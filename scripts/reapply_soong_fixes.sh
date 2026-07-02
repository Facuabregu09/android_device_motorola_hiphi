#!/bin/bash
set -e
cd ~/android/hiphi-a14
BP="vendor/motorola/sm8475-common/Android.bp"

# 1. wifidisplaysession vendor: sacar sufijo _vendor
sed -i 's/name: "vendor.qti.hardware.wifidisplaysession@1.0_vendor",/name: "vendor.qti.hardware.wifidisplaysession@1.0",/' "$BP"

# 2. wifidisplaysession system_ext: renombrar (solo la definición con system_ext_specific cerca)
python3 << 'PYEOF'
import re
with open("vendor/motorola/sm8475-common/Android.bp") as f:
    content = f.read()

# Buscar el bloque system_ext_specific que define wifidisplaysession@1.0 sin stem
pattern = r'(cc_prebuilt_library_shared \{\n    name: "vendor\.qti\.hardware\.wifidisplaysession@1\.0",\n)(    owner:.*?\n    strip: \{\n        none: true,\n    \},\n    target: \{\n        android_arm64: \{\n            srcs: \[\n                "proprietary/system_ext/lib64/vendor\.qti\.hardware\.wifidisplaysession@1\.0\.so",)'
replacement = r'cc_prebuilt_library_shared {\n    name: "vendor.qti.hardware.wifidisplaysession@1.0_system_ext",\n    stem: "vendor.qti.hardware.wifidisplaysession@1.0",\n\2'
new_content = re.sub(pattern, replacement, content, count=1)

if new_content != content:
    with open("vendor/motorola/sm8475-common/Android.bp", "w") as f:
        f.write(new_content)
    print("wifidisplaysession system_ext: RENAMED")
else:
    print("wifidisplaysession system_ext: NO CHANGE (pattern not found, check manually)")
PYEOF

# 3. Consumidores de system_ext que deben apuntar al nombre renombrado
sed -i '0,/vendor.qti.hardware.wifidisplaysession@1.0_system_ext/! {/"vendor.qti.hardware.wifidisplaysession@1.0",/{x;/libwfdservice/!{x;b};x}}' "$BP" 2>/dev/null || true

# 4. qspmhal: sacar sufijo en todas las referencias
sed -i 's/"vendor.qti.qspmhal@1.0_vendor"/"vendor.qti.qspmhal@1.0"/g' "$BP"

# 5. Deshabilitar módulos WFD problemáticos (AIDL frozen / dependencias rotas)
for MODULE in "libwfdservice" "wfdservice64" "libwfdmminterface" "libwfdconfigutils"; do
    python3 << PYEOF
import re
with open("$BP") as f:
    lines = f.readlines()
for i, line in enumerate(lines):
    if 'name: "$MODULE"' in line and 'enabled: false' not in lines[i+1]:
        lines.insert(i+1, '    enabled: false,\n')
        with open("$BP", "w") as f:
            f.writelines(lines)
        print("$MODULE: disabled")
        break
PYEOF
done

# 6. Sacar libwpa_client (lowi-server/qms/libcne) y libqsap_sdk (libmdmcutback) de shared_libs
sed -i "/\"libwpa_client\",/d" "$BP"
sed -i "/\"libqsap_sdk\",/d" "$BP"

echo ""
echo "=== VERIFICACIÓN ==="
echo "Referencias viejas restantes (debe ser 0):"
grep -c '_vendor"\|"libwpa_client",\|"libqsap_sdk",' "$BP" | grep -v qspmhal || true
echo "Módulos deshabilitados:"
grep -B1 "enabled: false," "$BP" | grep "name:" | grep -E "wfd"

# 7. Deshabilitar TODA la cadena WFD de una vez (Miracast/casting, no crítico)
python3 << 'PYEOF2'
import re
with open("vendor/motorola/sm8475-common/Android.bp") as f:
    lines = f.readlines()
count = 0
i = 0
while i < len(lines):
    m = re.search(r'name: "([\w@.-]*wfd[\w@.-]*|[\w@.-]*[Ww]ifi[Dd]isplay[\w@.-]*)"', lines[i])
    if m and i+1 < len(lines) and 'enabled: false' not in lines[i+1]:
        lines.insert(i+1, '    enabled: false,\n')
        count += 1
        i += 1
    i += 1
with open("vendor/motorola/sm8475-common/Android.bp", "w") as f:
    f.writelines(lines)
print(f"WFD chain: disabled {count} modules")
PYEOF2

# 8. Agregar liblx-osal a libar-gpr, liblx-ar_util, libar-acdb, libar-gsl
python3 << 'PYEOF3'
import re
with open("vendor/motorola/sm8475-common/Android.bp") as f:
    content = f.read()

for mod in ["libar-gpr", "liblx-ar_util", "libar-acdb"]:
    pattern = rf'(name: "{re.escape(mod)}",.*?shared_libs: \[\n)((?:                "[^"]*",\n)*?)(            \],)'
    def add_osal(m):
        if "liblx-osal" in m.group(2):
            return m.group(0)
        return m.group(1) + '                "liblx-osal",\n' + m.group(2) + m.group(3)
    content = re.sub(pattern, add_osal, content, flags=re.DOTALL)

# libar-gsl needs both libar-acdb and liblx-osal
pattern = r'(name: "libar-gsl",.*?"libar-gpr",\n)((?:                "[^"]*",\n)*?)(            \],)'
def add_gsl_deps(m):
    extra = ""
    if "libar-acdb" not in m.group(2):
        extra += '                "libar-acdb",\n'
    if "liblx-osal" not in m.group(2):
        extra += '                "liblx-osal",\n'
    return m.group(1) + extra + m.group(2) + m.group(3)
content = re.sub(pattern, add_gsl_deps, content, flags=re.DOTALL)

with open("vendor/motorola/sm8475-common/Android.bp", "w") as f:
    f.write(content)
print("AR/GSL audio deps: applied")
PYEOF3

# 9. libats necesita liblx-osal y libar-acdb también
python3 << 'PYEOF4'
import re
with open("vendor/motorola/sm8475-common/Android.bp") as f:
    content = f.read()
pattern = r'(name: "libats",.*?"libar-gsl",\n)((?:                "[^"]*",\n)*?)(            \],)'
def add_ats_deps(m):
    extra = ""
    if "liblx-osal" not in m.group(2):
        extra += '                "liblx-osal",\n'
    if "libar-acdb" not in m.group(2):
        extra += '                "libar-acdb",\n'
    return m.group(1) + extra + m.group(2) + m.group(3)
content = re.sub(pattern, add_ats_deps, content, flags=re.DOTALL)
with open("vendor/motorola/sm8475-common/Android.bp", "w") as f:
    f.write(content)
print("libats deps: applied")
PYEOF4

# 11. audio.primary.taro: mismo patrón, conflicto con código fuente CAF
python3 << 'PYEOF6'
import re
with open("vendor/motorola/sm8475-common/Android.bp") as f:
    content = f.read()
pattern = r'(name: "audio\.primary\.taro",\n)'
replacement = r'name: "audio.primary.taro_vendor",\n    stem: "audio.primary.taro",\n'
new_content = re.sub(pattern, replacement, content, count=1)
if new_content != content:
    with open("vendor/motorola/sm8475-common/Android.bp", "w") as f:
        f.write(new_content)
    print("audio.primary.taro: RENAMED")
else:
    print("audio.primary.taro: NO CHANGE")
PYEOF6

# 12. Agregar overrides a AGMIPC@1.0_vendor y audio.primary.taro_vendor
python3 << 'PYEOF7'
import re
with open("vendor/motorola/sm8475-common/Android.bp") as f:
    content = f.read()

for name, override in [
    ("vendor.qti.hardware.AGMIPC@1.0_vendor", "vendor.qti.hardware.AGMIPC@1.0"),
    ("audio.primary.taro_vendor", "audio.primary.taro"),
]:
    pattern = rf'(name: "{re.escape(name)}",\n)'
    if f'overrides: ["{override}"]' not in content:
        content = re.sub(pattern, rf'\1    overrides: ["{override}"],\n', content, count=1)

with open("vendor/motorola/sm8475-common/Android.bp", "w") as f:
    f.write(content)
print("overrides: applied")
PYEOF7

# 13. libmdmcutback: agregar check_elf_files: false (libqsap_sdk no existe, no se puede declarar)
python3 << 'PYEOF8'
import re
with open("vendor/motorola/sm8475-common/Android.bp") as f:
    content = f.read()
pattern = r'(name: "libmdmcutback",\n)'
if 'check_elf_files: false,' not in content.split('name: "libmdmcutback"')[1][:200]:
    content = re.sub(pattern, r'\1    check_elf_files: false,\n', content, count=1)
    with open("vendor/motorola/sm8475-common/Android.bp", "w") as f:
        f.write(content)
    print("libmdmcutback: check_elf_files false applied")
else:
    print("libmdmcutback: already has check_elf_files false")
PYEOF8

# 14. check_elf_files: false para módulos con DT_NEEDED de libs inexistentes (libwpa_client, libqsap_sdk)
python3 << 'PYEOF9'
import re
with open("vendor/motorola/sm8475-common/Android.bp") as f:
    content = f.read()
for name in ["libmdmcutback", "libcne", "lowi-server", "qms"]:
    pattern = rf'(name: "{re.escape(name)}",\n)'
    if not re.search(rf'name: "{re.escape(name)}",\n    check_elf_files: false,', content):
        content = re.sub(pattern, r'\1    check_elf_files: false,\n', content, count=1)
with open("vendor/motorola/sm8475-common/Android.bp", "w") as f:
    f.write(content)
print("check_elf_files false: applied to libmdmcutback/libcne/lowi-server/qms")
PYEOF9

# 15. AGMIPC@1.0-impl necesita libagm en shared_libs
python3 << 'PYEOF10'
import re
with open("vendor/motorola/sm8475-common/Android.bp") as f:
    content = f.read()
pattern = r'(name: "vendor\.qti\.hardware\.AGMIPC@1\.0-impl",.*?"libar-gsl",\n)'
if not re.search(r'name: "vendor\.qti\.hardware\.AGMIPC@1\.0-impl",[\s\S]{0,300}"libagm"', content):
    content = re.sub(pattern, r'\1'.replace('"libar-gsl",\n', '"libagm",\n                "libar-gsl",\n'), content, count=1, flags=re.DOTALL)
with open("vendor/motorola/sm8475-common/Android.bp", "w") as f:
    f.write(content)
print("AGMIPC@1.0-impl: libagm dependency applied")
PYEOF10

# 16. libagm necesita liblx-osal y libats
python3 << 'PYEOF11'
import re
with open("vendor/motorola/sm8475-common/Android.bp") as f:
    content = f.read()
pattern = r'(name: "libagm",[\s\S]{0,200}?shared_libs: \[\n)'
if not re.search(r'name: "libagm",[\s\S]{0,300}"liblx-osal"', content):
    content = re.sub(pattern, r'\1                "liblx-osal",\n                "libats",\n', content, count=1)
with open("vendor/motorola/sm8475-common/Android.bp", "w") as f:
    f.write(content)
print("libagm: liblx-osal/libats applied")
PYEOF11

# 17. Sacar libprotobuf-cpp-lite-3.9.1 (no existe como módulo declarable en Soong)
sed -i '/"libprotobuf-cpp-lite-3.9.1",/d' "$BP"
sed -i '/"libprotobuf-cpp-lite-3.9.1-vendorcompat",/d' "$BP"
echo "libprotobuf-cpp-lite-3.9.1: removed from shared_libs"
