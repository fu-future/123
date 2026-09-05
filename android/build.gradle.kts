buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:9.1.0")
    }
}

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

// 统一把所有(含第三方插件)模块的 compileSdk 抬到 36，
// 否则 file_picker 等插件模块会因 AAR 元数据要求编译失败。
subprojects {
    afterEvaluate {
        val android = extensions.findByName("android")
        when (android) {
            is com.android.build.api.dsl.ApplicationExtension -> android.compileSdk = 36
            is com.android.build.api.dsl.LibraryExtension -> android.compileSdk = 36
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
