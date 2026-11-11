# 可选入口。直接运行 ./run-all.sh 或各课时的 run.sh 也可以。
.PHONY: all samples lessons clean help

all: samples lessons

help:
	@echo "make samples   # 生成 samples/ 下的测试素材"
	@echo "make lessons   # 先确保素材存在，再按顺序跑完全部课时"
	@echo "make all       # 以上两步都做（默认）"
	@echo "make clean     # 删除生成的素材和课时输出（保留 .gitkeep）"

samples:
	./scripts/generate-samples.sh

lessons: samples
	./run-all.sh --skip-samples

clean:
	# 只删除生成物，保留目录占位和说明
	find samples -type f ! -name '.gitkeep' ! -name 'README.md' -exec rm -f {} +
	find output -mindepth 1 -maxdepth 1 ! -name '.gitkeep' -exec rm -rf {} +
