#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
TARGET_SUPPORTS_OMX_SERVICE := false
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit from hiphi device
$(call inherit-product, device/motorola/hiphi/device.mk)

# Inherit some common Lineage stuff.
$(call inherit-product, vendor/lineage/config/common_full_phone.mk)

PRODUCT_NAME := lineage_hiphi
PRODUCT_DEVICE := hiphi
PRODUCT_MANUFACTURER := motorola
PRODUCT_BRAND := motorola
PRODUCT_MODEL := motorola edge 30 pro

PRODUCT_GMS_CLIENTID_BASE := android-motorola

PRODUCT_BUILD_PROP_OVERRIDES += \
    DeviceProduct="hiphi_g" \
    BuildDesc="hiphi_g-user 14 U1SHS34.1-177-8-3 0be4e-aae78 release-keys" \
    BuildFingerprint="motorola/hiphi_g/hiphi:14/U1SHS34.1-177-8-3/0be4e-aae78:user/release-keys"
