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

app_gradle = """plugins {
    id "com.google.gms.google-services"
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
}

def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.jplabs.hivefi"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_1_8
    }

    defaultConfig {
        applicationId = "com.jplabs.hivefi"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }

    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled false
            shrinkResources false
        }
    }
}

flutter {
    source = "../.."
}
"""

with open('android/app/build.gradle', 'w') as f:
    f.write(app_gradle)

manifest_path = 'android/app/src/main/AndroidManifest.xml'
if os.path.exists(manifest_path):
    with open(manifest_path, 'r') as f:
        content = f.read()
    content = re.sub(r'android:label="[^"]*"', 'android:label="Hive-Fi"', content)
    if 'APPLICATION_ID' not in content:
        admob_meta = (
            '\n        <meta-data\n'
            '            android:name="com.google.android.gms.ads.APPLICATION_ID"\n'
            '            android:value="ca-app-pub-2628699742979891~7557734775"/>'
        )
        content = re.sub(r'(<application[^>]*>)', r'\1' + admob_meta, content)
    with open(manifest_path, 'w') as f:
        f.write(content)