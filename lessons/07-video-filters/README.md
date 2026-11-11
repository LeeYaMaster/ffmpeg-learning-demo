# 课时 07：视频滤镜与 filtergraph

跑这个课时：

```bash
./lessons/07-video-filters/run.sh
```

输出会写到 `output/07-video-filters/`。

## 这一课学什么

滤镜是 FFmpeg 最有表现力的部分。本课覆盖：

- 单输入、单输出的简单链：`-vf`（等价于 `-filter:v`）
- 多输入或需要命名标签时：`-filter_complex`
- 具体效果：水印（`overlay`）、文字（`drawtext`）、淡入淡出（`fade`）、水平翻转（`hflip`）、旋转（`rotate` / `transpose`）、亮度和色相（`eq` / `hue`）

## `-vf` 与 `-filter_complex`

一条简单链，用逗号连接，按从左到右的顺序执行：

```bash
ffmpeg -y -i in.mp4 -vf "hflip,eq=brightness=0.06:contrast=1.1" -c:a copy out.mp4
```

一旦有**两个输入**（例如视频 + 水印图），或需要把中间结果分成多路，就要用 `-filter_complex`，并为缓冲区命名：

```bash
ffmpeg -y -i in.mp4 -i logo.png \
  -filter_complex "[0:v][1:v]overlay=W-w-10:10[outv]" \
  -map "[outv]" -map 0:a -c:a copy out.mp4
```

`[0:v]` 是第 0 路输入的视频，`[1:v]` 是水印图。`W`/`H` 是主画面宽高，`w`/`h` 是叠加层宽高，所以 `W-w-10:10` 表示距右上角各 10 像素。

## 常用滤镜片段

```bash
# 右上角水印
overlay=W-w-10:10

# 烧录文字（必须指定 fontfile，路径中的冒号、反斜杠要转义）
drawtext=fontfile=/path/to/font.ttf:text='Hello':fontcolor=white:fontsize=36:x=20:y=20

# 开头 1 秒淡入，第 7 秒起淡出 1 秒（源片约 8 秒）
fade=t=in:st=0:d=1,fade=t=out:st=7:d=1

# 水平翻转
hflip

# 任意角度旋转（单位是弧度；背景默认黑）
rotate=PI/8

# 90° 旋转请优先用 transpose，它会正确交换宽高
transpose=1

# 亮度和色相
eq=brightness=0.08:contrast=1.15:saturation=1.2
hue=h=30:s=1.2
```

## 字体

`drawtext` 需要一个字体文件。脚本会按下面顺序自动寻找：

- macOS：PingFang、STHeiti、Arial Unicode 等
- Linux：Noto Sans/Serif CJK、文泉驿、DejaVu

如果只找到拉丁字体，中文可能显示为方框，脚本会给出警告而不会整课失败。你也可以自己指定：

```bash
export DEMO_FONT="/System/Library/Fonts/PingFang.ttc"
```

（本课脚本以自动检测为准；若要强制某款字体，可改 `run.sh` 里的 `DEMO_FONT`。）

## 建议你自己再试

- 把 `overlay=W-w-10:10` 改成 `overlay=10:H-h-10`，水印会跑到左下角。
- 给 `rotate` 加上 `c=none` 或先 `pad`，观察旋转后四角如何被裁切。
