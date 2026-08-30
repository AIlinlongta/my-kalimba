# MyKalimba · 拇指琴教学应用

一款用 **Godot 4.7** 开发的拇指琴（卡林巴）教学 / 弹奏应用。提供多音色弹奏、内置曲库与「下落式」乐谱练习模式，手机横屏优先，可导出 Android 与桌面端。

## 功能特性

- **多音色弹奏**：内置 4 种音色可切换 —— 卡林巴0 / 卡林巴1 / 钢琴0 / 小号（吉他音色采样已备）
- **真实拇指琴手感**：琴键按雁形长度排列、交叉映射，贴合实体拇指琴布局
- **下落式练习模式**：MIDI 乐谱以音符下落 + 判定线的方式指引演奏，学会一首歌循序渐进
- **演示模式**：可先听完整演奏，再进练习
- **可调速度**：练习/演示支持 150% / 125% / 100% / 75% / 50% / 25% 六档倍率，由慢到快逐步提速
- **内置曲库**：打包多首中文 MIDI 曲目（小星星、欢乐颂、千与千寻、大鱼海棠 等）
- **自定义乐谱**：乐谱存放于用户目录，可自行放入 MIDI 文件扩充曲库
- **移动端优化**：横屏布局、多点触控、GL Compatibility 渲染保证低端机流畅

## 技术栈

| 项 | 说明 |
|---|---|
| 引擎 | Godot 4.7 |
| 渲染 | GL Compatibility（兼容移动 / 桌面） |
| 语言 | GDScript |
| 物理 | Jolt Physics |
| 目标平台 | Android、Windows / Linux / macOS 桌面 |

## 运行与构建

1. 安装 [Godot 4.7](https://godotengine.org/)（标准版即可）
2. 用 Godot 打开本项目根目录（`project.godot`）
3. `F5` 运行预览；或按 `export_presets.cfg` 配置导出 Android APK / AAB 或桌面版本

> 协作者建议使用相同 Godot 版本与导出设置，`.godot/` 编辑器缓存不纳入版本管理（见 `.gitignore`）。

## 目录结构

```
my-kalimba/
├── project.godot          # Godot 工程配置（横屏、GL Compatibility）
├── export_presets.cfg     # Android / 桌面导出预设
├── kalimba.gd             # 主逻辑：琴键布局、音色、练习/演示模式
├── midi_parser.gd         # MIDI 解析
├── midi_adapter.gd        # MIDI 适配（音高映射）
├── midi_writer.gd         # MIDI 写入
├── audio/                 # 音色采样（kalimba / kalimba1 / piano / trumpet / guitar）
├── midi_hub/              # 内置乐谱 MIDI 曲库
├── docs/                  # 发布与评测指南等文档
└── gitee/                 # Gitee 相关文档副本
```

## 自定义乐谱

应用首次运行会把内置曲库拷贝到用户可写目录 `user://midi`。将自己想要练习的 **MIDI 文件**放入该目录即可扩充曲库（Godot 导出为 Android 时，用户目录在 `Android/data/<包名>/files/midi`）。

## 反馈与协作

- 使用问题 / 建议：欢迎在仓库 **Issues** 中反馈
- 评测反馈模板与发布、协作流程见 [docs/发布与评测指南.md](docs/发布与评测指南.md)
