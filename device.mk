#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

# Boot animation
TARGET_SCREEN_HEIGHT := 2400
TARGET_SCREEN_WIDTH := 1080

# Screen
TARGET_SCREEN_DENSITY := 400

# AAPT
PRODUCT_AAPT_CONFIG := normal
PRODUCT_AAPT_PREF_CONFIG := 400dpi
PRODUCT_AAPT_PREBUILT_DPI := xxxhdpi xxhdpi xhdpi hdpi

BOARD_SHIPPING_API_LEVEL := 31
PRODUCT_SHIPPING_API_LEVEL := $(BOARD_SHIPPING_API_LEVEL)

# Inherit from motorola sm8475-common
$(call inherit-product, device/motorola/sm8475-common/common.mk)

# Overlay
PRODUCT_PACKAGES += \
    FrameworksResDevice \
    LineageSdkResDevice \
    LineageSystemUIResDevice \
    SettingsResDevice \
    SystemUIResDevice

# Audio
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/configs/audio/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_taro/audio_policy_configuration.xml \
    $(LOCAL_PATH)/configs/audio/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_taro_qssi/audio_policy_configuration.xml \
    $(LOCAL_PATH)/configs/audio/mixer_paths_waipio_mtp.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_taro/mixer_paths_waipio_mtp.xml \
    $(LOCAL_PATH)/configs/audio/resourcemanager_waipio_mtp.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio/sku_taro/resourcemanager_waipio_mtp.xml \
    $(LOCAL_PATH)/configs/audio/audio_ext_spkr.conf:$(TARGET_COPY_OUT_VENDOR)/etc/audio_ext_spkr.conf \
    $(LOCAL_PATH)/configs/audio/usecaseKvManager.xml:$(TARGET_COPY_OUT_VENDOR)/etc/usecaseKvManager.xml

# Fingerprint
PRODUCT_PACKAGES += \
    android.hardware.biometrics.fingerprint@2.1-service.hiphi

# Init
PRODUCT_PACKAGES += \
    fstab.qcom \
    fstab.qcom.vendor_ramdisk \
    init.mmi.overlay.rc \
    init.vendor.st21nfc.rc \
    init.oem.fingerprint2.sh

# NFC
PRODUCT_PACKAGES += \
    android.hardware.nfc-service.st \
    com.android.nfc_extras \
    Tag

# Permissions
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.nfc.hcef.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.nfc.hcef.xml \
    frameworks/native/data/etc/com.nxp.mifare.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/com.nxp.mifare.xml

# PowerShare
PRODUCT_PACKAGES += \
    vendor.lineage.powershare-service.default

$(call soong_config_set,lineage_powershare,powershare_path,/sys/class/power_supply/wireless/device/tx_mode)

# Properties
PRODUCT_PACKAGES += \
    hardware.sku.XT2201-2.prop \
    hardware.sku.XT2201-3.prop \
    hardware.sku.XT2201-4.prop \
    hardware.sku.XT2201-6.prop

# Soong namespaces
PRODUCT_SOONG_NAMESPACES += $(LOCAL_PATH)

# VINTF
ODM_MANIFEST_SKUS +=  dn dnp n np
ODM_MANIFEST_DN_FILES := \
    $(LOCAL_PATH)/vintf/manifest_dn.xml
ODM_MANIFEST_DNP_FILES := \
    $(LOCAL_PATH)/vintf/manifest_dnp.xml
ODM_MANIFEST_N_FILES := \
    $(LOCAL_PATH)/vintf/manifest_n.xml \
    device/motorola/sm8475-common/vintf/manifest_ss.xml
ODM_MANIFEST_NP_FILES := \
    $(LOCAL_PATH)/vintf/manifest_np.xml \
    device/motorola/sm8475-common/vintf/manifest_ss.xml

# Inherit from vendor blobs (TEMP: commented until blob extraction)
$(call inherit-product, vendor/motorola/hiphi/hiphi-vendor.mk)

# Privapp permissions allowlist (fix: system_server crash on boot)
PRODUCT_COPY_FILES += \
    device/motorola/hiphi/permissions/privapp-permissions-hiphi.xml:$(TARGET_COPY_OUT_SYSTEM_EXT)/etc/permissions/privapp-permissions-hiphi.xml


# Display density override (DPI 420)
PRODUCT_PRODUCT_PROPERTIES += \
    ro.sf.lcd_density=420

# Dexopt: compilar apps a speed (apertura mas rapida)
PRODUCT_PRODUCT_PROPERTIES += \
    pm.dexopt.install=speed \
    pm.dexopt.bg-dexopt=speed
