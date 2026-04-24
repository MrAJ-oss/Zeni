buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}

// ✅ GLOBAL NAMESPACE FIX (VERY IMPORTANT)
subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            extensions.findByName("android")?.let { androidExt ->
                val namespaceField = androidExt.javaClass.getMethod("getNamespace")
                val currentNamespace = namespaceField.invoke(androidExt) as String?
                if (currentNamespace == null) {
                    androidExt.javaClass.getMethod("setNamespace", String::class.java)
                        .invoke(androidExt, project.group.toString())
                }
            }
        }
    }
}