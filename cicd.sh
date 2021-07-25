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
VERSION=""
DEFAULT_VERSION=""
BASE_NAME=""
TARGET_NAME=""
SHA=""
SHORT_SHA=""
BUILD_DIR="_build"

init()
{
echo "Initializing..."
# get the base name
BASE_NAME="gcc-arm-none-eabi-"$(grep "ARG ARM_NONE_EABI_PACKAGE_VERSION=" docker/Dockerfile.gcc | cut -d '"' -f 2)
# get the project name
TARGET_NAME=$(grep "TARGET =" Makefile | cut -d ' ' -f 3)
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
    VERSION=""
    DEFAULT_VERSION=$(git rev-parse --short=4 ${{ GITHUB_SHA }})
    SHA=${GITHUB_SHA}
    SHORT_SHA=$(git rev-parse --short=4 ${{ GITHUB_SHA }})
else #Local
    VERSION=""
    DEFAULT_VERSION=$(git log -1 --pretty=format:%h)
    SHA=$(git log -1 --format=%H)
    SHORT_SHA=$(git log -1 --pretty=format:%h)
fi
# log
echo "REGISTRY: $REGISTRY"
echo "VERSION: $VERSION"
echo "DEFAULT_VERSION: $DEFAULT_VERSION"
echo "BASE_NAME: $BASE_NAME"
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
    echo "-g for GCC"
    echo "-b for Build"
    echo "-X for Build All"
    echo "-c for Clean"
    echo "-s for Clean All"
    echo "##############################################################################" 
}

#-----------------------------------------------------------------------------------------
# GCC
# Description: This setups the GCC base
#-----------------------------------------------------------------------------------------
gcc()
{
    echo "Creating GCC Builder..."
    # set the tag to the defualt version if no version exists
    TAG=$VERSION
    if [ -z "$VERSION" ]; #Check for env
    then 
        # TAG=$DEFAULT_VERSION
        # For now we will use latest
        TAG="latest"
    fi
    echo "Prepped for: $BASE_NAME:$TAG"
    # build
    echo "Creating..."
    docker buildx build . -f ./docker/Dockerfile.gcc -t $BASE_NAME:$TAG \
        --build-arg $GIT_COMMIT="$SHA" \
        --target arm-none-eabi-gcc
    status_check $?
    echo "GCC Bulder Complete"
    echo ""
}

#-----------------------------------------------------------------------------------------
# Build
# Description: Builds a particular node and places the artifacts in the "build dir"
#-----------------------------------------------------------------------------------------
build()
{
    echo "Building Node $1..."
    
    makeBuildDIR
    # check if the file exists
    validateName $1
    NAME=$1

    docker buildx build . -f ./docker/Dockerfile.build --target artifact \
    --progress=plain \
    --build-arg TARGET_NAME="$NAME" \
    --output ./"$BUILD_DIR"

    status_check $?
    echo "Building Complete..check $BUILD_DIR for artifacts"
    echo ""
}

# -----------------------------------------------------------------------------------------
# BuildAll
# Description: 
# -----------------------------------------------------------------------------------------
buildAll() 
{
    echo "Building All..."
    # Find all services in cmd with a main.go
    NODES=""
    for FOUND in $(find . -name main.cpp -printf '%h\n' | cut -d '/' -f 2)
    do
        # Enssure has a makefile
        if [ $FOUND/makefile ]; then
            NODES="$NODES $FOUND"
        fi
    done
    echo "Found the following valid Nodes:$NODES"
    # Build the valid services
    for NODE in $NODES
    do
        build $NODE
    done
    echo "Building All Complete"
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
    docker image prune --filter label=stage=unit-arm-none-eabi-gcc --force
    docker image prune --filter label=stage=build --force
    docker image prune --filter label=stage=artifact --force
    # https://github.com/moby/buildkit/issues/1358
    echo "Docker builder prune"
    docker builder prune --filter label=stage=arm-none-eabi-gcc --force 
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
    echo "Removing GCC image"
    docker rmi -f "$BASE_NAME"
    # Clean
    clean
    # Remove dangling images
    docker rmi -f $(docker images -f "dangling=true" -q)
}

# init
init

# Parse arguements and run
while getopts ":hgb:xcs" options; do
    case $options in
        h ) usage ;;           # usage (help)
        g ) gcc ;;             # gcc
        b ) build  $OPTARG ;;  # build
        x ) buildAll ;;        # build all
        c ) clean ;;           # clean
        s ) cleanAll ;;        # superClean
        * ) usage ;;           # default (help)
    esac
done