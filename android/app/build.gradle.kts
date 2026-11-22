plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.coastalpearl.inventory"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.coastalpearl.inventory"
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = 1
        versionName = "1.0.0"
    }

    buildTypes {
        release {
            // Debug signing is intended for installable test builds only.
            signingConfig = signingConfigs.getByName("debug")

            // AGP 9.3+ requires code and resource shrinking to be enabled together.
            // This new DSL enables both R8 code optimization and resource shrinking.
            optimization {
                enable = true
            }
        }
    }
}

// AGP 9 built-in Kotlin compiler configuration.
kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
