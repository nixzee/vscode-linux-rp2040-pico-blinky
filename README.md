# <img src="https://raw.githubusercontent.com/nixzee/nixzee-branding/master/images/nixzee-logo-base.png" width="100"> Blinky Example for RP2040 Pico in Linux

TODO

# Directory Structure

# OS (Ubuntu) Setup

For the sake of this example, will be installing Ubuntu 20.04 onto a RPI 4. If you are using a different OS, skip this section.

## Install Ubuntu Server 20.04 LTS 64bit

This will walk through the process of installing an OS onto the RPI. We will be using Unbuntu 20.04 vs Raspbaian. Although Rasbian is lighter and faster, we will use Ubuntu for ROS.

1. Goto [Unbuntu for RPI](https://ubuntu.com/download/raspberry-pi) and download the "Ubuntu Server 20.04.1 LTS 64bit".
2. Once downloaded, get a 32-64GB uSD Card. I prefer the [Samsung Endurace Card](https://www.amazon.com/Samsung-Endurance-64GB-Micro-Adapter/dp/B07B9KTLJZ/ref=sr_1_3?crid=3H02VHGHS6QMC&dchild=1&keywords=endurance+sd+card+64gb&qid=1612207637&sprefix=endurance+sd+card%2Caps%2C169&sr=8-3). Here is a [dated white paper](https://www.jeffgeerling.com/blog/2019/raspberry-pi-microsd-card-performance-comparison-2019) comparing uSD cards.
3. Extract the image from the tar using [7Zip](https://www.7-zip.org/) by right clicking on the downloaded ".tar" and clicking extract.
4. Use [Win32DiskImager](https://sourceforge.net/projects/win32diskimager/) or Etcher to flash the uSD card. Insert the card, open the tool, click the folder icon, select the ".img" file, press OK and then press write. This should take 5 minutes.
5. Once completed, load the uSD card into a RPI4. Plug in a monitor and keyboard. Power on the RPI and wait about 5-10 minutes. For seem reason, the first boot takes a while for the password to be setup.
6. After the waiting, type ```ubuntu``` to login with the password being also ```ubuntu```. You will be prompted to change the password. If succesfull, you see something like this:

    ```shell
    unbuntu@ubuntu:~$
    ```

7. I recommend rebooting the device after 5 minutes at this point. It seems like there a processes that hang on the first boot. Im sure whats up but rebooting seems to fix it. If the reboot fails after some time, just power cycle it.

    ```shell
    sudo reboot
    ```

8. Download [moba](https://mobaxterm.mobatek.net/download.html) if you do not already have it.
9. You will need the IP for the next step. Use the following command

    ```shell
    ip address | grep eth0
    ```

10. Open **Moba** and click on "sessions" > "ssh". You will need to put in the IP of the RPI into "Remote host". Leave everything else alone, and press "OK"
11. If it connects succesffully, it will prompted you to loging with the username and password. You have now installed the OS and can remote into the RPI.
12. Update and Upgrade.

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
## Setup Host and Hostname

A [hostname](https://en.wikipedia.org/wiki/Hostname) is like an alias for the device on the network. Below are instructions on how to set the hostname. For this project, I would name one ```mobility-teleop``` and the other ```mobility-crane``` respectively.

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
## Install ZSH

[ZSH](https://www.zsh.org/) and [oh-my-zsh](https://ohmyz.sh/) just to make life easier and make you look cool. You want to be cool.

1. Install dependencies.

    ```shell
    sudo apt install wget curl git -y
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

## Dependencies

sudo apt-get install git-lfs

## GNU Arm Embedded Toolchain

We need to  install the [GNU Arm Embedded Toolchain](https://developer.arm.com/tools-and-software/open-source-software/developer-tools/gnu-toolchain/gnu-rm/downloads) in order to cross compile for the RP2040. 

1. Ensure we remove th

    ```shell
    sudo apt remove arm-none-eabi-gcc
    ```

2. First we need a few prerequisites.

    ```shell
    sudo apt install build-essential libncurses5 libncurses5-dev stm32flash make
    ```

3. Now get and extract.

    ```shell
    sudo wget https://developer.arm.com/-/media/Files/downloads/gnu-rm/10-2020q4/gcc-arm-none-eabi-10-2020-q4-major-aarch64-linux.tar.bz2
    ```

    ```shell
    sudo tar -C /usr/local -xvf gcc-arm-none-eabi-10-2020-q4-major-aarch64-linux.tar.bz2
    ```

4. Open your rc (~/.zshrc or whatever shell you use).

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

6. Finally, test by getting the version.

    ```shell
    arm-none-eabi-gcc --version
    ```

## Pico Probe

## OpenOCD

This section will walk you through building and installing the OpenOCD for PicoProbe. At this time, OpenOCD does not officially support Rasperry Pi Pico so we need to build from their [branch](https://github.com/raspberrypi/openocd/tree/picoprobe).

1. We need to remove the official OpenOCD if present.

    ```shell
    sudo apt remove openocd
    ```

2. Now lets install all the dependicies we will need to build OpenOCD.

    ```shell
    sudo apt install pkg-config autoconf automake autoconf build-essential texinfo libtool libftdi-dev libusb-1.0-0-dev
    ```

3. Clone the branch.

    ```shell
    git clone https://github.com/raspberrypi/openocd.git --branch picoprobe --depth=1 --no-single -branch
    ```

4. Build OpenOCD for Pico Probe since that is what we will use to debug. You may need to run the bootstrap multiple times in order for it to work.

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

# Debug

## Building and deploying

# CICD and Docker
