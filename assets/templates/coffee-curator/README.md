# 复用策展助手

导入 `.moonbook-agent` 后，在新 MoonBook 执行（替换路径）：

```text
moon run --target-dir /tmp/coffee-curator-activate-cache /path/to/book/skills/coffee-curator/activate.mbtx /path/to/book
```

显式指定外部构建目录，避免将编译缓存放进技能目录后再次打包。
该命令合并 `coffee_curator` profile，保留其他任务；同名配置有分歧时停止，供人工核对。
它不启动模型、发布活动或创建定时任务。

在以这本书为 cwd 的 MoonClaw gateway 中发送：

```text
/plan-job 为半醒咖啡准备下一期主题和三条提示词，引用品牌原稿
```

核对计划后，按 MoonClaw 的正常任务流程运行。草案写入 `wiki/planning/` 或
`wiki/reviews/`，保留原始资料引用、待核实事项和 `requires_review:true`。

资料、技能和策展配置跟随书复用。服务密钥、集群凭据、生产账户和活动私有投稿不随书导出。
原始策展书保留全部 37 个输入文件；可移植包携带预览、视频、杯型、logo、背景和说明，
导入后的路径是 `portable/outputs/coffee-curation-materials/`，不是来源书的 `raw/curation/`。
实际移植文件与 SHA256 以 `portable/outputs.manifest.v1.json` 为准。
首期配置模板在 `references/event-week01.json`；实际部署、验收与恢复顺序在
`references/COMFYUI_RUNBOOK.md`。模板中的图片服务默认关闭，避免未验收时错误开放生成。
