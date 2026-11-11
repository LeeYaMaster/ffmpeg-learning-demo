# 课时 10：字幕——烧录与软字幕

跑这个课时：

```bash
./lessons/10-subtitles/run.sh
```

输出会写到 `output/10-subtitles/`。

示例字幕是生成素材时写好的 `samples/demo.srt`（UTF-8），含几句中文，时间轴覆盖整段 8 秒片子。

## 两种完全不同的做法

**软字幕（mux / 封装）**：把 `.srt` 作为一条独立的字幕流放进容器。播放器可以开关、选语言，画面像素没有被改过，也无需重新编码视频。

```bash
# MKV 对 SRT 最友好
ffmpeg -y -i in.mp4 -i demo.srt -map 0 -map 1 -c copy -c:s srt out.mkv

# MP4 通常要转成 mov_text，部分播放器 / 浏览器不一定显示
ffmpeg -y -i in.mp4 -i demo.srt -map 0 -map 1 -c copy -c:s mov_text out.mp4
```

**烧录（burn-in）**：用 `subtitles`（或 `ass`）滤镜把文字画进每一帧。任何播放器都能看到，但无法再关掉，而且必须重编码视频。

```bash
ffmpeg -y -i in.mp4 -vf "subtitles=demo.srt" -c:a copy out.mp4
```

路径里若有冒号或特殊字符，需要像 `drawtext` 的 `fontfile` 一样转义。本课脚本会自动处理。

## 如何选择

| 需求 | 推荐 |
|------|------|
| 给自己看、希望能开关 | 软字幕，优先 MKV |
| 发到只认画面的平台、或目标设备不支持软字幕 | 烧录 |
| 要做双语、多条音轨的成片 | 软字幕 + 多条 `-map` |
| 已经进入剪辑后期、需要花字动画 | 用 ASS/SSA 样式，再烧录或交给播放器渲染 |

## 中文字体

`subtitles` 滤镜通过 libass + fontconfig 找字体。macOS 上 Homebrew 的 FFmpeg 一般能用到系统里的苹方 / 黑体；Linux 上需要 Noto CJK 或文泉驿一类字体。若只看到方框，不是 srt 坏了，而是当前环境找不到中文字体。

本课在烧录时如果检测了 CJK 字体，会通过 `force_style` / `fontsdir` 尽量指过去；找不到也不会让整课失败。

## 建议你自己再试

- 用 `ffprobe output/10-subtitles/soft_subs.mkv` 确认存在 `subtitle` 流。
- 若本机有 `ffplay`：`ffplay output/10-subtitles/soft_subs.mkv` 应能看到可渲染的字幕；`burned_in.mp4` 的字是画在画面上的。
