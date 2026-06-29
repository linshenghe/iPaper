# iPaper

iPaper 是一个本地优先的 macOS 论文进度管理 App。当前仓库主线已经从早期单文件网页工具转为原生 App 开发；旧网页版本只保留为原型、迁移样本和交互参考。

## 当前方向

- 产品形态：原生 macOS App
- 技术路线：`SwiftUI + AppKit + JSON + Keychain`
- 运行时权威数据：`~/Library/Application Support/PaperTracker/data.json`
- 持久化方式：本地 JSON 文件，首版不引入数据库
- AI 能力：App 内配置 API key，Keychain 存储；AI 只生成建议，不直接落盘
- 网页原型：只作为参考，不再作为主实现继续迭代

## GitHub

当前远端仓库：

- `linshenghe/iPaper`
- <https://github.com/linshenghe/iPaper>
- 公开仓库，默认分支 `main`

远端仓库已经改名为 `iPaper`；本地目录不需要跟着改。

## 开源说明

iPaper 使用 MIT License 开源。仓库只保留适合公开的源码、文档、样例数据和历史网页原型；不提交真实运行时数据、API key、token、cookie、私钥或本地凭证。

Claude Code 专用上下文、会话交接记录、真实 `data.json` 和机器本地输出不进入公开仓库。

## 阶段开发规则

实现计划按 Phase 推进。每个 Phase 使用独立分支、独立提交、独立 draft PR：

1. 从最新 `main` 创建阶段分支，例如 `codex/phase-0-foundation`。
2. 完成本阶段代码和文档。
3. 跑本阶段最小相关验证。
4. 检查 diff，确认没有密钥、本地噪音或无关格式化。
5. 提交本阶段变更。
6. push 阶段分支。
7. 创建 draft PR。
8. PR review/merge 后，再从更新后的 `main` 开始下一阶段。

默认不直接 push 到 `main`，不 force-push，不重写历史。

## 目录结构

```text
tool-paper-tracker/
├── AGENTS.md
├── LICENSE
├── README.md
├── PaperTracker/                  # App 源码
├── PaperTrackerTests/             # 单元测试
├── PaperTrackerUITests/           # UI 测试
├── docs/
│   ├── architecture/              # 架构与迁移文档
│   ├── archive/                   # 历史方案与归档文档
│   ├── superpowers/plans/         # 当前实现计划
│   └── working/                   # 暂未归档的工作文档
├── fixtures/                      # 样例/夹具数据
└── prototypes/
    └── web/                       # 历史网页原型
```

## 重要文件

- App 实施方案：[docs/superpowers/plans/2026-06-29-papertracker-macos-app-implementation.md](docs/superpowers/plans/2026-06-29-papertracker-macos-app-implementation.md)
- 迁移工作流归档：[docs/architecture/MACOS_WORKFLOW.md](docs/architecture/MACOS_WORKFLOW.md)
- 网页原型：[prototypes/web/tracker.html](prototypes/web/tracker.html)
- 网页原型示例数据：[prototypes/web/data.json](prototypes/web/data.json)

## 当前状态

- 仓库结构已整理为 App 开发形态
- 7 个 Phase 全部完成，27 个测试全通过
- Papers / Reviews / Sessions / Settings / AI Assist 功能完整
- 网页原型已归档至 `prototypes/web/`，可作为旧数据导入样本
