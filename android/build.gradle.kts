allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    // 1. Set build directory
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // 2. 🛡️ SHIELD: AGP 8.x Compatibility fix
    // Fix: Using a more robust check and forced cast to handle Isar's legacy build file
    project.plugins.withId("com.android.library") {
        project.extensions.getByType<com.android.build.gradle.LibraryExtension>().apply {
            // 1. Inject Namespace if missing (fixes the first error we saw)
            if (namespace == null) {
                namespace = "com.fix.missing_namespace.${project.name.replace("-", "_")}"
            }
        }

        // 🛡️ SHIELD: Manifest Stripper
        // This surgically removes the 'package' attribute from library manifests 
        // to satisfy AGP 8.x requirements for legacy libraries like Isar.
        project.tasks.withType<com.android.build.gradle.tasks.ProcessLibraryManifest>().configureEach {
            doFirst {
                val manifestFile = mainManifest.get().asFile
                if (manifestFile.exists()) {
                    val content = manifestFile.readText()
                    if (content.contains("package=")) {
                        // Remove the package attribute while preserving other manifest data
                        val updatedContent = content.replace(Regex("""package="[^"]*""""), "")
                        manifestFile.writeText(updatedContent)
                    }
                }
            }
        }
    }
    project.plugins.withId("com.android.application") {
        project.extensions.getByType<com.android.build.gradle.AppExtension>().apply {
            if (namespace == null) {
                namespace = "com.fix.missing_namespace.${project.name.replace("-", "_")}"
            }
        }
    }
}

// Fix: Removed the standalone 'evaluationDependsOn(":app")' block as it causes early evaluation conflicts

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

plugins {
  // ...

  // Add the dependency for the Google services Gradle plugin
  id("com.google.gms.google-services") version "4.4.3" apply false

}