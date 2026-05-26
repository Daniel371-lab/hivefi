plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.jplabs.hivefi"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.jplabs.hivefi"
        minSdk = 23
        targetSdk = 35
        versionCode = 11
        versionName = "1.0.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

// 👈 CONFIGURACIÓN CORREGIDA: Vincula el SDK de Flutter al compilador de Kotlin de la app
flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.5.1"))
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    
    // Vincula explícitamente las librerías nativas de Flutter incrustadas
    implementation(files("${project.property("flutter.sdk")}/packages/flutter_tools/gradle/flutter.jar")) {
        System.getenv("FLUTTER_ROOT")?.let {
            // En GitHub Actions, si local.properties no provee la propiedad, usa la ruta de la nube
            return@implementation files("$it/packages/flutter_tools/gradle/flutter.jar")
        }
    }
}
