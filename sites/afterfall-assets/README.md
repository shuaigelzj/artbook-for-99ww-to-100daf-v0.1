# After Fall 局内资产档案

无构建依赖的静态查询网站。`dist/index.html` 可直接在浏览器打开，也可用 `node serve.mjs` 在本地预览。

- `dist/catalog-data.js`：905 条分类记录与 20 份 Markdown 分类文档的索引。
- `dist/catalog-core.js`：搜索、筛选、证据状态与分页逻辑。
- `dist/app.js`：目录、文档下载和详情交互。
- `dist/docs/`：按程序用途和素材类型拆分的 Markdown。
- `dist/previews/`：按编号持续追加 Studio 图示；已完成批次由 preview-batches.json 和 preview-manifest.json 汇总。支持批次切换及补充视角，列表行内配图与箭头详情同时保留。
- `prepare-previews.mjs`：校验所有已完成批次的截图及 Studio 清理结果，复制图片并生成预览清单；随后运行 `generate-content.mjs` 同步资产详情及列表行内配图。旧命令 `prepare-preview50.mjs` 转调此入口，保留后续批次。

在原工作区执行 `node generate-content.mjs` 可根据 `output/局内素材分类_取证/catalog_classified_v2.json` 更新数据与 Markdown。该脚本同时更新工作区的分类文件索引。发布包只包含静态网站与这些分类型文档，不包含 Studio 原模型或原始脚本源码。
