import os
import re

gradle_properties_path = 'android/gradle.properties'
if os.path.exists(gradle_properties_path):
    with open(gradle_properties_path, 'r') as f:
        content = f.read()
    if 'android.newDsl' not in content:
        content += '\nandroid.newDsl=false\nandroid.builtInKotlin=false\n'
        with open(gradle_properties_path, 'w') as f:
            f.write(content)

settings_path = 'android/settings.gradle.kts'
if os.path.exists(settings_path):
    with open(settings_path, 'r') as f:
        content = f.read()
    if 'com.google.gms.google-services' not in content:
        content = content.replace(
            'plugins {',
            'plugins {\n    id("com.google.gms.google-services") version "4.4.2" apply false',
            1
        )
        with open(settings_path, 'w') as f:
            f.write(content)

app_gradle_kts = """import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.google.gms.google-services")
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
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
        jvmTarget = JavaVersion.VERSION_1_8.toString()
    }

    defaultConfig {
        applicationId = "com.jplabs.hivefi"
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            ndk {
                debugSymbolLevel = "FULL"
            }
        }
    }
}

flutter {
    source = "../.."
}
"""

with open('android/app/build.gradle.kts', 'w') as f:
    f.write(app_gradle_kts)

proguard_rules = """-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.android.billingclient.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
"""

with open('android/app/proguard-rules.pro', 'w') as f:
    f.write(proguard_rules)

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