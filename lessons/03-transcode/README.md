# 课时 03：转码与格式转换

跑这个课时：

```bash
./lessons/03-transcode/run.sh
```

输出会写到 `output/03-transcode/`。

## 这一课学什么

「换个后缀」其实可能是两件完全不同的事：

1. **转码（transcode）**：解开压缩 → 重新用另一种编码器压一遍。画质、体积、兼容性都会变，也更耗时。
2. **重封装 / 流拷贝（remux / `-c copy`）**：不碰压缩数据，只换容器（例如 MP4 → MKV）。几乎瞬间完成，画质不变。

常见目标组合：

| 目标 | 视频 | 音频 | 说明 |
|------|------|------|------|
| 通用 MP4 | H.264（`libx264`） | AAC | 兼容性最好 |
| WebM | VP9（`libvpx-vp9`）或 VP8 | Opus / Vorbis | 浏览器友好；本课若编码器不存在会跳过 |
| 仅音频 MP3 | — | `libmp3lame` | 手机、播放器都很常见 |
| 仅音频 AAC / M4A | — | `aac` | 常用于从视频抽出音轨后再封装 |
| WAV | — | PCM | 无损、体积大，适合再加工 |

## 命令要点

重新编码为 H.264 + AAC 的 MP4：

```bash
ffmpeg -y -i in.mp4 -c:v libx264 -preset medium -crf 23 -pix_fmt yuv420p -c:a aac -b:a 128k out.mp4
```

只换容器、不重新编码：

```bash
ffmpeg -y -i in.mp4 -c copy out.mkv
```

抽出音频并转成 MP3 / AAC / WAV：

```bash
ffmpeg -y -i in.mp4 -vn -c:a libmp3lame -q:a 2 out.mp3
ffmpeg -y -i in.mp4 -vn -c:a aac -b:a 128k out.m4a
ffmpeg -y -i in.mp4 -vn -c:a pcm_s16le out.wav
```

## `-c copy` 的常见陷阱

- **不能同时使用视频滤镜。** `-vf scale=...` 和 `-c:v copy` 互相矛盾，FFmpeg 会报错或忽略你的预期。
- **剪切点往往落在关键帧上。** 用 `-c copy` 剪切时，如果 `-ss` 没有对准 I 帧，片头可能出现黑屏、冻结或时间戳怪异。精确剪切请重新编码，或先把 `-ss` 放到关键帧上。
- **不是所有编码都能装进任意容器。** 例如 H.264 + AAC 可以进 MP4 / MKV，但不能可靠地塞进 WebM（WebM 通常要 VP8/VP9/AV1 + Vorbis/Opus）。本课会演示「拷贝到 WebM 失败、转码则成功」。
- **时间基、multiple 流、字幕** 有时也需要重封装选项（如 `-map`、`-movflags +faststart`），「只改后缀」并不是万能的。

## 建议你自己再试

- 对比 `copy_to_mkv.mkv` 和源文件的体积、时长，几乎应当一致。
- 对比 `to_webm.webm` 与源文件的体积和画质（WebM/VP9 默认会压得比较狠）。
