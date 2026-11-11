# FFmpeg 动手学习 Demo

这是一份面向程序员的 **命令行 FFmpeg 教程项目**。读说明、生成测试素材、按课时跑脚本，每一课都会打印即将执行的命令，并把结果写到 `output/`，再用 `ffprobe` 或 `ffplay` 查看。

所有示例视频和音频都由 FFmpeg 的 **lavfi 测试源**（`testsrc2`、`smptebars`、`sine` 等）现场生成，不含任何受版权保护的媒体。

文档、脚本注释和终端提示均为简体中文。

## 1. 安装 FFmpeg（macOS）

推荐用 [Homebrew](https://brew.sh)：

```bash
brew install ffmpeg
```

装好后确认三个工具都在 PATH 里：

```bash
ffmpeg  -version
ffprobe -version
ffplay  -version
```

三条都应该打印出版本号（例如 `ffmpeg version 7.x ...`）。若 `command not found`：

- 确认 `brew --prefix ffmpeg` 有输出，并把 `$(brew --prefix)/bin` 加进 PATH。
- Apple Silicon 上 Homebrew 默认在 `/opt/homebrew/bin`，Intel 上多为 `/usr/local/bin`。必要时把对应目录写入 `~/.zprofile`。

Linux 用户可用发行版包装（本项目脚本在缺失时也会提示）：

```bash
# Debian / Ubuntu
sudo apt update && sudo apt install -y ffmpeg
```

> 部分精简构建可能缺少 `libx264`、`libvpx`、`libass` 或 `ffplay`。本项目课时在可选编码器缺失时会跳过并说明，不会把整课判失败。Homebrew 的官方 `ffmpeg` 公式通常组件齐全，建议优先使用。

## 2. 三个命令分别做什么

| 命令 | 作用 | 什么时候用 |
|------|------|------------|
| **ffmpeg** | 转码、剪切、拼接、滤镜、提取、封装 | 要「产出一个新文件」时 |
| **ffprobe** | 只读地查看容器、码流、时长、帧信息，可输出 JSON | 先摸清文件再动手，或写脚本解析 |
| **ffplay** | 用简单窗口立即播放 | 本地预览；不产生输出文件。无图形界面时可以不装 |

一份典型工作流：`ffprobe` 看清楚 → `ffmpeg` 处理 → `ffplay`（或系统播放器）检查结果。

## 3. 生成示例素材

在项目根目录执行（可重复运行，会覆盖旧文件）：

```bash
./scripts/generate-samples.sh
```

素材会写到 `samples/`（该目录的二进制文件已被 git 忽略）。主要文件：

- `sample_h264_aac.mp4` — 主示例，约 8 秒，1280×720、30fps，H.264 + AAC，画面为带时间码的 testsrc2
- `sample_bars.mp4` — SMPTE 彩条
- `clip_a.mp4` / `clip_b.mp4` — 参数一致的 2 秒短片，供拼接课使用
- `tone_440.wav` / `tone_660.wav` — 纯音频正弦波
- `logo.png` — 半透明水印
- `demo.srt` — UTF-8 演示字幕

若提示找不到 `ffmpeg`，请先完成第 1 节的安装。

## 4. 推荐学习顺序

请按编号走，后面的课会用到前面建立的直觉（尤其是「选项位置」「copy 与重编码」「关键帧与时间戳」）。

| 顺序 | 目录 | 内容 |
|------|------|------|
| 01 | `lessons/01-inspect` | 用 ffprobe 查看格式、码流、时长、JSON、关键帧 |
| 02 | `lessons/02-basics` | `-i`、`-y`、`-map`、lavfi 虚拟输入 |
| 03 | `lessons/03-transcode` | 转码 MP4 / WebM / 音频；`-c copy` 与陷阱 |
| 04 | `lessons/04-extract` | 提取视频/音频，更换容器 |
| 05 | `lessons/05-cut-concat` | `-ss` 前后位置、精度与速度、拼接与时间戳 |
| 06 | `lessons/06-scale-crop` | 缩放、裁剪、补边、帧率；yuv420p 偶数尺寸 |
| 07 | `lessons/07-video-filters` | 水印、文字、淡入淡出、翻转、旋转、eq/hue |
| 08 | `lessons/08-thumbnails-gif` | 封面、逐秒截图、palettegen 高质量 GIF |
| 09 | `lessons/09-audio` | 音量、loudnorm、混音、替换音轨、采样率 |
| 10 | `lessons/10-subtitles` | 软字幕封装 vs 烧录 |
| 11 | `lessons/11-quality` | CRF、preset、两遍编码、可选 VideoToolbox |

全部跑完后，浏览根目录的 [`CHEATSHEET.md`](CHEATSHEET.md)，里面是可复制的命令碎片和一份「常见错误」清单。

每一课都有短说明：`lessons/0N-.../README.md`。

## 5. 如何跑第一课，输出在哪里

```bash
# 若还没生成素材，先跑上一步
./scripts/generate-samples.sh

# 第一课
./lessons/01-inspect/run.sh
```

脚本会：

1. 检查本机是否有 `ffmpeg` / `ffprobe`，没有就打印安装提示并退出
2. 说明这一步要做什么
3. 打印即将执行的**完整命令**（方便你复制改造）
4. 把结果写到 `output/01-inspect/`（例如 `probe.json`）

之后每一课都是同样的用法：

```bash
./lessons/02-basics/run.sh
# ...
./lessons/11-quality/run.sh
```

对应输出在 `output/<课时目录名>/`。这些文件也被 git 忽略，随时可以删掉重跑。

想一次跑完全部课时：

```bash
./run-all.sh
```

也可以使用 `make samples` / `make lessons` / `make all` / `make clean`（需要系统已安装 `make`；macOS 上通常随 Xcode Command Line Tools 提供）。不装 `make` 也完全没问题，用上面的 shell 脚本即可。

预览某个结果（需有图形界面）：

```bash
ffplay output/07-video-filters/watermark.mp4
```

也可以直接用系统播放器打开该文件。没有画面时，用 `ffprobe` 看编码和时长就足够验证。

## 6. 项目结构

```
ffmpeg-learning-demo/
  README.md                  # 本文件，从这里开始
  CHEATSHEET.md              # 命令速查与常见错误
  run-all.sh                 # 生成素材并按顺序跑完所有课时
  Makefile                   # 可选：make samples / lessons / clean
  scripts/
    common.sh                # 公共检测、字体查找、打印命令
    generate-samples.sh      # 用 lavfi 生成 samples/
  samples/                   # 生成的示例素材（二进制已忽略）
  lessons/
    01-inspect/              # 每课一个目录：run.sh + README.md
    ...
    11-quality/
  output/                    # 课时输出（已忽略）
```

## 7. 字体与中文绘制

`drawtext` 和水印文字需要一个字体文件。脚本会自动在常见位置查找：

- macOS：苹方、华文黑体、Arial Unicode 等
- Linux：Noto Sans/Serif CJK、文泉驿、DejaVu

若只找到拉丁字体，中文可能显示为方框，**相关步骤会警告但不会让整课失败**。软字幕本身是 UTF-8 文本，用支持中文的播放器渲染即可。

## 8. Apple Silicon 与硬件加速

在 Apple Silicon 或较新的 Intel Mac 上，Homebrew 的 FFmpeg 一般带有 `h264_videotoolbox`。这是**可选项**，见课时 11：脚本会先探测，没有该编码器（例如在 Linux 上）就跳过，不视为失败。硬件编码通常用 `-b:v` 控制码率，并没有和 `libx264` 完全对等的 CRF。

## 许可与范围

本项目用于学习命令行 FFmpeg，不是生产工具，也不包装 FFmpeg 的 C API。你可以随意修改脚本做实验。生成的测试媒体无版权负担，请不要把大型媒体文件提交进 git。
