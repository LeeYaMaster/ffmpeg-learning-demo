# 课时 02：生成测试媒体，理解输入 / 输出基本规则

跑这个课时：

```bash
./lessons/02-basics/run.sh
```

输出会写到 `output/02-basics/`。

## 这一课学什么

FFmpeg 的命令可以看成一条流水线：

```
ffmpeg [全局选项] [输入选项] -i 输入1 [输入选项] -i 输入2 [输出选项] 输出文件
```

关键点：

- **选项的位置决定它作用在谁身上。** `-i` 前面的选项（如 `-ss`、`-f`、`-t`）作用于**该路输入**；`-i` 之后、输出文件名之前的选项作用于**输出**。
- `-i` 不一定是磁盘上的文件。`lavfi`（libavfilter 虚拟输入）可以现场生成测试画面和声音，本项目的示例素材就是这样来的。
- `-y` 表示输出文件已存在时直接覆盖；`-n` 则相反，遇到同名文件就放弃。脚本里一般加 `-y`，方便反复练习。
- `-map` 明确指定「要哪些流」。不加 `-map` 时，FFmpeg 会按默认规则挑一路「最好的」视频和一路音频，多数时候够用，但多路输入时务必自己 map。

## 命令要点

从 lavfi 生成 3 秒彩条 + 静音（`anullsrc`）：

```bash
ffmpeg -y \
  -f lavfi -i "smptebars=size=640x360:rate=25:duration=3" \
  -f lavfi -i "anullsrc=r=44100:cl=stereo" \
  -shortest \
  -c:v libx264 -pix_fmt yuv420p -c:a aac \
  output/02-basics/from_lavfi.mp4
```

`-shortest` 的意思是：以较短的那路输入结束时间为准。`anullsrc` 默认可以无限长，不加 `-shortest` 或 `-t` 命令就不会停。

显式映射「第 0 路输入的视频 + 第 1 路输入的音频」：

```bash
ffmpeg -y -i video.mp4 -i audio.wav -map 0:v:0 -map 1:a:0 -c:v copy -c:a aac -shortest out.mp4
```

`0:v:0` 读作：第 0 个输入、视频、第 0 条。`1:a:0` 是第 1 个输入的第 0 条音频。

只保留视频、丢掉音频：

```bash
ffmpeg -y -i in.mp4 -map 0:v:0 -an -c:v copy out.mp4
```

`-an` 表示输出不含音频，等价于不 map 任何音频流。

## 建议你自己再试

- 故意去掉上面 `anullsrc` 例子里的 `-shortest`，观察命令是否一直不退出（用 Ctrl+C 中断即可）。
- 把 `-y` 改成 `-n`，再跑一次同一条命令，看 FFmpeg 如何拒绝覆盖。注意：有的版本此时退出码仍是 0，请看提示里的 `already exists`。
