# 论文进度追踪器 → macOS 原生应用：开发工作流

> 归档说明：这是一版早期迁移工作流草稿，保留供历史参考。当前仓库目录和最新实施方案以 `README.md` 和 `docs/superpowers/plans/2026-06-29-papertracker-macos-app-implementation.md` 为准。

---

## 一、目标

把 `tracker.html`（单文件网页）重构为原生 macOS SwiftUI 应用。

**核心动机**：数据直接存在本地 JSON 文件，不经过浏览器 localStorage，App 自动读取。

**兼容要求**：和网页版共享 `data.json` 格式，两个版本可交替使用。

---

## 二、当前项目状态

```
~/Projects/tool-paper-tracker/
├── tracker.html          ← 网页版，已完成，923行
├── data.json             ← 权威数据文件，两个版本共享
├── PLANS.md              ← 完整执行方案 + 设计方案
├── MACOS_WORKFLOW.md     ← 本文件
├── README.md             ← 使用说明
├── .gitignore
└── .git/
```

**网页版能力清单（SwiftUI 版需对标）**：

| 功能 | 网页版实现 |
|------|-----------|
| 论文 CRUD | ✅ 内联表单 + 表格 |
| 计时器 | ✅ ▶/⏹ 互斥、HH:MM:SS 跑表、崩溃恢复 |
| 审稿 CRUD | ✅ |
| 工作日志 | ✅ 自动生成 + 手动添加 + 编辑备注 |
| 截止日高亮 | ✅ 过期红 / 7天内黄 |
| 导出 CSV | ✅ 3 文件下载 |
| 导出/导入 JSON | ✅ 合并模式 |
| 硬盘文件同步 | ✅ Chrome File System Access API |
| 多标签检测 | ✅ localStorage 心跳 |
| 空状态引导 | ✅ |

---

## 三、SwiftUI 版架构

### 数据流

```
data.json（硬盘）←── Store.swift（ObservableObject）──→ SwiftUI Views
     ↕ 同一个文件                                        ↕ 内存中的 @Published 属性
   终端可直接编辑                                    UI 自动响应变化
```

**对比网页版**：网页版是 `localStorage ←→ data.json 双向备份`；SwiftUI 版是 **data.json 单一数据源**，不需要 localStorage。

### 文件结构（计划）

```
tool-paper-tracker/
├── PaperTracker.xcodeproj/     ← Xcode 项目（由 Xcode 创建）
├── PaperTracker/               ← 源代码
│   ├── PaperTrackerApp.swift   ← @main 入口，WindowGroup
│   ├── Models.swift            ← Paper / Review / Session 结构体，Codable
│   ├── Store.swift             ← ObservableObject，读写 data.json，所有 @Published
│   ├── ContentView.swift       ← 主布局：Header + 三个区域
│   ├── PaperListView.swift     ← 论文区：表单 + 表格 + 计时器
│   ├── ReviewListView.swift    ← 审稿区
│   ├── SessionListView.swift   ← 日志区
│   ├── TimerEngine.swift       ← Timer.publish 替代 setInterval
│   ├── ExportImport.swift      ← NSSavePanel / NSOpenPanel
│   └── Assets.xcassets/        ← App 图标
├── tracker.html                ← 保留不动
└── data.json                   ← 两个版本共享
```

### 技术选型

| 决策 | 选择 | 理由 |
|------|------|------|
| 框架 | SwiftUI | Apple 官方，代码量少 |
| 数据持久化 | 纯 JSON 文件（`~/Documents/PaperTracker/data.json`） | 便于备份、导入和人工审计 |
| 最低系统 | macOS 14 (Sonoma) | SwiftUI 稳定，覆盖绝大多数 Mac |
| 生命周期 | SwiftUI App (`@main`) | 最简入口 |
| 文件访问 | 无沙盒（App Store 外分发）或沙盒 + 用户选择目录 | 确保能读写 data.json |

---

## 四、数据模型（与网页版完全一致）

```swift
// Models.swift
struct Paper: Codable, Identifiable {
    var id: String = UUID().uuidString
    var title: String
    var status: PaperStatus = .writing
    var journal: String = ""
    var deadline: String = ""      // "YYYY-MM-DD"
    var totalSeconds: Int = 0
    var isRunning: Bool = false
    var sessionStart: Date? = nil
    var createdAt: Date = Date()
}

enum PaperStatus: String, Codable, CaseIterable {
    case writing = "写作中"
    case submitted = "投稿中"
    case rnr = "R&R"
    case accepted = "已接收"
    case published = "已发表"
}

struct Review: Codable, Identifiable {
    var id: String = UUID().uuidString
    var journal: String
    var deadline: String = ""
    var status: ReviewStatus = .pending
    var note: String = ""
    var createdAt: Date = Date()
}

enum ReviewStatus: String, Codable, CaseIterable {
    case pending = "待审"
    case reviewing = "审稿中"
    case done = "已提交"
}

struct Session: Codable, Identifiable {
    var id: String = UUID().uuidString
    var type: SessionType
    var targetId: String
    var targetName: String
    var start: Date
    var end: Date?
    var durationSeconds: Int = 0
    var note: String = ""
}

enum SessionType: String, Codable {
    case paper, review
}

struct AppData: Codable {
    var papers: [Paper] = []
    var reviews: [Review] = []
    var sessions: [Session] = []
}
```

---

## 五、Store 设计（对标网页版 localStorage + File System Access）

```swift
// Store.swift
class Store: ObservableObject {
    @Published var data = AppData()
    private let dataURL: URL
    
    init() {
        // 数据文件存在 ~/Documents/PaperTracker/data.json
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = docs.appendingPathComponent("PaperTracker")
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        dataURL = folder.appendingPathComponent("data.json")
        load()
    }
    
    func load() {
        guard let d = try? Data(contentsOf: dataURL),
              let appData = try? JSONDecoder().decode(AppData.self, from: d)
        else { return }
        data = appData
    }
    
    func save() {
        guard let d = try? JSONEncoder().encode(data) else { return }
        try? d.write(to: dataURL, options: .atomic)
    }
    
    // ---- Paper operations ----
    func addPaper(_ paper: Paper) { data.papers.append(paper); save() }
    func updatePaper(_ paper: Paper) { ...; save() }
    func deletePaper(_ id: String) { ...; save() }
    func startTimer(_ id: String) { /* 互斥逻辑 */ }
    func stopTimer(_ id: String) { /* 创建 session */ }
    
    // ---- Review operations ----
    // ---- Session operations ----
}
```

---

## 六、UI 布局（对标网页版）

```
┌──────────────────────────────────────────────────────┐
│  PaperTracker              📤 导出 CSV  💾 备份 JSON  │  ← 原生 toolbar
├──────────────────────────────────────────────────────┤
│                                                      │
│  ┌─ 我的论文 ────────────────────────────────────┐  │
│  │  [+ 添加论文]                                  │  │
│  │  论文名 · 状态 · 期刊 · 截止日 · 时间 · 操作    │  │
│  │  ──────────────────────────────────────────── │  │
│  │  ▎中国引文偏见  ✎投稿中  CPJ  —      ▶  ✏️   │  │
│  └────────────────────────────────────────────────┘  │
│                                                      │
│  ┌─ 审稿任务 ────────────────────────────────────┐  │
│  │  ...                                            │  │
│  └────────────────────────────────────────────────┘  │
│                                                      │
│  ┌─ 工作日志 ────────────────────────────────────┐  │
│  │  ...                                            │  │
│  └────────────────────────────────────────────────┘  │
│                                                      │
└──────────────────────────────────────────────────────┘
```

### 设计规范移植（核心 CSS 变量 → SwiftUI）

| 网页版 | SwiftUI |
|--------|---------|
| `--bg: #F5F4F0` | `Color(hex: "F5F4F0")` → window 背景 |
| `--accent: #2F4985` | `Color.accentColor` = "2F4985" |
| Charter 标题 | `Font.custom("Charter", size:)` — macOS 自带 |
| system-ui 正文 | `Font.body` — 默认 San Francisco |
| SF Mono 计时器 | `Font.system(.body, design: .monospaced)` |
| 状态色 5 种 | 各定义 Color extension |
| `deadline-overdue` 红底 | `listRowBackground` 条件渲染 |
| `deadline-soon` 黄底 | 同上 |
| 计时器脉动动画 | `withAnimation(.easeInOut(duration: 3).repeatForever())` |

---

## 七、计时器引擎（对标网页版 setInterval + tick）

```swift
// TimerEngine.swift
// 使用 Timer.publish 替代 setInterval

import Combine

class TimerEngine: ObservableObject {
    @Published var tick = Date()     // 每秒更新，驱动 UI 刷新
    private var cancellable: AnyCancellable?
    
    func start() {
        cancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] in self?.tick = $0 }
    }
    
    func stop() {
        cancellable = nil
    }
}
```

**计时器行 UI**：用 `.onReceive(timer.tick)` 在需要显示 HH:MM:SS 的视图里订阅，自动每秒刷新。

**计时恢复**：App 启动时检查 `isRunning == true` 的论文，`totalSeconds += now - sessionStart`，`sessionStart = now`。同网页版 `recoverTimers()`。

**计时互斥**：`startTimer(id)` 时先遍历停止其他 `isRunning` 的论文。

---

## 八、开发步骤（按顺序）

| 步 | 内容 | 预估 |
|----|------|------|
| 1 | 创建 Xcode 项目 → macOS App → SwiftUI → 命名 PaperTracker | 2 分钟 |
| 2 | 写 `Models.swift` — 全部数据模型 | 5 分钟 |
| 3 | 写 `Store.swift` — JSON 读写 + CRUD | 15 分钟 |
| 4 | 写 `ContentView.swift` — 三区骨架 | 10 分钟 |
| 5 | 写 `PaperListView.swift` — 论文表格 + 表单 + 计时显示 | 30 分钟 |
| 6 | 写 `TimerEngine.swift` — 跑表 | 10 分钟 |
| 7 | 写 `ReviewListView.swift` | 15 分钟 |
| 8 | 写 `SessionListView.swift` | 20 分钟 |
| 9 | 写 `ExportImport.swift` — CSV/JSON 导出导入 | 15 分钟 |
| 10 | 整体调试、对照网页版验证 | 20 分钟 |

---

## 九、AI 协作约定

### 数据文件位置

```
~/Documents/PaperTracker/data.json
```

**任何 AI（Claude/Codex）都可以直接读写这个文件来帮用户管理论文数据。** 格式与项目目录下的 `data.json` 完全一致。

### 对话示例

```
用户："添加一篇论文：数字乡村治理，投稿到 JPSJ"
AI：编辑 ~/Documents/PaperTracker/data.json → papers[] 追加一条
用户：打开 App → 论文已在列表中
```

### Swift 代码约束

- **我熟悉的语言是 R/Stata**。Swift 代码注释用中文，关键概念解释清楚
- **能不用的 Swift 特性就不用**：简单的 `if/else`、`ForEach`、`List`、`@State`、`@Published` 就够
- **避免**：泛型、Protocol 扩展、Result Builder、复杂的 Combine 管道
- **修改范围最小化**：改哪个功能就动哪个文件，一个 View 一个文件

---

## 十、环境要求

| 组件 | 要求 | 检查命令 |
|------|------|---------|
| Xcode | 16+（完整版，非 Command Line Tools） | `xcodebuild -version` |
| macOS | 15+（Sequoia）或 14（Sonoma）| 关于本机 |
| 磁盘 | ~15GB 空闲（Xcode） | 关于本机 → 存储空间 |

---

## 十一、当前状态

- [x] Xcode：**未安装**（仅有 Command Line Tools）
- [ ] 等 Xcode 装好后开始
- [x] 网页版 + data.json 同步：**已完成**
- [x] 本工作流文档：**已完成**
