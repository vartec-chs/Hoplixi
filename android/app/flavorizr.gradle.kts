import com.android.build.gradle.AppExtension

val android = project.extensions.getByType(AppExtension::class.java)

android.apply {
    flavorDimensions("flavor-type")

    productFlavors {
        create("dev") {
            dimension = "flavor-type"
            applicationId = "com.hiplixi.app.dev"
            resValue(type = "string", name = "app_name", value = "Hoplixi Dev")
        }
        create("prod") {
            dimension = "flavor-type"
            applicationId = "com.hiplixi.app"
            resValue(type = "string", name = "app_name", value = "Hoplixi")
        }
    }
}