import java.util.Properties                          // ✅ Fix 1: explicit import, not java.util.Properties()

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

val flutterVersionCode = localProperties.getProperty("flutter.versionCode") ?: "1"
val flutterVersionName = localProperties.getProperty("flutter.versionName") ?: "1.0"

android {
    namespace = "com.kashly.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true          // ✅ flutter_local_notifications desugaring
        sourceCompatibility = JavaVersion.VERSION_11   // ✅ 1.8 → 11 (AGP 8+ recommendation)
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        // ✅ Fix 2: compilerOptions DSL replaces deprecated jvmTarget string assignment
        freeCompilerArgs += listOf("-Xjvm-default=all")
    }

    kotlin {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)  // ✅ new DSL
        }
    }

    defaultConfig {
        applicationId = "com.kashly.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")  // ✅ desugaring
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8")
    implementation("androidx.multidex:multidex:2.0.1")
}
