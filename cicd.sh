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
# Description: Global variables
#-----------------------------------------------------------------------------------------
# Supported Container Builders
readonly CONTAINER_BUILDER_DOCKER="docker"
readonly CONTAINER_BUILDER_BUILDKIT="buildkit"
# Globals
REGISTRY=""
CONTAINER_BUILDER=$CONTAINER_BUILDER_BUILDKIT
TOOLCHAIN="gcc-arm-none-eabi"
TOOLCHAIN_VERSION=""
SHA=""
SHORT_SHA=""
BUILD_DIR="build"


init()
{
echo "Initializing..."
# get the toolchain
TOOLCHAIN_VERSION=$(grep "ARG ARM_NONE_EABI_PACKAGE_VERSION=" docker/Dockerfile.toolchain | cut -d '"' -f 2)
# Check if local or action...
# This is janky but it does the job
ACTION=true
if [ -z "${GITHUB_RUN_NUMBER}" ]; #Check for env
then 
    ACTION=false
fi
echo "Running in Action: $ACTION"
echo ""
# set based on build enviroment
if [ $ACTION = true ]
then # Action
    SHA=${GITHUB_SHA}
    SHORT_SHA=$(git rev-parse --short=4 ${{ GITHUB_SHA }})
else #Local
    SHA=$(git log -1 --format=%H)
    SHORT_SHA=$(git log -1 --pretty=format:%h)
fi
# log
echo "REGISTRY: $REGISTRY"
echo "CONTAINER_BUILDER: $CONTAINER_BUILDER"
echo "TOOLCHAIN: $TOOLCHAIN"
echo "TOOLCHAIN_VERSION: $TOOLCHAIN_VERSION" 
echo "SHA: $SHA"
echo "SHORT_SHA: $SHORT_SHA"
echo "Initializing Complete"
echo ""
}

#-----------------------------------------------------------------------------------------
# Status Check
# Description: Use to exit on failed code
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
# makeBuildDIR
# Description: Is used by functions to make the build dir
#-----------------------------------------------------------------------------------------
makeBuildDIR()
{
    # create the build dir with perms
    echo "Creating build directory"
    mkdir -p -m777 $BUILD_DIR
}

#-----------------------------------------------------------------------------------------
# removeBuildDIR
# Description: Is used by functions to remove the build dir
#-----------------------------------------------------------------------------------------
removeBuildDIR()
{
    # Remove the build directory
    echo "Removing build directory"
    rm -rf "$BUILD_DIR"
}

#-----------------------------------------------------------------------------------------
# Usage
# Description: Provides the usages of the shell
#-----------------------------------------------------------------------------------------
usage() 
{
    echo "##############################################################################" 
    echo "Usage" 
    echo "-t for TOOLCHAIN"
    echo "-b for Build"
    echo "-a for Build from Container"
    echo "-c for Clean"
    echo "-s for Clean All"
    echo "##############################################################################" 
}

#-----------------------------------------------------------------------------------------
# Toolchain
# Description: This setups the toolchain base
#-----------------------------------------------------------------------------------------
toolchain()
{
    echo "Creating Toolchain Image..."

    echo "Prepped for: $TOOLCHAIN:$TOOLCHAIN_VERSION"
    # build
    case $CONTAINER_BUILDER in
        "$CONTAINER_BUILDER_BUILDKIT" ) # For Buildkit
            echo "Using Buildkit"
            docker buildx build . -f ./docker/Dockerfile.toolchain -t $TOOLCHAIN:$TOOLCHAIN_VERSION \
                --progress=plain \
                --build-arg $GIT_COMMIT="$SHA" \
                --target toolchain
            ;;
        "$CONTAINER_BUILDER_DOCKER" ) # For Docker
            echo "Using Docker"
            docker build . -f ./docker/Dockerfile.toolchain -t $TOOLCHAIN:$TOOLCHAIN_VERSION \
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
# Build
# Description: 
#-----------------------------------------------------------------------------------------
build()
{
    # Remove build dir
    removeBuildDIR
    # Make the build dir
    makeBuildDIR

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
# buildFromDocker
# Description: 
#-----------------------------------------------------------------------------------------
buildFromDocker()
{

    echo "Build from"
    # build
    docker run --rm -it -v $(pwd):/workspace -exec $TOOLCHAIN:$TOOLCHAIN_VERSION bash -c "cd workspace/ && ./cicd.sh -b" 
    echo "Build Complete"
    echo ""
}

#-----------------------------------------------------------------------------------------
# Clean
# Description: Performs clean up
#-----------------------------------------------------------------------------------------
clean()
{
    # prune images by stage label (only care about our mess)
    # Do note that artifacts should not produce images
    echo "Docker image prune"
    docker image prune --filter label=stage=toolchain --force
    docker image prune --filter label=stage=build --force
    docker image prune --filter label=stage=artifact --force
    # https://github.com/moby/buildkit/issues/1358
    echo "Docker builder prune"
    docker builder prune --filter label=stage=toolchain --force 
    docker builder prune --filter label=stage=build --force
    docker builder prune --filter label=stage=artifact --force
}

#-----------------------------------------------------------------------------------------
# Clean All
# Description: Performs clean up of everything
#-----------------------------------------------------------------------------------------
cleanAll()
{
    # Remove build dir
    removeBuildDIR
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
while getopts ":htbacs" options; do
    case $options in
        h ) usage ;;             # usage (help)
        t ) toolchain ;;         # toolchain
        b ) build ;;             # build
        a ) buildFromDocker ;;   # buildFromDocker
        c ) clean ;;             # clean
        s ) cleanAll ;;          # superClean
        * ) usage ;;             # default (help)
    esac
done