#include <jni.h>
#include <android/log.h>
#include <dlfcn.h>

#define LOG_TAG "FdsanWorkaround"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGW(...) __android_log_print(ANDROID_LOG_WARN, LOG_TAG, __VA_ARGS__)

// Android fdsan error levels
enum android_fdsan_error_level {
    ANDROID_FDSAN_ERROR_LEVEL_DISABLED = 0,
    ANDROID_FDSAN_ERROR_LEVEL_WARN_ONCE = 1,
    ANDROID_FDSAN_ERROR_LEVEL_WARN_ALWAYS = 2,
    ANDROID_FDSAN_ERROR_LEVEL_FATAL = 3,
};

typedef enum android_fdsan_error_level (*fdsan_set_error_level_func)(enum android_fdsan_error_level);

JNIEXPORT void JNICALL
Java_com_mahsanet_proxy_1core_ProxyCoreApplication_disableFdsanNative(JNIEnv *env, jobject thiz) {
    // Try to load the fdsan function from libc
    void *libc = dlopen("libc.so", RTLD_NOW);
    if (!libc) {
        LOGW("Failed to dlopen libc.so");
        return;
    }

    fdsan_set_error_level_func set_error_level =
        (fdsan_set_error_level_func)dlsym(libc, "android_fdsan_set_error_level");

    if (!set_error_level) {
        LOGW("android_fdsan_set_error_level not found (Android version < 10?)");
        dlclose(libc);
        return;
    }

    // Set fdsan to WARN_ONCE mode (will log but not crash)
    enum android_fdsan_error_level old_level = set_error_level(ANDROID_FDSAN_ERROR_LEVEL_WARN_ONCE);
    LOGI("fdsan error level changed from %d to WARN_ONCE", old_level);

    dlclose(libc);
}
