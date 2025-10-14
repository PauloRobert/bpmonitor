//android/app/build.gradle.kts
plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "br.codemobilesolutions.bpmonitor"
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
        applicationId = "br.codemobilesolutions.bpmonitor"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // 🔐 Configuração de assinatura compatível com Kotlin DSL
    signingConfigs {
        create("release") {
            storeFile = file(findProperty("MYAPP_UPLOAD_STORE_FILE") as String)
            storePassword = findProperty("MYAPP_UPLOAD_STORE_PASSWORD") as String
            keyAlias = findProperty("MYAPP_UPLOAD_KEY_ALIAS") as String
            keyPassword = findProperty("MYAPP_UPLOAD_KEY_PASSWORD") as String
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")

            // 🔹 Ativa minificação e remoção de recursos não usados
            isMinifyEnabled = true
            isShrinkResources = true

            // 🔹 Define arquivos de regras do ProGuard/R8
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