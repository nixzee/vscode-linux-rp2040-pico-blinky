# <img src="https://raw.githubusercontent.com/nixzee/nixzee-branding/master/images/nixzee-logo-base.png" width="100"> Blinky Example for RP2040 Pico in Linux

TODO

# Directory Structure

# OS (Ubuntu) Setup

<!-- For the sake of this example, will be installing Ubuntu 20.04 onto a RPI 4. If you are using a different OS, skip this section. -->

## Install Ubuntu Server 20.04 LTS 64bit on RPI 4.

This will walk through the process of installing an OS onto the RPI. We will be using Unbuntu 20.04 vs Raspbaian. The setup below was done from Windows 10 and SSH.

1. Goto [Unbuntu for RPI](https://ubuntu.com/download/raspberry-pi) and download the "Ubuntu Server 20.04.1 LTS 64bit".
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

## Setup Host and Hostname (optional)

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

## Install ZSH (optional)

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

# Development Tools Setup

This section will walk through all the tools you will need to develop and debug for the RP2040 Pico.

## git

We will need to setup our [git](https://git-scm.com/) client.

1. Install git and [git LFS](https://git-lfs.github.com/). The LFS is not used for anything related to source code.

    ```shell
    sudo apt-get install git git-lfs
    git lfs install
    ```

2. Now we need to configure the git user info. Use your own user name and email.

    ```shell
    git config --global user.name "John Doe"
    git config --global user.email johndoe@example.com
    ```

## GNU Arm Embedded Toolchain

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

## Pico Probe

In order to debug the Pico, we will need a SWD debugger. TODO More info can be found in [Getting Started](https://datasheets.raspberrypi.org/pico/getting-started-with-pico.pdf#page=58).

1. You can download the UF2 file for PicoProbe. Raspberry does have a repo where you can build it manually but lets skip that and save some time. Goto the [link](https://www.raspberrypi.org/documentation/rp2040/getting-started/#board-specifications) and download the UF2 File.

2. Now take on of the Picos, plugin the micro USB cable into it. While holding down the **BOOTSEL** button, plug the USB cable into the computer. This will put the Pico in a bootloader mode and should show in Windows as a new drive.

3. Now copy the UF2 file over to the Pico. In windows you should see a new drive under "This PC". Once copied over then Pico will reboot and you should have a solid green LED.

## OpenOCD

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

# Development Enviroment Setup

## VS Code

## Cloning from GitHub

Now we will pull the repo.

1. From your home directory, clone the repo.

    ```shell
    git clone https://github.com/nixzee/vscode-linux-rp2040-pico-blinky
    ```

2. Now enter the directory and get submodules.

    ```shell
    cd vscode-linux-rp2040-pico-blinky
    git submodule update --init --recursive
    ```

# Debug

## Building and deploying

# CICD and Docker
