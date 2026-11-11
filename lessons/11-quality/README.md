# 课时 11：画质、速度与（可选）硬件加速

跑这个课时：

```bash
./lessons/11-quality/run.sh
```

输出会写到 `output/11-quality/`。

## 这一课学什么

同样是 H.264，参数选得不同，体积、画质和耗时可以差出好几倍。本课用同一段 8 秒源片实际压几份，方便你对比：

- **CRF**（恒定质量）：最常用的「按观感控制画质」方式
- **preset**：同样 CRF 下，更慢的预设压得更小
- **目标码率 / 两遍编码**：需要「大概固定体积」时再用
- **能 copy 就 copy**：不改画面和声音时，不要重编码
- **VideoToolbox**（仅 macOS，可选）：`h264_videotoolbox`，没有该编码器时脚本会跳过，不会失败

## CRF 怎么选

`libx264` 的 CRF 范围是 0–51，**数字越小画质越好、文件越大**。默认 23。经验范围：

| CRF | 观感（大致） |
|-----|----------------|
| 18  | 接近视觉无损，体积明显变大 |
| 23  | 默认，多数情况够用 |
| 28  | 能看出压缩痕迹，文件更小 |

```bash
ffmpeg -y -i in.mp4 -c:v libx264 -crf 18 -preset medium -c:a aac out.mp4
```

CRF 和 `-b:v` 不要混着当「两套同时生效的目标」来理解：指定了 CRF，就让编码器自己决定码率。

## preset 怎么选

从快到慢大致是：

`ultrafast` / `superfast` / `veryfast` / `faster` / `fast` / `medium`（默认） / `slow` / `slower` / `veryslow`

同样的 CRF，越慢通常体积越小、编码越久。日常导出用 `medium` 或 `slow`；实时预览或本课演示用 `veryfast` / `ultrafast` 就够。

## 目标码率与两遍编码

若有明确的体积预算（例如「这段要控制在 2 Mbps」），用码率模式：

```bash
# 单遍 ABR，简单但码率分配一般
ffmpeg -y -i in.mp4 -c:v libx264 -b:v 1M -preset medium -c:a aac out.mp4

# 两遍：第一遍只统计，第二遍按统计结果分配码率，通常更稳
ffmpeg -y -i in.mp4 -c:v libx264 -b:v 1M -pass 1 -an -passlogfile /tmp/ffpass -f null /dev/null
ffmpeg -y -i in.mp4 -c:v libx264 -b:v 1M -pass 2 -passlogfile /tmp/ffpass -c:a aac out.mp4
```

第一遍必须用 `-f null` 丢掉画面输出，并且一般加 `-an`（音频不用参与分析）。日志文件由 `-passlogfile` 指定前缀，请写到输出目录，避免污染项目根目录。

## 能拷贝就不要重编码

剪切点对准关键帧、只换容器、只换音轨、只去掉字幕……这些都可以 `-c copy` 或 `-c:v copy`。每重编码一次，就多一次世代损失。

## 可选：macOS VideoToolbox

Apple Silicon 和较新的 Intel Mac 都提供 VideoToolbox 硬件编码。Homebrew 安装的 FFmpeg 通常带有 `h264_videotoolbox`（以及 `hevc_videotoolbox`）。

```bash
# 硬件编码一般按码率控制，没有和 libx264 对等的 CRF
ffmpeg -y -i in.mp4 -c:v h264_videotoolbox -b:v 2M -c:a aac out.mp4
```

注意：

- **这是可选项。** 脚本会先探测编码器，没有就打印说明并跳过，退出码仍为 0。Linux 上必然会被跳过。
- 硬件编码更快、更省电，同样码率下画质通常略逊于精心调过的 `libx264`。
- 部分选项（心理视觉、部分 profile）和软件编码器不完全兼容，遇到报错就退回 `libx264`。
- 若探测不到编码器：确认 `ffmpeg -encoders | grep videotoolbox`，以及你用的是官方/Homebrew 构建，而不是精简版。

## 建议你自己再试

- 对比 `crf18.mp4` 与 `crf28.mp4` 的文件大小，再用播放器放大查看色块边缘。
- 在 Mac 上看脚本是否打印了 VideoToolbox 成功信息；若没有，检查 `ffmpeg -encoders`。
