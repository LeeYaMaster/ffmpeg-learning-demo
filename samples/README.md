# samples/

本目录的音视频素材由 `scripts/generate-samples.sh` 用 FFmpeg 的 lavfi 测试源现场生成，不包含任何受版权保护的媒体。

运行：

```bash
./scripts/generate-samples.sh
```

生成后会看到类似这些文件：

| 文件 | 说明 |
|------|------|
| `sample_h264_aac.mp4` | 主示例：约 8 秒，1280×720、30fps，H.264 + AAC |
| `sample_bars.mp4` | 彩条测试图，约 4 秒，带音频 |
| `clip_a.mp4` / `clip_b.mp4` | 各约 2 秒，编码参数一致，供拼接课使用 |
| `tone_440.wav` / `tone_660.wav` | 纯音频正弦波，供混音课使用 |
| `logo.png` | 半透明水印图 |
| `demo.srt` | 演示用 UTF-8 字幕 |

这些二进制文件已被 `.gitignore` 忽略，请不要提交进仓库。
