# Micro-XRCE-DDS + Crazyflie Port

This repository contains a build system and some extensions to integrate [Micro-XRCE-DSS](https://micro-xrce-dds.readthedocs.io/en/latest/) into the [Crayflie firmware](https://github.com/bitcraze/crazyflie-firmware).

It contains:
 - A Cmake toolchain for crosscompiling Micro-XRCE-DDS-Client
 - Crazyflie custom radio transports for Micro-XRCE-DDS-Client
 - Crazyflie custom timing functions for Micro-XRCE-DDS-Client
 - A sample app: microxrceddsapp.c


## Building

Clone this repository:

```bash
git clone -b microxrceddsapps https://github.com/micro-ROS/crazyflie_extensions.git
```

Update submodules:

```bash
git submodule init
git submodule update
cd crazyflie-firmware
git submodule init
git submodule update
```

Build Micro-XRCE-DDS-Client library:

```bash
make libmicroxrcedds
```

Build Crazyflie 2.1 firmware:

```bash
make CLOAD=0
```

Flash Crazyflie 2.1, make sure [DFU mode is enabled](https://www.bitcraze.io/docs/crazyflie-firmware/master/dfu/):

```bash
dfu-util -d 0483:df11 -a 0 -s 0x08000000 -D cf2.bin
```

## Integrated Micro-XRCE-DDS Agent + Crazyflie Client

Check [this port](https://github.com/eProsima/crazyflie-clients-python/tree/Micro-XRCE-DDS_Bridge):

```bash
git clone -b Micro-XRCE-DDS_Bridge https://github.com/eProsima/crazyflie-clients-python/tree/Micro-XRCE-DDS_Bridge
```