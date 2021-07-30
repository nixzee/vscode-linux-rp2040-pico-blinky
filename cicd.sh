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
REGISTRY=""
TOOLCHAIN="gcc-arm-none-eabi"
TOOLCHAIN_VERSION=""
SHA=""
SHORT_SHA=""
BUILD_DIR="_build"

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
# validateName
# Description: Is used by functions like build to verify the name being passed
#-----------------------------------------------------------------------------------------
validateName()
{
    if [ ! -f $1/src/main.cpp ]; then
        echo "The node main does not exist"
        status_check 2
    fi
}

#-----------------------------------------------------------------------------------------
# makeBuildDIR
# Description: Is used by functions to make the build dir
#-----------------------------------------------------------------------------------------
makeBuildDIR()
{
    # create the build dir with perms
    mkdir -m777 $BUILD_DIR
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
    echo "Creating Toolchain Builder..."

    echo "Prepped for: $TOOLCHAIN:$TOOLCHAIN_VERSION"
    # build
    echo "Creating..."
    docker buildx build . -f ./docker/Dockerfile.toolchain -t $TOOLCHAIN:$TOOLCHAIN_VERSION \
        --progress=plain \
        --build-arg $GIT_COMMIT="$SHA" \
        --target toolchain
    status_check $?
    echo "GCC Toolchain Complete"
    echo ""
}

#-----------------------------------------------------------------------------------------
# Build
# Description: Builds the project and places the artifacts in the "build dir"
#-----------------------------------------------------------------------------------------
build()
{
    # Make the build dir
    makeBuildDIR

    # docker buildx build . -f ./docker/Dockerfile.build --target artifact \
    # --progress=plain \
    # --output ./"$BUILD_DIR"

    docker buildx build . -f ./docker/Dockerfile.build --target artifact

    status_check $?
    echo "Building Complete..check $BUILD_DIR for artifacts"
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
    # Remove the artifacts and directory
    echo "Removing build dir"
    rm -rf "$BUILD_DIR"
    echo "Removing toolchain image"
    docker rmi -f $(docker images | grep $TOOLCHAIN)
    # Clean
    clean
    # Remove dangling images
    docker rmi -f $(docker images -f "dangling=true" -q)
}

# init
init

# Parse arguements and run
while getopts ":htbcs" options; do
    case $options in
        h ) usage ;;           # usage (help)
        t ) toolchain ;;       # toolchain
        b ) build ;;          # build
        c ) clean ;;           # clean
        s ) cleanAll ;;        # superClean
        * ) usage ;;           # default (help)
    esac
done