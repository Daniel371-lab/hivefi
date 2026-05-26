pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        val propertiesFile = file("local.properties")
        
        if (propertiesFile.exists()) {
            propertiesFile.inputStream().use { properties.load(it) }
            properties.getProperty("flutter.sdk")
        } else {
            System.getenv("FLUTTER_ROOT")
        } ?: throw GradleException("Flutter SDK path not found")
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("com.android.application") version "8.3.2" apply false
    id("org.jetbrains.kotlin.android") version "2.0.21" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
    id("dev.flutter.flutter-gradle-plugin") version "1.0.0" apply false // 👈 AGREGADO: Declaración global del plugin
}

include(":app")
