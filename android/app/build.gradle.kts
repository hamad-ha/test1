plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // Correct Google Services plugin
}

android {
    namespace = "com.example.test1" // Update to a unique ID for production
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.test1" // Update to match namespace
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true // Enable if using Firebase or other large libraries
    }

    signingConfigs {
        release {
            // Example: Load signing config from a properties file or environment variables
            keyAlias = project.findProperty("keyAlias") ?: "your_key_alias"
            keyPassword = project.findProperty("keyPassword") ?: "your_key_password"
            storeFile = file(project.findProperty("storeFile") ?: "path/to/keystore.jks")
            storePassword = project.findProperty("storePassword") ?: "your_store_password"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.release // Use release signing config
            minifyEnabled = true // Enable code shrinking
            proguardFiles getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro"
        }
        debug {
            signingConfig = signingConfigs.debug
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Add Firebase or other dependencies if needed
    implementation platform("com.google.firebase:firebase-bom:33.1.0") // Use latest Firebase BOM
    implementation "com.google.firebase:firebase-analytics"
    // Add other Firebase libraries as needed
}