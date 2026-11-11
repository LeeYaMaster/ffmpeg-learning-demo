# 课时 08：缩略图、逐秒截图与高质量 GIF

跑这个课时：

```bash
./lessons/08-thumbnails-gif/run.sh
```

输出会写到 `output/08-thumbnails-gif/`。

## 这一课学什么

- 抽出一帧作为封面 / 缩略图
- 按固定间隔连续截图
- 用 `palettegen` + `paletteuse` 做高质量 GIF（比直接 `-c:v gif` 或随意指定调色板好看得多）

## 命令要点

从第 3 秒取一帧：

```bash
ffmpeg -y -ss 3 -i in.mp4 -frames:v 1 thumb.jpg
```

`-ss` 放在 `-i` 前面时定位很快。如果必须精确到某一帧，把 `-ss` 放到 `-i` 后面（见课时 05）。

每秒一张图，并缩到宽 320（高度自动取偶数）：

```bash
ffmpeg -y -i in.mp4 -vf "fps=1,scale=320:-2" thumbs/img_%03d.png
```

`%03d` 表示 3 位补零序号：`img_001.png`、`img_002.png`……源片 8 秒大约会得到 8 张图。

## 高质量 GIF：先生成调色板，再按调色板抖动

GIF 最多 256 色。如果让编码器「随便选颜色」，渐变和测试图案会有明显色带。正确流程是：

```bash
# 第一遍：根据画面统计出一张 256 色调色板
ffmpeg -y -i in.mp4 -vf "fps=8,scale=320:-2:flags=lanczos,palettegen" palette.png

# 第二遍：用这张调色板把每一帧映射到 256 色
ffmpeg -y -i in.mp4 -i palette.png \
  -lavfi "fps=8,scale=320:-2:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer" \
  out.gif
```

也可以在一条 `filter_complex` 里用 `split` 一次完成，本课脚本两种都会示范。`lanczos` 是质量较好的缩放算法，做小尺寸 GIF 时值得加上。

直接输出 GIF、不用调色板（对比用，画质通常更差）：

```bash
ffmpeg -y -i in.mp4 -vf "fps=8,scale=320:-2" -c:v gif naive.gif
```

## 建议你自己再试

- 用文件管理器看 `thumbs/` 目录，会按时间顺序排好。
- 对比 `naive.gif` 和 `palette.gif` 的体积与色带（testsrc2 的色块很能说明问题）。
