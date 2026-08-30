# Debug Session: android-export-grey  [RESOLVED — APK exported & signed 2026-08-17]

**Symptom:** "导出项目" / "全部导出" 按钮灰色。Godot 4.7.1 + Windows 10/11。

**Direct visual evidence (user screenshot):**
- 5 条红色错误：缺 Java SDK、缺 platform-tools（adb）、缺 build-tools（apksigner）
- 导出模板管理器显示 **Android + iOS 模板已装**（含 android_debug.apk / android_release.apk / android_source.zip）

**Real-world evidence (filesystem):**
- `java` / `javac` / `adb` / `apksigner` 全部 command not found
- 10+ 个常见 JDK/Android SDK 路径全部 MISS
- 无 Android Studio 残留
- `editor_settings-4.7.tres` 中 `java_sdk_path = ""`、`android_sdk_path` 指向不存在的目录
- 空间：C 27 GB、D 14.5 GB，足够

**Attempted fix #1 (已撤回):** 把 `export_path` / `version/name` / `package/unique_name` / `package/name` 填上。**结果：按钮仍灰**。
**Attempted fix #2 (已撤回):** 把 `custom_template/debug` / `release` 改成 `res://android/...`。**结果：路径不存在，恶化**。
**Attempted fix #3:** 回退 custom_template 为空。**结果：待用户验证。**

**Likely root cause (advisor confirmed):**
Godot 4.7 在 `use_gradle_build=false` 模式下，**仍需要在 Editor Settings 里填入合法的 Java SDK 路径和 Android SDK 路径**。它会去验证 SDK 里的 `build-tools/.../apksigner.exe`、`platform-tools/adb.exe` 是否存在。即便用预编译模板也需要这条链完整。用户的"不装也能导出"判断**不对应 Godot 4.7**——可能是从更早版本的经验推断。

**Resolution path (待用户授权时执行):**
1. 装 JDK 17 zip → D:\jdk17
2. 装 Android commandline tools + sdkmanager 拉 platform-tools / build-tools / platforms;android-34 → D:\Android\Sdk
3. 改 `editor_settings-4.7.tres`：
   - `export/android/java_sdk_path = "D:/jdk17"`
   - `export/android/android_sdk_path = "D:/Android/Sdk"`
4. 重启 Godot，打开 Project → Export，按钮即应可点

**Estimated time:** 15-30 分钟（主要在下载）。

**Status:** RESOLVED 2026-08-17 21:57。JDK 17 (D:\jdk17\jdk-17.0.20+8) + Android SDK (D:\Android\Sdk, platform-tools/build-tools;34.0.0/platforms;android-34) 已装,editor_settings-4.7.tres 已指向。headless 导出 kalimba.apk (27.7MB) 成功,因 debug_keystore 缺失导出时未自动签名 → 用 keytool 生成 D:\Android\debug.keystore + apksigner sign (v1+v2) 后 verify 通过。

