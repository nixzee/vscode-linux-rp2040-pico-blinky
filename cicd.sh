#!/bin/sh
#$env:DOCKER_BUILDKIT=1
#-----------------------------------------------------------------------------------------
# CI/CD Shell Script
# Decription: The purpose of this script is assit in bootstrapping the CICD needs. It also
# allows the user to run both locally and remotely. A user should be able to run a too at
# any time.
#-----------------------------------------------------------------------------------------

#-----------------------------------------------------------------------------------------
# Globals and init
# Description: Global variables.
#-----------------------------------------------------------------------------------------
# Supported Container Builders
readonly CONTAINER_BUILDER_DOCKER="docker"
readonly CONTAINER_BUILDER_BUILDKIT="buildkit"
# Defaults
readonly DEFAULT_TOOLCHAIN="gcc-arm-none-eabi"
readonly DEFAULT_BUILD_DIR="build"
# Globals
REGISTRY=""
CONTAINER_BUILDER=$CONTAINER_BUILDER_BUILDKIT
TOOLCHAIN=$DEFAULT_TOOLCHAIN
TOOLCHAIN_VERSION=""
TOOLCHAIN_IMAGE_NAME=""
SHA=""
SHORT_SHA=""
BUILD_DIR=$DEFAULT_BUILD_DIR

init()
{
    # get the toolchain
    TOOLCHAIN_VERSION=$(grep "ARG ARM_NONE_EABI_PACKAGE_VERSION=" docker/Dockerfile.toolchain | cut -d '"' -f 2)
    # Check if local or action...
    # This is janky but it does the job
    ACTION=true
    if [ -z "${GITHUB_RUN_NUMBER}" ]; #Check for env
    then 
        ACTION=false
    fi
    # set based on build enviroment
    if [ $ACTION = true ]
    then # Action
        SHA=${GITHUB_SHA}
        SHORT_SHA=$(git rev-parse --short=4 ${{ GITHUB_SHA }})
    else #Local
        SHA=$(git log -1 --format=%H)
        SHORT_SHA=$(git log -1 --pretty=format:%h)
    fi
    # set the toolchain image name
    TOOLCHAIN_IMAGE_NAME="$TOOLCHAIN:$TOOLCHAIN_VERSION"
    # check if there is a registry
    if [ ! -z "$REGISTRY" ]; 
    then
        TOOLCHAIN_IMAGE_NAME="$REGISTRY/$TOOLCHAIN_IMAGE_NAME"
    fi
}

#-----------------------------------------------------------------------------------------
# about
# Description: Use to exit on failed code.
#-----------------------------------------------------------------------------------------
about()
{
    # log
    echo "REGISTRY: $REGISTRY"
    echo "CONTAINER_BUILDER: $CONTAINER_BUILDER"
    echo "TOOLCHAIN: $TOOLCHAIN"
    echo "TOOLCHAIN_VERSION: $TOOLCHAIN_VERSION"
    echo "TOOLCHAIN_IMAGE_NAME: $TOOLCHAIN_IMAGE_NAME" 
    echo "SHA: $SHA"
    echo "SHORT_SHA: $SHORT_SHA"
    echo "OS_INFO: $(uname -a)"
    echo "IN_ACTION: $ACTION"
    echo ""
}

#-----------------------------------------------------------------------------------------
# status_check
# Description: Use to exit on failed code.
# Yes...I know about set -e. I just perfer to have more control.
# Usage: status_check $?
#-----------------------------------------------------------------------------------------
status_check()
{
    if [ $1 -ne 0 ]
    then
    echo "Terminating"
    exit 1
    fi
}

#-----------------------------------------------------------------------------------------
# create_build_dir
# Description: Is used by functions to create the build dir
#-----------------------------------------------------------------------------------------
create_build_dir()
{
    # create the build dir with perms
    # BEWARE: if done inside a container with a volume the owner will be root.
    echo "Creating build directory"
    mkdir -p -m777 $BUILD_DIR
}

#-----------------------------------------------------------------------------------------
# remove_build_dir
# Description: Is used by functions to remove the build dir
#-----------------------------------------------------------------------------------------
remove_build_dir()
{
    # Remove the build directory
    echo "Removing build directory"
    rm -rf "$BUILD_DIR"
}

#-----------------------------------------------------------------------------------------
# usage
# Description: Provides the usages of the shell.
#-----------------------------------------------------------------------------------------
usage() 
{
    echo "##############################################################################" 
    echo "Usage" 
    echo "-a for About - logs meta info std out"
    echo "-t for Toolchain - Builds the toolchain image using a supported container builder"
    echo "-b for Build from local - Will build the artifacts at the OS level"
    echo "-d for Build from Container - Will use the toolchain image to build the artifacts"
    echo "-c for Clean - Cleans the container builder"
    echo "-s for Clean All - Cleans wipes everything including build dir and images"
    echo "##############################################################################" 
}

#-----------------------------------------------------------------------------------------
# toolchain
# Description: This setups the toolchain base
#-----------------------------------------------------------------------------------------
toolchain()
{
    echo "Creating Toolchain Image..."

    echo "Prepped for: $TOOLCHAIN_IMAGE_NAME"
    # build
    case $CONTAINER_BUILDER in
        "$CONTAINER_BUILDER_BUILDKIT" ) # For Buildkit
            echo "Using Buildkit"
            docker buildx build . -f ./docker/Dockerfile.toolchain -t $TOOLCHAIN_IMAGE_NAME \
                --progress=plain \
                --build-arg GIT_COMMIT="$SHA" \
                --target toolchain
            ;;
        "$CONTAINER_BUILDER_DOCKER" ) # For Docker
            echo "Using Docker"
            docker build . -f ./docker/Dockerfile.toolchain -t $TOOLCHAIN_IMAGE_NAME \
                --build-arg GIT_COMMIT="$SHA"
            ;;
        * )
            echo "No Container builder is set or not supported"
            status_check 2 
            ;;
    esac
    status_check $?
    echo "GCC Toolchain Complete"
    echo ""
}

#-----------------------------------------------------------------------------------------
# build_from_local
# Description: Will build configure create a fresh build dir, configure cmake, and build
# artifacts.
#-----------------------------------------------------------------------------------------
build_from_local()
{
    # Remove build dir
    remove_build_dir
    status_check $?
    # Make the build dir
    create_build_dir
    status_check $?

    echo "Configuring and Building with CMake"
    # build
    cd build/ && \
        cmake .. -G "Unix Makefiles" && \
        cmake --build . --config Debug --target all -j 4
    status_check $?
    echo "Build Complete"
    echo ""
}

#-----------------------------------------------------------------------------------------
# build_from_container
# Description: Will use the tool chain image and call build_from_local inside the 
# container.
#-----------------------------------------------------------------------------------------
build_from_container()
{
    echo "Building from container"
    # build
    docker run --rm -it -v $(pwd):/workspace -exec $TOOLCHAIN_IMAGE_NAME bash -c "cd workspace/ && ./cicd.sh -b" 
    echo "Build from container Complete"
    echo ""
}

#-----------------------------------------------------------------------------------------
# clean
# Description: Performs clean up
#-----------------------------------------------------------------------------------------
clean()
{
    # prune images by stage label (only care about our mess)
    # Do note that artifacts should not produce images
    echo "Docker image prune"
    docker image prune --filter label=stage=toolchain --force
    # https://github.com/moby/buildkit/issues/1358
    echo "Docker builder prune"
    docker builder prune --filter label=stage=toolchain --force 
}

#-----------------------------------------------------------------------------------------
# clean_all
# Description: Performs clean up of everything
#-----------------------------------------------------------------------------------------
clean_all()
{
    # Remove build dir
    remove_build_dir
    # Remove toolchain image
    echo "Removing toolchain image if found"
    if [ $(docker images | grep $TOOLCHAIN | awk '{print $3}') ]; 
    then
        docker rmi -f $(docker images | grep $TOOLCHAIN | awk '{print $3}')
    fi
    # Clean
    clean
    # Remove dangling images
    echo "Removing dangling image(s) if found"
    if [ $(docker images -f "dangling=true" -q) ]; 
    then
        docker rmi -f $(docker images -f "dangling=true" -q)
    fi
}

# init
init

# Parse arguements and run
while getopts ":hatbdcs" options; do
    case $options in
        h ) usage ;;                # usage (help)
        a ) about ;;                # about
        t ) toolchain ;;            # toolchain
        b ) build_from_local ;;     # build from local
        d ) build_from_container ;; # build_from_container
        c ) clean ;;                # clean
        s ) clean_all ;;            # superClean
        * ) usage ;;                # default (help)
    esac
done