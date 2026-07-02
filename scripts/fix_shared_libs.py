import re
import sys

BP = "vendor/motorola/sm8475-common/Android.bp"

def add_libs_to_module(lines, module_name, libs_to_add):
    n = len(lines)
    i = 0
    changed = False
    while i < n:
        if f'name: "{module_name}",' in lines[i]:
            depth = 1
            j = i + 1
            while j < n and depth > 0:
                depth += lines[j].count('{') - lines[j].count('}')
                if depth <= 0:
                    break
                if 'shared_libs: [' in lines[j]:
                    block_end = j + 1
                    while block_end < n and ']' not in lines[block_end]:
                        block_end += 1
                    existing = '\n'.join(lines[j+1:block_end])
                    to_insert = [f'                "{lib}",' for lib in libs_to_add if f'"{lib}"' not in existing]
                    if to_insert:
                        lines[j+1:j+1] = to_insert
                        n = len(lines)
                        j += len(to_insert)
                        changed = True
                j += 1
            i = j
        else:
            i += 1
    return lines, changed

with open(BP) as f:
    lines = f.read().split('\n')

fixes = [
    ("vendor.qti.hardware.AGMIPC@1.0-service", ["libagm"]),
    ("libqtigefar", ["libar-pal"]),
    ("libqcompostprocbundle", ["libar-pal"]),
    ("libqcomvisualizer", ["libar-pal"]),
    ("libqc2audio_hwaudiocodec", ["libpalclient"]),
    ("libmcs", ["libagm", "libar-acdb", "libats", "liblx-osal"]),
    ("libfmpal", ["libar-pal"]),
    ("audio.primary.taro_vendor", ["libar-pal", "lib_lvacfs", "liblvacfs_wrapper", "vendor.qti.hardware.pal@1.0-impl", "vendor.qti.hardware.pal@1.0"]),
    ("libar-pal", ["liblx-osal"]),
    ("libagm_compress_plugin", ["libsndcardparser"]),
    ("libagm_mixer_plugin", ["libsndcardparser"]),
    ("libagm_pcm_plugin", ["libsndcardparser"]),
    ("vendor.qti.hardware.pal@1.0-impl", ["libar-pal"]),
    ("libar-gpr", ["liblx-osal"]),
    ("liblx-ar_util", ["liblx-osal"]),
    ("libar-acdb", ["liblx-osal"]),
    ("libar-gsl", ["libar-acdb", "liblx-osal"]),
    ("libats", ["liblx-osal", "libar-acdb"]),
    ("libagm", ["liblx-osal", "libats"]),
    ("vendor.qti.hardware.AGMIPC@1.0-impl", ["libagm"]),
]

for module, libs in fixes:
    lines, changed = add_libs_to_module(lines, module, libs)
    print(f"{module}: {'updated' if changed else 'no change (already ok or not found)'}")

with open(BP, "w") as f:
    f.write('\n'.join(lines))

def disable_module(lines, module_name):
    n = len(lines)
    for i in range(n):
        if f'name: "{module_name}",' in lines[i]:
            if 'enabled: false' not in lines[i+1]:
                lines.insert(i+1, '    enabled: false,')
                return lines, True
            return lines, False
    return lines, False

for mod in ["libmmrtpencoder", "libmmrtpdecoder", "wfdhdcphalservice", "wfdvndservice", "wifidisplayhalservice"]:
    lines, changed = disable_module(lines, mod)
    print(f"{mod}: {'disabled' if changed else 'no change'}")

with open(BP, "w") as f:
    f.write('\n'.join(lines))

fixes2 = [
    ("lib-imsvtcore", ["vendor.qti.imsrtpservice@3.0"]),
    ("libdpmqmihal", ["com.qualcomm.qti.dpm.api@1.0"]),
    ("libqcc_file_agent", ["vendor.qti.hardware.qccsyshal@1.0", "vendor.qti.hardware.qccsyshal@1.1"]),
    ("libsensorcal", ["libprotobuf-cpp-lite-3.9.1"]),
    ("libsnsapi", ["libprotobuf-cpp-lite-3.9.1"]),
    ("libsnsdiaglog", ["libprotobuf-cpp-lite-3.9.1"]),
    ("libssc", ["libprotobuf-cpp-lite-3.9.1"]),
    ("libwvhidl", ["libprotobuf-cpp-lite-3.9.1"]),
    ("sensors.ssc", ["libprotobuf-cpp-lite-3.9.1"]),
    ("vendor.libdpmctmgr", ["com.qualcomm.qti.dpm.api@1.0"]),
    ("vendor.libdpmfdmgr", ["com.qualcomm.qti.dpm.api@1.0"]),
    ("vendor.libdpmframework", ["com.qualcomm.qti.dpm.api@1.0"]),
    ("vendor.libdpmtcm", ["com.qualcomm.qti.dpm.api@1.0"]),
    ("vendor.libmwqemiptablemgr", ["com.qualcomm.qti.dpm.api@1.0"]),
    ("vendor.qti.hardware.qccsyshal@1.1", ["vendor.qti.hardware.qccsyshal@1.0"]),
    ("libvolumelistener", ["libar-pal"]),
]

with open(BP) as f:
    lines2 = f.read().split('\n')

for module, libs in fixes2:
    lines2, changed = add_libs_to_module(lines2, module, libs)
    print(f"{module}: {'updated' if changed else 'no change'}")

with open(BP, "w") as f:
    f.write('\n'.join(lines2))

DPM_VENDOR_MODULES = ["libdpmqmihal", "vendor.libdpmctmgr", "vendor.libdpmfdmgr", "vendor.libdpmframework", "vendor.libdpmtcm", "vendor.libmwqemiptablemgr"]

def fix_dpm_api_refs(lines):
    changed = False
    n = len(lines)
    for mod in DPM_VENDOR_MODULES:
        i = 0
        while i < n:
            if f'name: "{mod}",' in lines[i]:
                depth = 1
                j = i + 1
                while j < n and depth > 0:
                    depth += lines[j].count('{') - lines[j].count('}')
                    if depth <= 0:
                        break
                    if lines[j].strip() == '"com.qualcomm.qti.dpm.api@1.0",':
                        lines[j] = lines[j].replace('"com.qualcomm.qti.dpm.api@1.0",', '"com.qualcomm.qti.dpm.api@1.0_vendor",')
                        changed = True
                    j += 1
                i = j
            else:
                i += 1
    return lines, changed

with open(BP) as f:
    lines3 = f.read().split('\n')
lines3, changed = fix_dpm_api_refs(lines3)
print(f"dpm.api refs: {'fixed' if changed else 'no change'}")
with open(BP, "w") as f:
    f.write('\n'.join(lines3))

def add_check_elf_false(lines, module_name):
    n = len(lines)
    for i in range(n):
        if f'name: "{module_name}",' in lines[i]:
            if 'check_elf_files: false' not in lines[i+1]:
                lines.insert(i+1, '    check_elf_files: false,')
                return lines, True
            return lines, False
    return lines, False

with open(BP) as f:
    lines4 = f.read().split('\n')

for mod in ["libsensorcal", "libsnsapi", "libsnsdiaglog", "libssc", "libwvhidl", "sensors.ssc", "lib-imsvtcore", "libqcc_file_agent"]:
    lines4, changed = add_check_elf_false(lines4, mod)
    print(f"{mod}: check_elf_files {'added' if changed else 'no change'}")

with open(BP, "w") as f:
    f.write('\n'.join(lines4))
