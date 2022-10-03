# Define target output
target: bit

# Define Firmware Version: v1.0.0.0
export PRJ_VERSION = 0x01000000

# Define target part
export PRJ_PART = xc7a100tcsg324-2

# Define the TOP_DIR path
export TOP_DIR = $(abspath $(PWD)/../..)

# Using XVC Debug bridge
export USE_XVC_DEBUG = 0

# Setup for releases.yaml
export RELEASE = electron_event_generator

# Use top level makefile
include ../../submodules/ruckus/system_vivado.mk
