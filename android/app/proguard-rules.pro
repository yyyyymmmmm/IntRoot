# Flutter 相关规则
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.editing.** { *; }

# Kotlin 相关规则
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}

# 保留 Parcelable 实现类
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# 保留 Serializable 实现类
-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    !private <fields>;
    !private <methods>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# 图片选择器相关规则
-keep class com.luck.picture.lib.** { *; }

# OkHttp 相关规则
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**
-keepnames class okhttp3.internal.publicsuffix.PublicSuffixDatabase

# SQLite 相关规则
-keep class org.sqlite.** { *; }
-keep class org.sqlite.database.** { *; }

# 保留 native 方法
-keepclasseswithmembernames class * {
    native <methods>;
}

# 保留枚举类
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# 保留 R 文件中的属性
-keepclassmembers class **.R$* {
    public static <fields>;
}

# 避免混淆泛型
-keepattributes Signature

# 保留注解
-keepattributes *Annotation*

# 保留 JavaScript 接口
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# 移除日志
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
} 