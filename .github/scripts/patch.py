import os
import re

settings_path = 'android/settings.gradle'
if os.path.exists(settings_path):
    with open(settings_path, 'r') as f:
        content = f.read()
    if 'com.google.gms.google-services' not in content:
        content = content.replace('plugins {', 'plugins {\n    id "com.google.gms.google-services" version "4.4.2" apply false')
        with open(settings_path, 'w') as f:
            f.write(content)

app_path = 'android/app/build.gradle'
if os.path.exists(app_path):
    with open(app_path, 'r') as f:
        content = f.read()

    if 'com.google.gms.google-services' not in content:
        content = content.replace('plugins {', 'plugins {\n    id "com.google.gms.google-services"')

    content = content.replace('minSdk = flutter.minSdkVersion', 'minSdk = 23')
    content = content.replace('minSdkVersion = flutter.minSdkVersion', 'minSdk = 23')

    signing_block = (
        "def keystoreProperties = new Properties()\n"
        "def keystorePropertiesFile = rootProject.file('key.properties')\n"
        "if (keystorePropertiesFile.exists()) {\n"
        "    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))\n"
        "}\n\n"
    )
    if 'keystoreProperties' not in content:
        content = re.sub(r'(plugins \{[^}]*\})', r'\1\n\n' + signing_block, content, count=1)

    signing_config_block = (
        "\n    signingConfigs {\n"
        "        release {\n"
        "            keyAlias keystoreProperties['keyAlias']\n"
        "            keyPassword keystoreProperties['keyPassword']\n"
        "            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null\n"
        "            storePassword keystoreProperties['storePassword']\n"
        "        }\n"
        "    }\n\n"
    )
    if 'signingConfigs' not in content:
        content = re.sub(r'(android\s*\{)', r'\1' + signing_config_block, content, count=1)

    # Reemplazar el bloque release completo
    content = re.sub(
        r'release\s*\{[^}]*\}',
        'release {\n            signingConfig signingConfigs.release\n        }',
        content,
        count=1
    )

    with open(app_path, 'w') as f:
        f.write(content)

manifest_path = 'android/app/src/main/AndroidManifest.xml'
if os.path.exists(manifest_path):
    with open(manifest_path, 'r') as f:
        content = f.read()
    if 'APPLICATION_ID' not in content:
        admob_meta = (
            '\n        <meta-data\n'
            '            android:name="com.google.android.gms.ads.APPLICATION_ID"\n'
            '            android:value="ca-app-pub-2628699742979891~7557734775"/>'
        )
        content = re.sub(r'(<application[^>]*>)', r'\1' + admob_meta, content)
        with open(manifest_path, 'w') as f:
            f.write(content)