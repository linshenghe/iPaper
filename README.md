# iPaper

iPaper 是一个本地优先的 macOS 论文进度管理 App，用来管理论文状态、审稿任务、工作计时和时间日志。

当前版本是原生 macOS App。旧网页版只保留为原型参考和旧数据导入来源。

## 数据与隐私

- 运行时数据保存在本机：`~/Library/Application Support/PaperTracker/data.json`
- 数据格式是本地 JSON，不需要服务器或数据库
- API key 保存在 macOS Keychain，不写入 JSON 或仓库
- AI Assist 只生成可确认的字段建议，不会自动保存到数据文件
- 使用 AI Assist 时，你粘贴到输入框里的文本会发送到你配置的 AI API endpoint

建议在正式使用前先通过 Settings 做一次备份。

## 安装与启动

当前仓库还没有发布签名安装包。开发/试用方式：

1. 用 Xcode 打开 `PaperTracker.xcodeproj`
2. 选择 `PaperTracker` scheme
3. 运行 App

发布版打包、签名和 notarization 仍待补齐。

## 主界面

App 使用双栏布局：

- 左侧是导航：All Papers、Writing、Submitted、R&R、Accepted / Published、Reviews、Sessions、Today
- 右侧是当前列表和操作区
- 左下角显示保存状态、计时状态和 AI 配置状态

默认进入 All Papers。

## 管理论文

在 Papers 页面可以：

- 点击 `+ New Paper` 新建论文
- 填写标题、期刊、状态、截止日期和备注
- 编辑已有论文
- 删除论文
- 搜索标题或期刊
- 按 Writing、Submitted、R&R、Accepted、Published 筛选

论文状态包括：

- Writing
- Submitted
- R&R
- Accepted
- Published

Today 视图会显示今天截止或正在计时的论文。

## 计时与日志

每篇论文行内都有计时入口。

- 开始一篇论文的计时后，其他正在运行的论文会自动停止
- 停止计时时，App 会累计论文总时长
- 停止计时时，App 会自动生成一条 Session 日志
- 重新打开 App 时，会恢复并结算仍在运行的计时

Sessions 页面可以查看时间线，并编辑或删除日志备注。

## 管理审稿

Reviews 页面用于记录审稿任务。

可以维护：

- 期刊名称
- 截止日期
- 状态：In Progress 或 Completed
- 备注

## 备份、恢复与导入导出

在 Settings 的 Data 区域可以：

- 备份当前数据为 JSON
- 从备份 JSON 恢复数据
- 从旧版 iPaper 网页版 JSON 导入数据
- 导出 CSV 文件

CSV 导出会生成三个文件：

- `papers.csv`
- `reviews.csv`
- `sessions.csv`

恢复备份会覆盖当前数据。执行前请确认备份文件正确。

## AI Assist

AI Assist 用来从摘要、邮件或备注中提取论文字段建议。

使用步骤：

1. 打开 Settings
2. 填写 AI Base URL
3. 填写模型名
4. 保存 API key
5. 点击 `Test Connection` 检查连接
6. 回到 Papers 页面，点击 `AI Assist`
7. 粘贴文本并生成建议
8. 选择要应用的字段
9. 点击 `Apply Selected & Close`
10. 在新建论文表单中确认并保存

默认 Base URL 是 `https://api.openai.com/v1`。也可以填写兼容 OpenAI API 的服务地址。

## 故障处理

如果保存、导入、导出、备份恢复、Keychain 或 AI 请求失败，App 会在界面中显示错误信息。

如果数据文件损坏，App 会提示读取失败，并保留原文件，避免自动覆盖。

## 开发者信息

主要源码目录：

- `PaperTracker/`：App 源码
- `PaperTrackerTests/`：单元测试
- `PaperTrackerUITests/`：UI 测试
- `prototypes/web/`：旧网页版原型和示例数据

运行测试：

```bash
xcodebuild test -project PaperTracker.xcodeproj -scheme PaperTracker -destination 'platform=macOS'
```

项目使用 MIT License。
