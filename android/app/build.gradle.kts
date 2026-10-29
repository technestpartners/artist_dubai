plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android plugin.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.imbu.DubaiArtists"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.imbu.DubaiArtists"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

tasks.matching { it.name == "assembleRelease" }.configureEach {
    doLast {
        val buildDir = layout.buildDirectory.asFile.get()
        val sourceApk = File(buildDir, "outputs/apk/release/app-release.apk")
        val flutterApkDir = file("${project.rootDir}/../build/app/outputs/flutter-apk")
        if (sourceApk.exists()) {
            val appName = "Artist Dubai"
            val version = flutter.versionName ?: "3.2.5"
            sourceApk.copyTo(File(flutterApkDir, "$appName.apk"), overwrite = true)
            sourceApk.copyTo(File(flutterApkDir, "Artist_Dubai.apk"), overwrite = true)
            sourceApk.copyTo(File(flutterApkDir, "ArtistDubai-v$version.apk"), overwrite = true)
        }
    }
}
