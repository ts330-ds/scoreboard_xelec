allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Helper to load properties from local.properties
val localProperties = java.util.Properties()
val localPropertiesFile = rootProject.file("local.properties")
if (localPropertiesFile.exists()) {
    localPropertiesFile.inputStream().use { localProperties.load(it) }
}

val flutterSdkPath = localProperties.getProperty("flutter.sdk") ?: "/Users/tusharsoni/Software/flutter3.27.3"

subprojects {
    // This allows plugins using the old 'flutter.compileSdkVersion' syntax to find the values
    project.extensions.extraProperties.set("flutter", object {
        val compileSdkVersion = (localProperties.getProperty("flutter.compileSdkVersion") ?: "34").toInt()
        val minSdkVersion = (localProperties.getProperty("flutter.minSdkVersion") ?: "21").toInt()
        val targetSdkVersion = (localProperties.getProperty("flutter.targetSdkVersion") ?: "34").toInt()
        val ndkVersion = localProperties.getProperty("flutter.ndkVersion") ?: "25.1.8937393"
    })

    // Add flutter.jar and androidx dependencies to plugin subprojects for compilation
    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.library")) {
            project.dependencies {
                add("compileOnly", files("$flutterSdkPath/bin/cache/artifacts/engine/android-arm-release/flutter.jar"))
                add("implementation", "androidx.annotation:annotation:1.7.1")
                add("implementation", "androidx.core:core:1.12.0")
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
