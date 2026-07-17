import os
import re

def eliminar_si_existe(path):
    if os.path.exists(path):
        os.remove(path)

eliminar_si_existe('android/settings.gradle.kts')
eliminar_si_existe('android/app/build.gradle.kts')

settings_gradle = """pluginManagement {
    def flutterSdkPath = {
        def properties = new Properties()
        file("local.properties").withInputStream { properties.load(it) }
        def flutterSdkPath = properties.getProperty("flutter.sdk")
        assert flutterSdkPath != null, "flutter.sdk not set in local.properties"
        return flutterSdkPath
    }()

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id "dev.flutter.flutter-plugin-loader" version "1.0.0"
    id "com.android.application" version "8.13.0" apply false
    id "org.jetbrains.kotlin.android" version "2.2.20" apply false
    id "com.google.gms.google-services" version "4.4.2" apply false
}

include ":app"
"""

with open('android/settings.gradle', 'w') as f:
    f.write(settings_gradle)

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
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
            ndk {
                debugSymbolLevel 'SYMBOL_TABLE'
            }
        }
    }
}

flutter {
    source = "../.."
}
"""

with open('android/app/build.gradle', 'w') as f:
    f.write(app_gradle)

proguard_rules = """-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.android.billingclient.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**
"""

with open('android/app/proguard-rules.pro', 'w') as f:
    f.write(proguard_rules)

wrapper_path = 'android/gradle/wrapper/gradle-wrapper.properties'
if os.path.exists(wrapper_path):
    with open(wrapper_path, 'r') as f:
        content = f.read()
    content = re.sub(
        r'distributionUrl=.*',
        'distributionUrl=https\\://services.gradle.org/distributions/gradle-8.14.2-bin.zip',
        content
    )
    with open(wrapper_path, 'w') as f:
        f.write(content)

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