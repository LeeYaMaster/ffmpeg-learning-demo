# 课时 04：提取流与更换容器

跑这个课时：

```bash
./lessons/04-extract/run.sh
```

输出会写到 `output/04-extract/`。

## 这一课学什么

很多日常需求其实只是「拿出其中一条流」或「换个盒子装着」，不必重新压缩：

- 只要视频（发成无声片段、交给只认画面的工具）
- 只要音频（做播客、提取原声）
- 把 MP4 换成 MKV（或反过来），编码保持不变

能用 `-c copy` 就用，省时间且不损失质量。只有目标容器不接受当前编码，或你需要改采样率、声道、分辨率时，才转码。

## 命令要点

视频 only，拷贝视频流、丢掉音频：

```bash
ffmpeg -y -i in.mp4 -map 0:v:0 -c:v copy -an out.mp4
```

音频 only，编码已是 AAC 时可以直接拷贝进 `.m4a`：

```bash
ffmpeg -y -i in.mp4 -map 0:a:0 -c:a copy -vn out.m4a
```

若目标是 MP3，AAC 不能直接 copy 进 MP3 容器，需要转码：

```bash
ffmpeg -y -i in.mp4 -map 0:a:0 -vn -c:a libmp3lame -q:a 2 out.mp3
```

更换容器、两条流都拷贝：

```bash
ffmpeg -y -i in.mp4 -c copy out.mkv
```

## 小提示

- `-vn` / `-an` / `-sn` 分别表示输出不要视频 / 音频 / 字幕。和 `-map` 一起用时，请保持语义一致，避免「map 了又丢掉」。
- 抽出的「裸 AAC」有时用 `.aac` 后缀；更常见的做法是放进 `.m4a`（其实是 MP4 的音频用途）。
- 想确认有没有重新编码：看命令日志里是 `Stream mapping` 后的 `Video: h264 ... (copy)` 还是出现了 `libx264`。本课脚本用 `-loglevel error` 比较安静，可用 ffprobe 对比 `codec_name` 和文件体积来验证。

## 建议你自己再试

- 对 `video_only.mp4` 跑 `ffprobe`，确认没有 audio 流。
- 把 `audio_copy.m4a` 用 `ffplay` 听一下，应该和原片音轨一样。
