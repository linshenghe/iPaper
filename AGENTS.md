# iPaper — Project Context

原生 macOS App 项目，网页版只保留为原型参考。

## Architecture

- 主实现：`PaperTracker/` 下的 SwiftUI macOS App
- 单元测试：`PaperTrackerTests/`
- UI 测试：`PaperTrackerUITests/`
- 运行时权威数据：`~/Library/Application Support/PaperTracker/data.json`
- 持久化：本地 JSON 文件，后续由 App 独占管理
- AI 能力：App 内配置 API key，Keychain 存储，AI 只给建议不直接落盘

## Repository Layout

- `PaperTracker/` — App 源码
- `PaperTrackerTests/` — 单元测试
- `PaperTrackerUITests/` — UI 测试
- `docs/architecture/` — 架构、迁移、技术说明
- `docs/archive/` — 历史网页方案、旧文档归档
- `docs/superpowers/plans/` — 当前实现计划
- `docs/working/` — 暂未归档但需要提交的工作文档
- `fixtures/` — 样例/夹具数据
- `prototypes/web/` — 旧网页原型与示例数据

## What I Edit

- App 代码优先改 `PaperTracker/`
- 测试优先改 `PaperTrackerTests/` 和 `PaperTrackerUITests/`
- 新方案、执行计划、结构说明优先改 `docs/`
- 旧网页原型只在需要参考或迁移时读取；除非用户明确要求，否则不再把它当主实现继续迭代

## Output Placement Rules

- 新源码放 `PaperTracker/`
- 新测试放 `PaperTrackerTests/` 或 `PaperTrackerUITests/`
- 新架构文档放 `docs/architecture/`
- 新执行计划放 `docs/superpowers/plans/`
- 尚未归档的一般工作文档放 `docs/working/`
- 样例 JSON、测试输入输出、导入样本放 `fixtures/`
- 没有明确分类时：文档放 `docs/working/`，数据放 `fixtures/`
- 不要把新的业务文件直接放到项目根目录

## Important Design Decisions

- 首版只做 macOS，本地使用，不考虑跨平台
- 不引入数据库；先用 JSON 持久化
- 不依赖第三方 Swift 包，优先系统框架
- API key 不能写入仓库或 JSON，统一放 Keychain
- 所有文件读写、导入导出、AI 请求失败都必须显式提示

## User Preferences

- Reply in Chinese
- Local use only
- No deployment to personal domain
- macOS only

## Boundary

- Claude Code 专用上下文和本地私有配置不进入公开仓库；如需读取只读检查，避免改动。
