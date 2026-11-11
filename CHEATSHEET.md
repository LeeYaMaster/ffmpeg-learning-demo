# FFmpeg 速查与常见错误

配合本项目各课时使用。命令中的路径请换成你自己的文件。更完整的解释见对应课时的 `README.md`。

## 工具分工

```bash
ffmpeg  -version          # 转码、剪辑、滤镜、封装
ffprobe -version          # 查看媒体信息
ffplay  file.mp4          # 快速预览（不写文件）
```

## 查看信息

```bash
ffprobe -hide_banner in.mp4
ffprobe -v error -print_format json -show_format -show_streams in.mp4
ffprobe -v error -select_streams v:0 -show_entries stream=codec_name,width,height,r_frame_rate -of default=nw=1 in.mp4
```

## 转码与拷贝

```bash
# 通用 MP4（H.264 + AAC）
ffmpeg -y -i in.mp4 -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p -c:a aac -b:a 128k out.mp4

# 只换容器，不重新压缩（要确认目标容器支持当前编码）
ffmpeg -y -i in.mp4 -c copy out.mkv

# 只要视频 / 只要音频
ffmpeg -y -i in.mp4 -map 0:v:0 -c:v copy -an video.mp4
ffmpeg -y -i in.mp4 -map 0:a:0 -c:a copy -vn audio.m4a
```

## 剪切与拼接

```bash
# 快：输入跳转 + copy（切点受关键帧限制）
ffmpeg -y -ss 00:00:10 -i in.mp4 -t 5 -c copy -avoid_negative_ts make_zero clip.mp4

# 准：输出跳转 + 重编码
ffmpeg -y -i in.mp4 -ss 00:00:10 -t 5 -c:v libx264 -c:a aac clip.mp4

# concat demuxer（各段参数需一致）
# list.txt 每行：file '/path/to/clip.mp4'
ffmpeg -y -f concat -safe 0 -i list.txt -c copy joined.mp4
```

## 画面

```bash
# 缩放（-2 保证偶数高，适配 yuv420p）
ffmpeg -y -i in.mp4 -vf "scale=1280:-2" -c:a copy out.mp4

# 按比例放入固定画幅并补黑边
ffmpeg -y -i in.mp4 -vf "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2" -c:a copy out.mp4

# 中心裁剪、改帧率
ffmpeg -y -i in.mp4 -vf "crop=1280:720,fps=30" -c:a copy out.mp4

# 水印
ffmpeg -y -i in.mp4 -i logo.png -filter_complex "[0:v][1:v]overlay=W-w-10:10" -c:a copy out.mp4
```

## 音频

```bash
ffmpeg -y -i in.wav -af "volume=-6dB" out.wav
ffmpeg -y -i in.mp4 -af "loudnorm=I=-16:TP=-1.5:LRA=11" -c:v copy out.mp4
ffmpeg -y -i a.wav -i b.wav -filter_complex "amix=inputs=2:duration=shortest" mixed.wav
ffmpeg -y -i video.mp4 -i new.wav -map 0:v -map 1:a -c:v copy -c:a aac -shortest out.mp4
ffmpeg -y -i in.wav -ar 16000 -ac 1 speech.wav
```

## 字幕、封面、GIF

```bash
# 软字幕（优先 MKV）
ffmpeg -y -i in.mp4 -i dialog.srt -map 0 -map 1 -c copy -c:s srt out.mkv

# 烧录
ffmpeg -y -i in.mp4 -vf "subtitles=dialog.srt" -c:a copy burned.mp4

# 封面
ffmpeg -y -ss 3 -i in.mp4 -frames:v 1 thumb.jpg

# 高质量 GIF
ffmpeg -y -i in.mp4 -vf "fps=10,scale=480:-2:flags=lanczos,palettegen" pal.png
ffmpeg -y -i in.mp4 -i pal.png -lavfi "fps=10,scale=480:-2:flags=lanczos[x];[x][1:v]paletteuse" out.gif
```

## 画质与速度

```bash
# CRF：数字越小质量越高。18–28 是常用区间，默认 23
ffmpeg -y -i in.mp4 -c:v libx264 -crf 20 -preset slow -c:a aac out.mp4

# 两遍，按目标码率
ffmpeg -y -i in.mp4 -c:v libx264 -b:v 2M -pass 1 -an -f null /dev/null
ffmpeg -y -i in.mp4 -c:v libx264 -b:v 2M -pass 2 -c:a aac out.mp4

# macOS 可选硬件编码（先用 ffmpeg -encoders | grep videotoolbox 确认）
ffmpeg -y -i in.mp4 -c:v h264_videotoolbox -b:v 4M -c:a aac out.mp4
```

---

## 常见错误

1. **选项写错位置。** `-ss`、`-f`、`-itsoffset` 写在 `-i` 前作用于输入，写在后面作用于输出。看到「切得不准」或「格式探测失败」时，先检查选项落在哪一侧。

2. **把 `-c copy` 和滤镜一起用。** 滤镜要解开像素再处理，必须重编码视频（或音频）。正确示例：`-vf scale=1280:-2 -c:v libx264 -c:a copy`。

3. **yuv420p 用了奇数宽高。** 报错类似 `width not divisible by 2`。用 `scale=1280:-2` 或 `scale=-2:720`，不要用 `-1`。

4. **H.264 拷贝进 WebM，或把不兼容的编码塞进 MP4。** 换容器前先用 ffprobe 看编码。WebM 用 VP8/VP9/AV1 + Vorbis/Opus；MP4 常用 H.264/H.265 + AAC。

5. **`-c copy` 剪切出现片头黑屏或卡住。** 切点没落在关键帧上。要精确画面就重编码；要快就接受关键帧对齐，或先把源片用较小的 GOP 重编一次。

6. **`anullsrc` / `lavfi` 命令停不下来。** 虚拟源可以无限长，记得加 `-shortest` 或 `-t`。

7. **覆盖已有文件时卡住或直接放弃。** 交互模式下 FFmpeg 会询问。脚本里请加 `-y`（覆盖）或 `-n`（不覆盖）。

8. **多路输入时音画对错了。** 默认 map 只挑「最好的」各一路。明确写 `-map 0:v:0 -map 1:a:0`，并用 `-shortest` 避免长音轨把短视频拖长。

9. **drawtext / 字幕中文变成方框。** 不是 srt 编码错了（请用 UTF-8），而是找不到中文字体。指定 `fontfile` 或安装苹方 / Noto Sans CJK。

10. **时间戳错乱、第二段拼接后不同步。** concat demuxer 要求各段参数一致；不一致就改用 concat 滤镜重编码。copy 剪切后可尝试 `-avoid_negative_ts make_zero`。

11. **`-t` 和 `-to` 搞混。** `-t` 是持续时长，`-to` 是结束时间点。两者再和 `-ss` 组合时，时间原点取决于 `-ss` 在 `-i` 前还是后。

12. **Apple 硬件编码器没有 CRF。** `h264_videotoolbox` 请用 `-b:v` 或 `-q:v`。探测不到编码器时退回 `libx264`，不要把它当成必需步骤。

13. **输出 MP4 在线播放要等全部下载完才能看。** 加上 `-movflags +faststart`，把 moov atom 挪到文件头部。

14. **忘了 `-pix_fmt yuv420p`，结果 QuickTime 播不了。** x264 有时会选择 `yuv444p` 之类兼容性较差的格式。面向普通播放器时显式写出 `yuv420p`。
