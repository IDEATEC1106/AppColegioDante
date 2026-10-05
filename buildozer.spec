[app]
title = App Colegio Dante
package.name = appcolegiodante
package.domain = org.colegio
source.dir = .
source.include_exts = py,png,jpg,kv,atlas
version = 0.1
requirements = python3,kivy
orientation = portrait
fullscreen = 0
# (str) Target version of Android to compile for
android.api_target = 31

# (str) Which Android SDK to use
android.sdk_version = 31

# (str) Android NDK version to use
android.ndk_version = 23b

# (bool) Indicate whether the user agrees to the Android SDK Terms & Conditions
android.accept_sdk_license = True
android.archs = arm64-v8a, armeabi-v7a
android.allow_backup = True
