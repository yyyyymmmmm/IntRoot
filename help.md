# 项目环境配置指南

## 目录
- [1. 环境要求](#1-环境要求)
- [2. Flutter 环境配置](#2-flutter-环境配置)
- [3. Android 开发环境配置](#3-android-开发环境配置)
- [4. 环境变量配置](#4-环境变量配置)
- [5. 运行项目](#5-运行项目)
- [6. 项目特定配置](#6-项目特定配置)
- [7. 开发工具配置](#7-开发工具配置)
- [8. 故障排除指南](#8-故障排除指南)
- [9. 性能优化](#9-性能优化)
- [10. 发布指南](#10-发布指南)

## 1. 环境要求

### 系统要求
- Windows 10 64位 或更高版本
- 至少 8GB RAM (推荐 16GB)
- 至少 20GB 可用磁盘空间
- 1280x800 或更高分辨率显示器
- 支持虚拟化技术的 CPU（用于 Android 模拟器）

### Flutter 环境要求
- Flutter SDK: 3.32.5（固定版本）
- Dart SDK: 3.8.1（随Flutter SDK附带）
- Flutter 通道: stable
- Flutter 版本控制: git

### Android 环境要求
- Android Studio: 2023.1.1 或更高版本
- Android SDK: API 33 或更高版本
- Android NDK: 27.0.12077973（必须是此版本）
- Gradle: 8.0.0
- Kotlin: 1.9.0
- Java: JDK 11

### 开发工具
- VS Code + Flutter 插件
- Android Studio + Flutter 插件
- Git 2.x 或更高版本

## 2. Flutter 环境配置

1. 下载 Flutter SDK
   - 访问 [Flutter 官网](https://flutter.dev/docs/get-started/install/windows)
   - 下载最新的稳定版 Flutter SDK
   - 将下载的 zip 文件解压到不含空格或特殊字符的路径（推荐：`D:\Flutter\flutter`）
   
   ![Flutter下载页面](assets/images/flutter-download.png)

2. 配置 Flutter 环境变量
   - 打开系统环境变量设置（Win + R 输入 sysdm.cpl）
   - 在"系统变量"中，编辑 Path 变量
   - 添加 Flutter SDK 的 bin 目录路径：`D:\Flutter\flutter\bin`
   
   ![环境变量设置](assets/images/env-vars.png)

3. 验证 Flutter 安装
   ```powershell
   flutter --version
   ```
   预期输出：
   ```
   Flutter 3.32.5 • channel stable • https://github.com/flutter/flutter.git
   Framework • revision fcf2c11572 (4 weeks ago) • 2025-06-24 11:44:07 -0700
   Engine • revision dd93de6fb1
   Tools • Dart 3.8.1 • DevTools 2.45.1
   ```

### Flutter 版本管理
1. 切换 Flutter 版本：
   ```powershell
   flutter version 3.32.5
   ```

2. 验证 Flutter 配置：
   ```powershell
   flutter --version
   ```
   预期输出：
   ```
   Flutter 3.32.5 • channel stable • https://github.com/flutter/flutter.git
   Framework • revision fcf2c11572 (4 weeks ago) • 2025-06-24 11:44:07 -0700
   Engine • revision dd93de6fb1
   Tools • Dart 3.8.1 • DevTools 2.45.1
   ```

3. 检查 Flutter 环境：
   ```powershell
   flutter doctor -v
   ```

### Dart SDK 配置
- Dart SDK 路径：`[Flutter安装目录]/bin/cache/dart-sdk`
- Dart 版本：3.8.1
- Dart 开发工具：DevTools 2.45.1

## 3. Android 开发环境配置

1. 安装 Android Studio
   - 从[官网](https://developer.android.com/studio)下载最新版 Android Studio
   - 运行安装程序，按默认选项安装
   - 确保安装位置路径不包含中文字符
   
   ![Android Studio 安装](assets/images/as-install.png)

2. 配置 Android SDK
   - 打开 Android Studio
   - 进入 Settings > Appearance & Behavior > System Settings > Android SDK
   - 在 "SDK Platforms" 标签页安装：
     * Android API 33 (Android 13.0)
     * Android API 34 (Android 14.0)
   
   - 在 "SDK Tools" 标签页安装以下组件（必需）：
     * Android SDK Build-Tools 34.0.0
     * Android SDK Command-line Tools (latest)
     * Android SDK Platform-Tools 34.0.5
     * Android Emulator 32.1.15
     * Android NDK 27.0.12077973（必须是此版本）

   - 推荐安装的额外组件：
     * Google USB Driver（Windows 系统必需）
     * Intel x86 Emulator Accelerator (HAXM installer)
     * Layout Inspector image server for API 33+
     * Device Manager

3. SDK 版本对照表

   | 组件名称 | 所需版本 | 说明 |
   |---------|---------|------|
   | Android SDK Platform | API 33+ | 最低支持 Android 13.0 |
   | Android SDK Build-Tools | 34.0.0 | 用于构建 Android 应用 |
   | Android SDK Platform-Tools | 34.0.5 | adb 和其他工具 |
   | Android SDK Tools | Latest | 基础开发工具 |
   | Android NDK | 27.0.12077973 | 原生开发工具包，版本必须匹配 |
   | CMake | 3.22.1 | 用于原生代码构建 |

4. SDK 路径配置
   ```
   Android SDK 位置：
   - Windows: D:\AndroidSdk
   - macOS: ~/Library/Android/sdk
   - Linux: ~/Android/Sdk

   必需的子目录结构：
   AndroidSdk/
   ├── build-tools/34.0.0/
   ├── cmdline-tools/latest/
   ├── emulator/
   ├── ndk/27.0.12077973/
   ├── platform-tools/
   ├── platforms/android-33/
   └── platforms/android-34/
   ```

5. Gradle 配置
   - Gradle 版本：8.0.0
   - Android Gradle Plugin 版本：8.1.0
   - 项目级 build.gradle.kts：
     ```kotlin
     buildscript {
         ext {
             buildToolsVersion = "34.0.0"
             minSdkVersion = 21
             compileSdkVersion = 34
             targetSdkVersion = 34
             ndkVersion = "27.0.12077973"
         }
     }
     ```

6. 模拟器系统镜像
   推荐使用以下系统镜像之一：
   - x86_64 镜像（Intel/AMD CPU）：
     * API 33: Google APIs Intel x86_64 Atom System Image
     * API 34: Google Play Intel x86_64 Atom System Image
   
   - ARM64 镜像（Apple Silicon）：
     * API 33: Google APIs ARM 64 v8a System Image
     * API 34: Google Play ARM 64 v8a System Image

7. 创建和配置模拟器
   - 在 Android Studio 中打开 Device Manager
   - 点击 "Create Device"
   - 选择设备配置：
     * 设备：Pixel 6 Pro（推荐）
     * 屏幕：1440 x 3120 (560dpi)
     * 内存：4GB RAM
     * 内部存储：512MB
   
   - 系统镜像选择：
     * x86_64 设备：API 33 Google Play Intel x86_64
     * ARM设备：API 33 Google Play ARM 64 v8a
   
   - 高级设置：
     * 启用 "Cold Boot" - 每次完全重启模拟器
     * Graphics：Hardware - GLES 2.0
     * Multi-Core CPU (2-4)
     * 启用 "Enable Device Frame" - 显示设备外观
     * 启用 "Enable GPU Acceleration"

## 4. 环境变量配置

### 系统环境变量
- Path 变量：
  - `D:\Flutter\flutter\bin`
  - `D:\AndroidSdk\platform-tools`
  - `D:\AndroidSdk\build-tools\34.0.0`
  - `D:\AndroidSdk\cmdline-tools\latest`
  - `D:\AndroidSdk\ndk\27.0.12077973`
  - `D:\AndroidSdk\platforms\android-33`
  - `D:\AndroidSdk\platforms\android-34`

### 用户环境变量
- `FLUTTER_HOME`: `D:\Flutter\flutter`
- `ANDROID_HOME`: `D:\AndroidSdk`
- `JAVA_HOME`: `C:\Program Files\Java\jdk-11`

## 5. 运行项目

1. 启动 Flutter 应用
   ```powershell
   flutter run
   ```

2. 启动 Android 模拟器
   ```powershell
   emulator -avd Pixel_6_Pro
   ```

## 6. 项目特定配置

### Flutter 配置
1. pubspec.yaml 配置：
   ```yaml
   environment:
     sdk: '>=3.0.5 <4.0.0'
     flutter: ">=3.0.0"

   dependencies:
     flutter:
       sdk: flutter
     # 核心依赖
     provider: ^6.0.5
     sqflite: ^2.3.0
     path: ^1.8.3
     intl: ^0.18.1
     
     # 路由导航
     go_router: ^10.0.0
     
     # 存储相关
     shared_preferences: ^2.2.0
     flutter_secure_storage: ^8.0.0
     
     # UI组件
     flutter_markdown: ^0.6.17
     flutter_slidable: ^3.0.0
     flutter_heatmap_calendar: ^1.0.5
     
     # 网络和功能
     url_launcher: ^6.3.2
     http: ^1.1.0

   dev_dependencies:
     flutter_test:
       sdk: flutter
     flutter_lints: ^2.0.0
   ```

2. Flutter 配置文件：
   ```
   # .metadata
   version:
     revision: fcf2c11572
     channel: stable

   project_type: app
   migration:
     platforms:
       android:
         default_package: flutter
   ```

### Android 配置
在 `android/app/build.gradle.kts` 中确保以下配置：
   ```kotlin
   android {
       namespace = "com.example.mo_ming_notes"
       compileSdk = 34  // 必须使用 API 34
       
       defaultConfig {
           applicationId = "com.example.mo_ming_notes"
           minSdk = 21
           targetSdk = 34
           versionCode = 1
           versionName = "1.0"
       }

       buildTypes {
           release {
               isMinifyEnabled = true
               proguardFiles(getDefaultProguardFile("proguard-android.txt"), "proguard-rules.pro")
           }
       }

       compileOptions {
           sourceCompatibility = JavaVersion.VERSION_11
           targetCompatibility = JavaVersion.VERSION_11
       }

       ndkVersion = "27.0.12077973"  // 必须使用此版本
   }
   ```

### 版本兼容性说明

1. Flutter SDK 版本限制
   - 最低版本：3.0.5
   - 当前版本：3.32.5
   - 最高版本：4.0.0（不含）

2. Dart SDK 版本限制
   - 最低版本：2.12.0
   - 当前版本：3.8.1
   - 最高版本：4.0.0（不含）

3. 依赖版本说明
   | 依赖包 | 版本 | 说明 |
   |-------|------|------|
   | provider | ^6.0.5 | 状态管理 |
   | sqflite | ^2.3.0 | 数据库 |
   | go_router | ^10.0.0 | 路由导航 |
   | flutter_secure_storage | ^8.0.0 | 安全存储 |
   | flutter_markdown | ^0.6.17 | Markdown渲染 |

4. 版本升级注意事项
   - 不要升级到 Flutter 4.0.0 及以上版本
   - provider 包保持在 6.x 版本
   - 数据库相关包版本需要同步更新

## 7. 开发工具配置

### VS Code 配置
- 安装 Flutter 插件
- 安装 Dart 插件
- 安装 Git 插件
- 安装 Kotlin 插件
- 安装 Gradle 插件

### Android Studio 配置
- 安装 Flutter 插件
- 安装 Kotlin 插件
- 安装 Gradle 插件
- 安装 NDK 插件

## 8. 故障排除指南

### Flutter 版本相关问题

1. Flutter 版本不匹配
   ```
   Flutter SDK version 3.32.5 requires Dart SDK version >=3.8.1 <4.0.0
   ```
   解决方案：
   ```powershell
   flutter version 3.32.5
   flutter pub get
   ```

2. 依赖版本冲突
   ```
   Because mo_ming_notes depends on flutter_secure_storage >=8.0.0 which requires SDK version >=2.12.0 <4.0.0...
   ```
   解决方案：
   - 检查 pubspec.yaml 中的版本约束
   - 运行 `flutter pub outdated` 查看可更新的包
   - 按需更新依赖版本

### SDK 相关错误

1. compileSdkVersion 错误
   ```
   Error: The Android Gradle plugin supports only Kotlin Gradle plugin version 1.9.0 and higher.
   ```
   解决方案：
   - 在 `android/build.gradle` 中更新 Kotlin 版本：
     ```gradle
     ext.kotlin_version = '1.9.0'
     ```

2. NDK 版本不匹配
   ```
   Execution failed for task ':app:stripDebugDebugSymbols'.
   No toolchains found in the NDK toolchains folder for ABI: 'arm64-v8a'
   ```
   解决方案：
   - 确保使用正确的 NDK 版本 27.0.12077973
   - 删除其他版本的 NDK
   - 重新下载 NDK：
     ```powershell
     sdkmanager --install "ndk;27.0.12077973"
     ```

3. Gradle 同步失败
   ```
   Could not find method android() for arguments
   ```
   解决方案：
   - 确保 Gradle 版本兼容：
     ```gradle
     distributionUrl=https\://services.gradle.org/distributions/gradle-8.0-all.zip
     ```
   - 清理 Gradle 缓存：
     ```powershell
     cd android
     ./gradlew clean
     ```

### 项目特定错误

1. 数据库迁移错误
   ```
   DatabaseException: no such table: notes
   ```
   解决方案：
   - 删除旧数据库文件
   - 重新运行应用
   - 如需保留数据，执行迁移脚本：
     ```dart
     await db.execute(
       'CREATE TABLE IF NOT EXISTS notes(id INTEGER PRIMARY KEY, title TEXT, content TEXT)',
     );
     ```

2. 路由错误
   ```
   Could not find a generator for route RouteSettings
   ```
   解决方案：
   - 检查 `go_router` 配置
   - 确保所有路由都已正确注册
   - 验证路由参数类型

## 9. 性能优化

### 开发环境优化
1. Android Studio 性能设置
   - 增加 IDE 内存：
     ```
     # studio64.exe.vmoptions
     -Xmx4096m
     -XX:MaxPermSize=1024m
     ```
   - 禁用不必要的插件
   - 启用 Power Save Mode 进行大型重构

2. Gradle 构建优化
   ```gradle
   android {
       dexOptions {
           javaMaxHeapSize "4g"
           preDexLibraries true
       }
       
       buildTypes {
           debug {
               minifyEnabled false
               shrinkResources false
           }
       }
   }
   ```

### 应用性能优化
1. 图片资源优化
   - 使用适当的图片格式
   - 实现图片缓存
   - 根据设备分辨率加载不同尺寸

2. 数据库优化
   - 使用索引
   - 批量操作
   - 异步加载

## 10. 发布指南

### 版本号管理
1. 在 pubspec.yaml 中更新版本号：
   ```yaml
   version: 1.0.0+1  # 格式：主版本.次版本.修订号+构建号
   ```

2. 在 android/app/build.gradle 中同步版本号：
   ```gradle
   defaultConfig {
       versionCode 1
       versionName "1.0.0"
   }
   ```

### 发布检查清单
1. 应用配置
   - 更新版本号
   - 检查应用ID
   - 验证权限声明

2. 性能测试
   - 运行性能测试
   - 检查内存使用
   - 验证启动时间

3. 安全检查
   - 移除调试代码
   - 检查敏感信息
   - 验证数据加密

### 签名配置
在 `android/app/build.gradle` 中配置签名：
```gradle
android {
    signingConfigs {
        release {
            storeFile file("keystore.jks")
            storePassword "******"
            keyAlias "key0"
            keyPassword "******"
        }
    }
}
``` 