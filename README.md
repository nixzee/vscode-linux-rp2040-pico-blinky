# <img src="https://raw.githubusercontent.com/nixzee/nixzee-branding/master/images/nixzee-logo-base.png" width="100"> Blinky Example for RP2040 Pico in Linux

This repo provides eveything you need to go from zero to debuging a RP2040 Pico using Ubuntu 20.04 ARM64 (on an RPI4) and VS Code Remote Plugin. Although this is for ARM64, it could easily be switch another distro.

## Motivation

A while I was starting a project that required multiple micro-controllers. I really wanted to use the PICO but I could not get any in stock. I had to settle with the STM32F411 (This was litterally the only chip I could get in stock at the time). This was my first solo embedded project and lets just say I learned a lot with a lot of pain along the way. At the end of the project, I wanted to ensure the next time would be better for me and others on my team. I don't want to go any further on this or this will turn into an even longer novel. However, the big take away is that Pico is cheap and abundant (now), has a solid community and well documented, powerful and easy to use. This is my main motivation for this repo.

Once I was able to finally get the Pico, I discovered a lot of the documentation is heavily catered to Raspbian. Nothing wrong with that but not everyone use Raspbian. We, for instance, use Ubuntu 20.04 for our RPI deployments. I wanted to show to how to setup the Pico for anything but Raspbian.

Another motivation for me is watching people struggle with Arduino (when doing anything complex) and not having a proper debugger. Yes, I know the latest Arduino IDE has debugging. However, thats only a half solution and you are now stuck in their ecosystem. By using OpenOCD we can perform a proper debug independent of the IDE. Additionally, VS Code is better IDE that can do most anything and provides a plugin called Cortex-Debug that will manage GDB and OpenOCD for us. Also, the Pico SDK is well documented and almost as easy to program is Arduino without hiding behind crippling abstraction.

## Future Goals

There are some additional goals I want to do in the future to extened this project. I will mark these off as they get completed.

* Add [ccache](https://ccache.dev/) support.
* Setup a [GitHub Action](https://github.com/features/actions) and [GitHub Packages](https://docs.github.com/en/packages/learn-github-packages/introduction-to-github-packages). This is something I just never seem to get around to for some reason but is hugely important.
* Develop a debugging board for the Pico using [KiCAD](https://www.kicad.org/). My idea is just mate the pico foot print to the board an use simple through-hole components to make it an easy build. The motivation is a cheap and easy way to simplify the wiring for Pico Probe.
* Create an example around [FreeRTOS](https://www.freertos.org/index.html). Most of my embedded projects use FreeRTOS. If you have never heard of it or used, read the documenetaion and use it. Its a game changer for some projects. I believe there is already a branch to support multi-core M0+.

## Directory Structure

The project directory structure is broken down as follows:

* [.vscode](https://github.com/nixzee/vscode-linux-rp2040-pico-blinky/tree/main/.vscode) - Contains VS Code configurations.
* build - This is where Cmake and Make artifacts live. This watched by the gitinore.
* [docker](https://github.com/nixzee/vscode-linux-rp2040-pico-blinky/tree/main/docker) - Contains two Dockerfiles. One to be used to create a toolchain image and the other to build artifacts.
* [hardware](https://github.com/nixzee/vscode-linux-rp2040-pico-blinky/tree/main/hardware) - This directory contains models and images for 3D printing case(s).
* [src](https://github.com/nixzee/vscode-linux-rp2040-pico-blinky/tree/main/src) - The actual source code. This project has the main and the pico-sdk submodule.

## Parts

Below are list of parts that I used for to test this repo.

* 2x [RP2040 Pico](https://tinyurl.com/26vwvxdt)
* 1x [RPI 4](https://tinyurl.com/rbt6czxj)
* 1x [Samsung Endurace Card](https://tinyurl.com/2he8cpcn)
* 1x [Ice Cooler](https://tinyurl.com/x6fkxe9k)
* 1x [RPI Power Supply](https://tinyurl.com/yjfx8nsh)
* 1x [Micro USB Cable](https://tinyurl.com/4277rt3f)
* 1x [Jumper Wire Kit](https://tinyurl.com/ubsyt854)

---

## OS (Ubuntu) Setup

### Install Ubuntu Server 20.04 LTS 64bit on RPI 4

This will walk through the process of installing an OS onto the RPI. We will be using Unbuntu 20.04 vs Raspbaian. The setup below was done from Windows 10 and SSH.

1. Goto [Unbuntu for RPI](https://ubuntu.comt/download/raspberry-pi) and download the "Ubuntu Server 20.04.1 LTS 64bit".
2. Once downloaded, get a 32-64GB uSD Card. I prefer the [Samsung Endurace Card](https://www.amazon.com/Samsung-Endurance-64GB-Micro-Adapter/dp/B07B9KTLJZ/ref=sr_1_3?crid=3H02VHGHS6QMC&dchild=1&keywords=endurance+sd+card+64gb&qid=1612207637&sprefix=endurance+sd+card%2Caps%2C169&sr=8-3). Here is a [dated white paper](https://www.jeffgeerling.com/blog/2019/raspberry-pi-microsd-card-performance-comparison-2019) comparing uSD cards. Honestly, do your own research.
3. Extract the image from the tar using [7Zip](https://www.7-zip.org/) by right clicking on the downloaded ".tar" and clicking extract.
4. Use [Win32DiskImager](https://sourceforge.net/projects/win32diskimager/) or Etcher to flash the uSD card. Insert the card, open the tool, click the folder icon, select the ".img" file, press OK and then press write. This should take 5 minutes.
5. Once completed, load the uSD card into a RPI4. Plug in a monitor and keyboard. Power on the RPI and wait about 5-10 minutes. For seem reason, the first boot takes a while for the password to be setup.
6. After the waiting, type ```ubuntu``` to login with the password being also ```ubuntu```. You will be prompted to change the password. If succesfull, you see something like this:

    ```shell
    unbuntu@ubuntu:~$
    ```

7. I recommend rebooting the device after 5 minutes at this point. It seems like there a processes that hangs on the first boot. I'm not sure whats up but rebooting seems to fix it. If the reboot fails after some time, just power cycle it.

    ```shell
    sudo reboot
    ```

8. Download [moba](https://mobaxterm.mobatek.net/download.html) if you do not already have it. You can also use Putty or perform from Powershell is you like punishment.

9. You will need the IP for the next step. Use the following command

    ```shell
    ip address | grep eth0
    ```

10. Open **Moba** and click on "sessions" > "ssh". You will need to put in the IP of the RPI into "Remote host". Leave everything else alone, and press "OK"

11. If it connects succesffully, it will prompted you to loging with the username and password. You have now installed the OS and can remote into the RPI.

12. Update and Upgrade. You don't really need to reboot unless you want to.

    ```shell
    sudo apt update
    sudo apt upgrade
    sudo reboot
    ```

13. Disable the Cloud-Init crap.

    ```shell
    sudo touch /etc/cloud/cloud-init.disabled
    sudo reboot
    ```

### Setup Host and Hostname (optional)

A [hostname](https://en.wikipedia.org/wiki/Hostname) is like an alias for the device on the network. Below are instructions on how to set the hostname.

1. Open the hostname file and replace the old name with a new one.

    ```shell
    sudo nano /etc/hostname
    ```

2. Edit the hosts file and replace with the new name.

    ```shell
    sudo nano /etc/hosts
    ```

3. Reboot.

    ```shell
    sudo reboot
    ```

### Install ZSH (optional)

[ZSH](https://www.zsh.org/) and [oh-my-zsh](https://ohmyz.sh/) just to make life easier and make you look cool. You want to be cool.

1. Install dependencies.

    ```shell
    sudo apt install wget curl git
    ```

2. Install **ZSH** and set as default shell.

    ```shell
    sudo apt install zsh
    sudo chsh $USER -s $(which zsh)
    ```

3. Reboot the device.

    ```shell
    sudo reboot
    ```

4. Upon logging in, you will prompted to create the startup script. Press "2".
5. Install **Oh-my-Zsh**.

    ```shell
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    ```

6. I recommend changing the theme to "agnoster". You can find the setting in "ZSH_THEME".

    ```shell
    nano ~/.zshrc
    ```

    ```shell
    # Set name of the theme to load --- if set to "random", it will
    # load a random theme each time oh-my-zsh is loaded, in which case,
    # to know which specific one was loaded, run: echo $RANDOM_THEME
    # See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
    ZSH_THEME="agnoster"
    ```

7. Reload the shell.

    ```shell
    source ~/.zshrc
    ```

8. Get the ProFont for Powerline.

    ```shell
    sudo apt install --yes powerline
    ```

---

## Development Tools Setup

This section will walk through all the tools you will need to develop and debug for the RP2040 Pico.

### Git

We will need to setup our [Git](https://git-scm.com/) client. This example is in a [GitHub](https://github.com/) repo and use SSH instead of HTTPS as you should. This means we will need to setup a GitHub account (if dont already have one) and SSH keys.

1. Install git and [git LFS](https://git-lfs.github.com/). The LFS is not used for anything related to source code.

    ```shell
    sudo apt-get install git git-lfs
    git lfs install
    ```

2. We need to configure the git user info. Use your own user name and email.

    ```shell
    git config --global user.name "John Doe"
    git config --global user.email johndoe@example.com
    ```

3. Now for the fun stuff. Go to [GitHub](https://github.com/) if you haven't already.

4. Follow the [instructions](https://docs.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent) for generating the SSH keys localy on the Linux device.

5. Follow these [instructions](https://docs.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account) for adding the SSH key to your GitHub Account.

6. Now [test](https://docs.github.com/en/github/authenticating-to-github/connecting-to-github-with-ssh/testing-your-ssh-connection).

### CMake

The [Pico SDK](https://github.com/raspberrypi/pico-sdk) leverages [CMake](https://cmake.org/) to build. I highly recommend doing some reading on it if you are not familar. It can be bit overwhelming but go into with specific questions. Look at me...I am no CMake expert and I didn't manage to break everything.

1. We need to install CMake.

    ```shell
    sudo apt install cmake
    ```

### GNU Arm Embedded Toolchain

We need to install the [GNU Arm Embedded Toolchain](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads) in order to cross compile for the RP2040. We will be doing this because all new packages will not be release via Launchpad. [Here](https://launchpad.net/gcc-arm-embedded) is the article. [Here](https://askubuntu.com/questions/1243252/how-to-install-arm-none-eabi-gdb-on-ubuntu-20-04-lts-focal-fossa) is another explination. Also, I prefer choosing my toolchain. Put simply, we need to install the toolchain manaully. No biggie.

1. Ensure we remove the package manager installed one if was installed prior.

    ```shell
    gcc-arm-none-eabi
    ```

2. First we need a few prerequisites.

    ```shell
    sudo apt install build-essential libncurses5 libncurses5-dev make
    ```

3. Now get and extract. I would check if there is newer release.

    ```shell
    sudo wget https://developer.arm.com/-/media/Files/downloads/gnu-rm/10-2020q4/gcc-arm-none-eabi-10-2020-q4-major-aarch64-linux.tar.bz2
    ```

    ```shell
    sudo tar -C /usr/local -xvf gcc-arm-none-eabi-10-2020-q4-major-aarch64-linux.tar.bz2
    ```

4. Open your run commands file (~/.zshrc or whatever shell you use).

    ```shell
    nano ~/.zshrc
    ```

5. Now add the path to the end of your rc.

    ```shell
    # GCC
    export PATH=$PATH:/usr/local/gcc-arm-none-eabi-10-2020-q4-major/bin
    ```

6. Save, close, and source the file.

    ```shell
    source ~/.zshrc
    ```

7. Finally, test by getting the version.

    ```shell
    arm-none-eabi-gcc --version
    ```

    You should see something like this:

    ```console
    ubuntu@node1  ~  arm-none-eabi-gcc --version
    arm-none-eabi-gcc (GNU Arm Embedded Toolchain 10-2020-q4-major) 10.2.1 20201103 (release)
    Copyright (C) 2020 Free Software Foundation, Inc.
    This is free software; see the source for copying conditions.  There is NO
    warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
    ```

### OpenOCD

This section will walk you through building and installing the OpenOCD for PicoProbe. At this time, OpenOCD does not officially support Rasperry Pi Pico so we need to build from their [branch](https://github.com/raspberrypi/openocd/tree/picoprobe). This is largely the same as what is in the [Getting Started](https://datasheets.raspberrypi.org/pico/getting-started-with-pico.pdf#page=58).

1. We need to remove the official OpenOCD if present.

    ```shell
    sudo apt remove openocd
    ```

2. Now lets install all the dependicies we will need to build OpenOCD.

    ```shell
    sudo apt install pkg-config autoconf automake autoconf build-essential texinfo libtool libftdi-dev libusb-1.0-0-dev
    ```

3. Clone the branch from home directory.

    ```shell
    git clone https://github.com/raspberrypi/openocd.git --branch picoprobe --depth=1 --no-single
    ```

4. Build OpenOCD for Pico Probe since that is what we will use to debug. You may need to run the bootstrap multiple times in order for it to work. For some reason, it always fails the first time for me.

    ```shell
    cd openocd
    ./bootstrap
    ./configure --enable-picoprobe
    make -j4
    sudo make install
    ```

5. Test that OpenOCD was built and installed correctly. Plug in the Pico Probe device. Run the command below for any errors. You will need to escape if succesful.

    ```shell
    openocd -f interface/picoprobe.cfg -f target/rp2040.cfg -s tcl
    ```

    You should see something like this:

    ```Console
    ubuntu@node1  ~  openocd -f interface/picoprobe.cfg -f target/rp2040.cfg -s tcl
    Open On-Chip Debugger 0.10.0+dev-g18b4c35-dirty (2021-07-23-14:43)
    Licensed under GNU GPL v2
    For bug reports, read
            http://openocd.org/doc/doxygen/bugs.html
    Info : only one transport option; autoselect 'swd'
    Warn : Transport "swd" was already selected
    adapter speed: 5000 kHz

    Info : Hardware thread awareness created
    Info : Hardware thread awareness created
    Info : RP2040 Flash Bank Command
    Info : Listening on port 6666 for tcl connections
    Info : Listening on port 4444 for telnet connections
    Info : clock speed 5000 kHz
    Info : SWD DPIDR 0x0bc12477
    Info : SWD DLPIDR 0x00000001
    Info : SWD DPIDR 0x0bc12477
    Info : SWD DLPIDR 0x10000001
    Info : rp2040.core0: hardware has 4 breakpoints, 2 watchpoints
    Info : rp2040.core1: hardware has 4 breakpoints, 2 watchpoints
    Info : starting gdb server for rp2040.core0 on 3333
    Info : Listening on port 3333 for gdb connections
    ```

### Docker

The following steps are to install **Docker**. [Docker](https://www.docker.com/) is used to create/use containers. This will be used later for CICD. Its also handy is you want to generate artifacts and dont want to setup a complete development enviroment.

1. Update and get dependencies.

    ```shell
    sudo apt update
    sudo apt install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
    ```

2. Add the **Docker** APT repo.

    ```shell
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=arm64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    ```

3. Install.

    ```shell
    sudo apt update
    sudo apt install docker-ce docker-ce-cli containerd.io
    ```

4. Test by running the following command.

    ```shell
    sudo docker --version
    ```

    You should see something like this:

    ```console
    ubuntu@node1  ~  sudo docker --version
    Docker version 20.10.7, build f0df350
    ```

5. Now we need to give non-root access to docker because of reasons...

    ```shell
    sudo groupadd docker
    sudo gpasswd -a $USER docker
    ```

6. Now after next session login or reboot you should be able to run docker commands as non-root (no sudo).

### Pico Probe

In order to debug the Pico, we will need a SWD debugger. We will use another Pico flashed with Pico Probe to debug another Pico. More info can be found in [Getting Started](https://datasheets.raspberrypi.org/pico/getting-started-with-pico.pdf#page=58).

1. You can download the UF2 file for PicoProbe. Raspberry does have a repo where you can build it manually but lets skip that and save some time. Goto the [link](https://www.raspberrypi.org/documentation/rp2040/getting-started/#board-specifications) and download the UF2 File.

2. Now take on of the Picos, plugin the micro USB cable into it. While holding down the **BOOTSEL** button, plug the USB cable into the computer. This will put the Pico in a bootloader mode and should show in Windows as a new drive.

3. Now copy the UF2 file over to the Pico. In windows you should see a new drive under "This PC". Once copied over then Pico will reboot and you should have a solid green LED.

4. Now we need to setup Udev rules for the Pico probe so it can permissions. First got back to your OpenOCD git directory and navigate to the following:

    ```shell
    cd ~/openocd/contrib
    ls
    ```

    You see a file that looks likes this:

    ```console
    ...
    60-openocd.rules
    ```

5. This file is the Udev rules for the Pico. We need to load it.

    ```shell
    sudo cp 60-openocd.rules /etc/udev/rules.d
    sudo udevadm control --reload
    ```

---

## Development Enviroment Setup

This section will walk you through setting up the development enviroment in VS Code.

### Cloning from GitHub

Now we will pull the repo. Please keep in mind that this repo uses submodules, SSH, and LFS.

1. From your home directory, clone the repo.

    ```shell
    git clone https://github.com/nixzee/vscode-linux-rp2040-pico-blinky
    ```

2. Now enter the directory and get submodules. This step may take a few minutes.

    ```shell
    cd vscode-linux-rp2040-pico-blinky
    git submodule update --init --recursive
    ```

### VS Code

For a development IDE, we are using [VS Code](https://code.visualstudio.com/) and some plugins including [VS Code Remote Development](https://code.visualstudio.com/docs/remote/remote-overview). Please keep in mind that these instructions work for build 1.58.2.

1. Install [VS Code](https://code.visualstudio.com/) for your development machine. Install for Windows.

2. Once installed, we install the first plugin. Off to the left, there is a bar with icons. One of the icons looks like blocks. Click on it. Type into to the box ```Search Extensions in Marketplace```, ```Remote Development``` Click on it and click install. Once done, reload **VS Code** by closing and re-opening.

3. Next we need to connect to RPI. You should a green box on the lower left. Click it. A window will popup at the top. Select ```Remote SSH: Connect to Host...```. Click on ```Add New Host``` put in the following (swap the IP for the IP of the RPI).

    ```shell
    ubuntu@<IP>
    ```

4. Following any prompts.

5. Open the project. Click File>Open Folder. Select ```vscode-linux-rp2040-pico-blinky```. Click OK. Enter your password.

6. We will now install all the plugins. As before, click on the plugins icon. We will instll the following on. Some of these are not really neccisary but handy to have.

    * C/C++
    * C/C++ Intellisense
    * Cortex-Debug
    * Docker
    * CMake
    * CMake Tools
    * Doxygen Documentation Generator
    * markdownlint
    * Todo Tree

7. Perform a window reload <kbd>Ctrl</kbd>+<kbd>shift</kbd>+<kbd>p</kbd> and type ```window reload``` and hit enter. Log back in.

8. Now we need to select the CMake kit so that CMake knows which compiler to use. On the very bottom on the blue tool bar you should see something with a tool icon and says ```No Active kit```. Click it and click the ```Scan for Kits``` at the top of the window. Wait for it to finish. Now select the ```No Active kit``` again. Select ```GCC 10.2.1 arm-none-eabi``` at the top of the window. This is the toolchain we installed earlier.

9. The build artifacts from CMake need a place to live. We will put them into a build directory. Let's create one. Note that the build directory is in the git ignore file. This means any changes in the folder will not be tracked by git. This is a good thing since we dont want artifacts and binaries being pushed to git. To create a build directory, navigate to repo directory and create it or just create in VS Code.

    ```shell
    cd ~/vscode-linux-rp2040-pico-blinky
    mkdir build
    ```

10. Let's quickly test CMake. Perform <kbd>Ctrl</kbd>+<kbd>shift</kbd>+<kbd>p</kbd> and type ```Cmake: Configure``` and hit enter. You should see something like this in the OUTPUT:

    ```console
    [main] Configuring folder: vscode-linux-rp2040-pico-blinky 
    [proc] Executing command: /usr/bin/cmake --no-warn-unused-cli -DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=TRUE     -DCMAKE_BUILD_TYPE:STRING=Debug -DCMAKE_C_COMPILER:FILEPATH=/usr/local/gcc-arm-none-eabi-10-2020-q4-major/bin/  arm-none-eabi-gcc-10.2.1 -H/home/ubuntu/vscode-linux-rp2040-pico-blinky -B/home/ubuntu/vscode-linux-rp2040-pico-blinky/   build -G "Unix Makefiles"
    [cmake] Not searching for unused variables given on the command line.
    [cmake] PICO_SDK_PATH is /home/ubuntu/vscode-linux-rp2040-pico-blinky/pico-sdk
    [cmake] PICO platform is rp2040.
    [cmake] Using regular optimized debug build (set PICO_DEOPTIMIZED_DEBUG=1 to de-optimize)
    [cmake] PICO target board is pico.
    [cmake] Using board configuration from /home/ubuntu/vscode-linux-rp2040-pico-blinky/pico-sdk/src/boards/include/boards/ pico.h
    [cmake] TinyUSB available at /home/ubuntu/vscode-linux-rp2040-pico-blinky/pico-sdk/lib/tinyusb/src/portable/raspberrypi/    rp2040; adding USB support.
    [cmake] Compiling TinyUSB with CFG_TUSB_DEBUG=1
    [cmake] -- Configuring done
    [cmake] -- Generating done
    [cmake] -- Build files have been written to: /home/ubuntu/vscode-linux-rp2040-pico-blinky/build
    ```

The next time you connect, click the green box again and select your device. You will need to open the project folder each time since the connection will take you to home. You should see the 

---

## Building and Debug

ddd

## CICD and Docker

This section will discuss the cicd script and how Docker is being used to build the project.

### CICD "Lite"

One of the future goals of this project is setup a GitHub action to continously build the project. I would not go as far as to call this actual [cicd](https://www.atlassian.com/continuous-delivery/principles/continuous-integration-vs-delivery-vs-deployment).To assist in our cicd "lite", there is a provided shell script with flags. Let's break these down.

* -a for About - Logs meta info to stdout (the terminal).
* -t for Toolchain - Builds the toolchain image using a supported container builder.
* -b for Build from local - Will build the artifacts at the OS level.
* -d for Build from Container - Will use the toolchain image to build the artifacts.
* -c for Clean - Cleans the container builder.
* -s for Clean All - Wipes everything including build dir and images.

An example use case for About:

```shell
./cicsh.sh -a
```

If you are having permission issues, set the execution permission.

```shell
chmod +x cicd.sh
```

### Build from Container

In addtion to our script, there is a [Dockerfile](https://docs.docker.com/engine/reference/builder/) used to build a toolchain image. This image has everything needed to compile the code for the Pico. This handy if you just want a UF2 artifact and dont want to setup the development tools and/or enviroment. Another thing I like about using containers, is that we can version lock the build tools. More reading about Docker, Contaierd, etc:

* [What is Docker?](https://opensource.com/resources/what-docker)
* [conatiner vs image](https://phoenixnap.com/kb/docker-image-vs-container)
* [containerd](https://containerd.io/)

This my first time developing an image that is used to build and is NOT apart of another stage. I spent the past few years developing micro-services with Docker and [Golang](https://golang.org/) for Edge IoT but this is a little different. Please advise if you have recommendations.

Follow the steps below to be able to compile the project from a container.

1. Run the cicd shell script to build the toolchain images. You will need internet connection and this will take a few minutes.

    ```shell
    ./cicd.sh -at
    ```

    You should see something like this when completed:

    ```console
    ...
    #13 exporting to image
    #13 sha256:e8c613e07b0b7ff33893b694f7759a10d42e180f2b4dc349fb57dc6b71dcab00
    #13 exporting layers done
    #13 writing image sha256:2f390daacc9d19afeb491e6ea5d743bd4d2d790f13fa8027f25c1884295eded1
    #13 writing image sha256:2f390daacc9d19afeb491e6ea5d743bd4d2d790f13fa8027f25c1884295eded1 0.1s done
    #13 naming to docker.io/library/gcc-arm-none-eabi:10-2020-q4-major done
    #13 DONE 0.1s
    GCC Toolchain Complete
    ```

2. Now compile the code. Please keep in mind that the build directory will be owned by root. I assume this due to Docker running as root by default. I will look into this at some point...

    ```shell
    ./cicd.sh -d
    ```

    You should see something like this when completed:

    ```console
    ...
    [ 86%] Building ASM object CMakeFiles/blinky.dir/src/pico-sdk/src/rp2_common/pico_float/float_v1_rom_shim.S.obj
    [ 88%] Building C object CMakeFiles/blinky.dir/src/pico-sdk/src/rp2_common/pico_malloc/pico_malloc.c.obj
    [ 89%] Building ASM object CMakeFiles/blinky.dir/src/pico-sdk/src/rp2_common/pico_mem_ops/mem_ops_aeabi.S.obj
    [ 91%] Building CXX object CMakeFiles/blinky.dir/src/pico-sdk/src/rp2_common/pico_standard_link/new_delete.cpp.obj
    [ 93%] Building C object CMakeFiles/blinky.dir/src/pico-sdk/src/rp2_common/pico_standard_link/binary_info.c.obj
    [ 94%] Building ASM object CMakeFiles/blinky.dir/src/pico-sdk/src/rp2_common/pico_standard_link/crt0.S.obj
    [ 96%] Building C object CMakeFiles/blinky.dir/src/pico-sdk/src/rp2_common/pico_stdio/stdio.c.obj
    [ 98%] Building C object CMakeFiles/blinky.dir/src/pico-sdk/src/rp2_common/pico_stdio_uart/stdio_uart.c.obj
    [100%] Linking CXX executable blinky.elf
    [100%] Built target blinky
    Build Complete
    ```

3. You should now see the build directory populated.