# After Fall 副本与据点图鉴

无构建依赖的静态网页。数据来自当前聊天中的静态脚本分析，以及工作区《大型副本与据点静态复核》。不连接 Roblox，不操作 Studio。

- `dist/data.js`：32 项结构化资料；统一生成总览、详情和文档。
- `dist/app.js`：分类、全文搜索、区域／状态筛选、分页、详情路由与下载。
- 导出 PDF：总览表旁一键生成单页 PDF，纸张尺寸随表格内容而定，含全部条目（不受筛选与分页影响），在浏览器端完成。
- `dist/docs/`：总览 CSV／Markdown、逐项详解、JSON 和原始复核清单。
- `generate-docs.cjs`：从同一数据源更新文档，避免表格与详情错位。
- `check.cjs`：数据完整性、关系引用、静态文件与脚本语法检查。
- `serve.mjs`：本地静态预览，默认端口 4178。

运行 `node generate-docs.cjs` 更新文档，`node check.cjs` 检查，`node serve.mjs` 预览。也可直接打开 `dist/index.html`，核心浏览无需网络。
