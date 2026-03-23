#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/motorola/hiphi

# Inherit from motorola sm8475-common
include device/motorola/sm8475-common/BoardConfigCommon.mk

# Bootloader
TARGET_BOOTLOADER_BOARD_NAME := hiphi

# Kernel
TARGET_KERNEL_CONFIG += \
	vendor/ext_config/moto-waipio-hiphi.config \
	vendor/ext_config/moto-waipio-hiphic.config \
	vendor/ext_config/moto-waipio-hiphid.config

# Partitions
BOARD_MOT_DP_GROUP_SIZE := 9659482112 # ( BOARD_SUPER_PARTITION_SIZE - 4MB )
BOARD_SUPER_PARTITION_SIZE := 9663676416

# Properties
TARGET_PRODUCT_PROP += $(DEVICE_PATH)/product.prop
TARGET_SYSTEM_PROP += $(DEVICE_PATH)/system.prop
TARGET_VENDOR_PROP += $(DEVICE_PATH)/vendor.prop

# Recovery
TARGET_RECOVERY_UI_MARGIN_HEIGHT := 90
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/init/fstab.qcom

# Security
BOOT_SECURITY_PATCH := 2025-02-01
VENDOR_SECURITY_PATCH := $(BOOT_SECURITY_PATCH)

# Verified Boot
BOARD_AVB_ROLLBACK_INDEX := 25
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX := $(BOARD_AVB_ROLLBACK_INDEX)

# inherit from the proprietary version
include vendor/motorola/hiphi/BoardConfigVendor.mk
