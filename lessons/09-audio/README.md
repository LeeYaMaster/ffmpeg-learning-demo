# 课时 09：音频处理

跑这个课时：

```bash
./lessons/09-audio/run.sh
```

输出会写到 `output/09-audio/`。

## 这一课学什么

- 调整音量（简单的 `volume`，以及按 EBU R128 的 `loudnorm`）
- 把两路声音混在一起（`amix`）
- 静音、替换原片音轨
- 音频淡入淡出（`afade`）
- 改采样率和声道数

音频滤镜用 `-af`（单条链）或在 `-filter_complex` 里处理多路输入，和视频的 `-vf` / `-filter_complex` 是同一套思路。

## 命令要点

音量加倍（+6 dB 左右）或写成分贝：

```bash
ffmpeg -y -i tone_440.wav -af "volume=2.0" louder.wav
ffmpeg -y -i tone_440.wav -af "volume=-6dB" quieter.wav
```

`loudnorm` 按广播常用的响度标准归一化。单遍模式够用来学习；追求精确可以做两遍（先测再应用，本课用单遍，避免把日志搞复杂）：

```bash
ffmpeg -y -i in.mp4 -af "loudnorm=I=-16:TP=-1.5:LRA=11" -c:v copy out.mp4
```

混合两路正弦波：

```bash
ffmpeg -y -i tone_440.wav -i tone_660.wav \
  -filter_complex "amix=inputs=2:duration=shortest:normalize=0" mixed.wav
```

`normalize=0` 表示不要自动压低以防削波（两个等幅正弦相加会明显变响，正好用来听效果）。若担心削波，可改成默认的 normalize，或混完再 `alimiter` / `volume`。

替换视频的音轨（视频 copy，音频重编码，按较短的一路截断）：

```bash
ffmpeg -y -i video.mp4 -i tone_660.wav \
  -map 0:v:0 -map 1:a:0 -c:v copy -c:a aac -shortest out.mp4
```

只去掉声音：

```bash
ffmpeg -y -i video.mp4 -c:v copy -an muted.mp4
```

开头 1 秒淡入、结尾 1 秒淡出（6 秒素材）：

```bash
ffmpeg -y -i tone_440.wav -af "afade=t=in:st=0:d=1,afade=t=out:st=5:d=1" fade.wav
```

改采样率与声道：

```bash
# 48 kHz 立体声 → 16 kHz 单声道（语音常用）
ffmpeg -y -i tone_440.wav -ar 16000 -ac 1 voice_like.wav
```

`-ar` 是采样率，`-ac` 是声道数。也可以写成滤镜 `aresample=16000,aformat=channel_layouts=mono`。

## 建议你自己再试

- 用 `ffplay output/09-audio/mixed.wav` 听 440Hz 与 660Hz 叠在一起的效果（能听到拍频和更亮的音色）。
- 对比 `muted.mp4` 和 `replaced_audio.mp4`：一个完全没声，一个换成了 660Hz。
