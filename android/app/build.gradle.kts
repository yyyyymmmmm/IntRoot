plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.inkroot.notes"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"  // 指定需要的 NDK 版本

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.inkroot.notes"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            // 启用 R8 压缩和资源压缩
            isMinifyEnabled = true
            isShrinkResources = true
            
            // 配置 Proguard/R8 规则
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {}
