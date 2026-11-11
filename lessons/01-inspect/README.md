# 课时 01：用 ffprobe 查看媒体信息

跑这个课时：

```bash
./lessons/01-inspect/run.sh
```

输出会写到 `output/01-inspect/`。

## 这一课学什么

拿到一个文件，先别急着转码。用 `ffprobe` 看清楚：

- 封装格式（format / container，例如 `mov,mp4,m4a,3gp,3g2,mj2`）
- 有哪些流（视频、音频、字幕），各自的编码
- 时长、码率、分辨率、帧率、采样率、声道数
- 更细的帧信息（关键帧位置、时间戳）

`ffprobe` 只读文件，不会改它。输出既可以是人类可读的文本，也可以是方便脚本处理的 JSON。

## 和 ffmpeg / ffplay 的分工

| 工具 | 作用 |
|------|------|
| `ffprobe` | 查看、测量、以结构化格式导出信息 |
| `ffmpeg` | 转码、剪辑、滤镜、封装 |
| `ffplay` | 快速预览（不保存文件） |

## 命令要点

查看容器与流的概要（默认就会打印）：

```bash
ffprobe -hide_banner samples/sample_h264_aac.mp4
```

只取需要的字段，避免被一大段日志淹没：

```bash
ffprobe -hide_banner -v error \
  -show_entries format=format_name,duration,size,bit_rate \
  -show_entries stream=index,codec_type,codec_name,width,height,r_frame_rate,sample_rate,channels \
  -of default=noprint_wrappers=1 \
  samples/sample_h264_aac.mp4
```

JSON 适合给脚本用（本课会把结果存成文件）：

```bash
ffprobe -v error -print_format json -show_format -show_streams \
  samples/sample_h264_aac.mp4
```

看前几帧的类型（`I` 是关键帧，`P`/`B` 是预测帧）。这对后面理解「剪切为什么要放在关键帧上」很重要：

```bash
ffprobe -v error -select_streams v:0 -read_intervals "%+#12" \
  -show_entries frame=key_frame,pts_time,pict_type \
  -of csv=print_section=0 \
  samples/sample_h264_aac.mp4
```

## 建议你自己再试

- 把 `sample_h264_aac.mp4` 换成 `sample_bars.mp4` 或 `tone_440.wav`，对比纯音频和音视频文件的流数量。
- 有 GUI 播放器时，也可以 `ffplay samples/sample_h264_aac.mp4` 看画面和听声音。
