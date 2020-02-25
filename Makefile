DEBUG ?= 1

PROJECTFOLDER = $(shell pwd)

TOPFOLDER = $(PROJECTFOLDER)/..
UROS_DIR = $(TOPFOLDER)/mcu_ws

EXTENSIONS_DIR = $(TOPFOLDER)/crazyflie_microros_extensions
SRC_DIR = $(EXTENSIONS_DIR)/src
CRAZYFLIE_BASE = $(TOPFOLDER)/crazyflie_firmware

ARCHCPUFLAGS =  -DARM_MATH_CM4 -D__FPU_PRESENT=1 -D__TARGET_FPU_VFP  -mfloat-abi=hard -mfpu=fpv4-sp-d16 -mcpu=cortex-m4 -mthumb -ffunction-sections -fdata-sections

ifeq ($(DEBUG), 1)
	ARCHCPUFLAGS += -O0 -g3
  	BUILD_TYPE = Debug
else
	BUILD_TYPE = Release
endif

# micro-ROS variables

MICROROS_INCLUDES += $(shell find $(UROS_DIR)/install -name 'include' | sed -E "s/(.*)/-I\1/")
MICROROS_INCLUDES += -I$(EXTENSIONS_DIR)/include
MICROROS_INCLUDES += -I$(EXTENSIONS_DIR)/include/FreeRTOS_POSIX
MICROROS_INCLUDES += -I$(EXTENSIONS_DIR)/include/private
MICROROS_INCLUDES += -I$(EXTENSIONS_DIR)/FreeRTOS-Plus-POSIX/include
MICROROS_INCLUDES += -I$(EXTENSIONS_DIR)/FreeRTOS-Plus-POSIX/include/portable
MICROROS_INCLUDES += -I$(EXTENSIONS_DIR)/FreeRTOS-Plus-POSIX/include/portable/crazyflie
MICROROS_INCLUDES += -I$(CRAZYFLIE_BASE)/src/lib/FreeRTOS/include

MICROROS_LIBRARIES = libmicroros.a

MICROROS_POSIX_FREERTOS_OBJECTS_VPATH +=  $(EXTENSIONS_DIR)/FreeRTOS-Plus-POSIX/source

MICROROS_POSIX_FREERTOS_OBJECTS += FreeRTOS_POSIX_clock.o 
MICROROS_POSIX_FREERTOS_OBJECTS += FreeRTOS_POSIX_sched.o 
MICROROS_POSIX_FREERTOS_OBJECTS += FreeRTOS_POSIX_unistd.o 
MICROROS_POSIX_FREERTOS_OBJECTS += FreeRTOS_POSIX_utils.o 
MICROROS_POSIX_FREERTOS_OBJECTS += libatomic.o

COLCON_INCLUDES += $(EXTENSIONS_DIR)/FreeRTOS-Plus-POSIX/include 
COLCON_INCLUDES += $(EXTENSIONS_DIR)/include 
COLCON_INCLUDES += $(EXTENSIONS_DIR)/include/private 
COLCON_INCLUDES += $(EXTENSIONS_DIR)/include/FreeRTOS_POSIX 
COLCON_INCLUDES += $(EXTENSIONS_DIR)/include/FreeRTOS_POSIX/sys
COLCON_INCLUDES += $(CRAZYFLIE_BASE)/src/hal/interface 
COLCON_INCLUDES += $(CRAZYFLIE_BASE)/src/modules/interface 
COLCON_INCLUDES += $(CRAZYFLIE_BASE)/src/utils/interface 
COLCON_INCLUDES += $(CRAZYFLIE_BASE)/src/config 
COLCON_INCLUDES += $(CRAZYFLIE_BASE)/src/drivers/interface
COLCON_INCLUDES_STR := $(foreach x,$(COLCON_INCLUDES),$(x)\n)


# Crazyflie 2.1 app configuration

APP = 1
APP_STACKSIZE = 2500
APP_PRIORITY = 3

PROJ_OBJ += microrosapp.o
MEMMANG_OBJ = custom_memory_manager.o
PROJ_OBJ += $(MICROROS_LIBRARIES) 
PROJ_OBJ += $(MICROROS_POSIX_FREERTOS_OBJECTS)
INCLUDES += $(MICROROS_INCLUDES)
VPATH += $(MICROROS_POSIX_FREERTOS_OBJECTS_VPATH) 
VPATH += $(SRC_DIR)/
CFLAGS += -DFREERTOS_HEAP_SIZE=50000
CROSS_COMPILE ?= $(TOPFOLDER)/toolchain/bin/arm-none-eabi-

include $(CRAZYFLIE_BASE)/Makefile

# micro-ROS targets

arm_toolchain: $(EXTENSIONS_DIR)/arm_toolchain.cmake.in
	rm -f $(EXTENSIONS_DIR)/arm_toolchain.cmake; \
	cat $(EXTENSIONS_DIR)/arm_toolchain.cmake.in | \
		sed "s/@CROSS_COMPILE@/$(subst /,\/,$(CROSS_COMPILE))/g" | \
		sed "s/@FREERTOS_TOPDIR@/$(subst /,\/,$(TOPFOLDER))/g" | \
		sed "s/@ARCH_CPU_FLAGS@/\"$(ARCHCPUFLAGS)\"/g" | \
		sed "s/@ARCH_OPT_FLAGS@/\"$(ARCHOPTIMIZATION)\"/g" | \
		sed "s/@INCLUDES@/$(subst /,\/,$(COLCON_INCLUDES_STR))/g" \
		> $(EXTENSIONS_DIR)/arm_toolchain.cmake

colcon_compile: arm_toolchain
	cd $(UROS_DIR); \
	colcon build \
		--packages-ignore-regex=.*_cpp \
		--cmake-args \
		-DCMAKE_POSITION_INDEPENDENT_CODE=OFF \
		-DTHIRDPARTY=ON \
		-DBUILD_SHARED_LIBS=OFF \
		-DBUILD_TESTING=OFF \
		-DCMAKE_BUILD_TYPE=$(BUILD_TYPE) \
		-DCMAKE_TOOLCHAIN_FILE=$(EXTENSIONS_DIR)/arm_toolchain.cmake \
		-DCMAKE_VERBOSE_MAKEFILE=ON; \

libmicroros: colcon_compile
	mkdir -p $(UROS_DIR)/libmicroros; cd $(UROS_DIR)/libmicroros; \
	for file in $$(find $(UROS_DIR)/install/ -name '*.a'); do \
		folder=$$(echo $$file | sed -E "s/(.+)\/(.+).a/\2/"); \
		mkdir -p $$folder; cd $$folder; ar x $$file; \
		for f in *; do \
			mv $$f ../$$folder-$$f; \
		done; \
		cd ..; rm -rf $$folder; \
	done ; \
	ar rc libmicroros.a *.obj; mkdir -p $(EXTENSIONS_DIR)/bin; cp libmicroros.a $(EXTENSIONS_DIR)/bin; ranlib $(EXTENSIONS_DIR)/bin/libmicroros.a; \
	cd ..; rm -rf libmicroros;