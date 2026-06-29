# PaperTracker macOS App Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把当前 `tracker.html` 原型重构为长期可用的原生 macOS App，数据由 App 独占管理，首版支持论文/审稿/日志/计时/备份/旧数据导入，并提供 AI 辅助填写。

**Architecture:** App 采用 `SwiftUI` 做主界面，少量 `AppKit` 负责 `NSOpenPanel` / `NSSavePanel`。持久化使用 `~/Library/Application Support/PaperTracker/data.json`，由单一 `Store` 负责读写、校验、迁移、错误提示和自动保存；AI 能力通过 App 内配置的 API key 调用 OpenAI 兼容接口，模型输出只作为“待确认建议”，最终保存仍由确定性代码执行。

**Tech Stack:** Swift 6, SwiftUI, AppKit, Foundation, Combine, XCTest, Keychain Services, Xcode 26+

## Product UI Baseline

### Design Read

这是一个给单个研究者长期高频使用的 macOS 原生工具。视觉方向采用“原生工具感 + Things/Craft 式精致细节”，目标是稳定、清晰、耐用，不做展示型首页，不做夸张编辑风格。

### Design Dials

- `DESIGN_VARIANCE: 4`
- `MOTION_INTENSITY: 3`
- `VISUAL_DENSITY: 5`

解释：

- 布局稳定，不做高变形、不做实验性编排
- 动效只用于反馈和过渡，不做表演性动画
- 信息密度略高于 Notes/Reminders，但明显低于 Xcode 这类重工具

### Product UI Direction

- 主方向：`精致原生管理器`
- 参考气质：`Things / Craft`
- 避免方向：
  - 过度系统默认，导致没有识别度
  - 过度仪表盘化，像后台管理系统
  - 过度编辑化，影响高频操作效率

### Primary Window Structure

首版固定采用“双栏主界面”，不做三栏工作台：

- 左栏：导航与筛选
- 右栏：主内容区
- 编辑：通过内嵌详情区、popover 或 sheet 完成，不长期占据第三栏

### Left Sidebar Specification

左栏是轻量导航，不是文件树。默认信息架构：

- `All Papers`
- `Writing`
- `Submitted`
- `R&R`
- `Accepted / Published`
- `Reviews`
- `Sessions`
- `Today`

左栏底部保留一个轻状态区，用于：

- 显示最近保存时间
- 显示 AI 连接状态
- 提供备份入口

视觉要求：

- 使用原生 sidebar 语义
- 分组间距比系统默认更从容
- 选中态使用克制的胶囊/圆角高亮
- 不使用重边框，不堆分割线

### Right Pane Default Behavior

App 启动后，右侧主区域默认展示“论文列表管理器”，不是 dashboard，也不是单篇论文聚焦页。

右侧结构固定分三层：

1. 顶部工具栏
   - 页面标题
   - 搜索
   - 筛选
   - `+ New Paper`
   - `AI Assist`

2. 列表主体
   - 论文行是核心交互单元
   - 支持选中
   - 支持快速开始/停止计时
   - 支持快速修改状态

3. 次级详情层
   - 打开单篇论文后，用 sheet、popover 或内嵌详情展示
   - 不把主界面永久切成复杂三栏

### Interaction Priority

这个产品的核心路径不是看概览，而是高频完成以下动作：

- 找到论文
- 看当前状态
- 开始或停止计时
- 修改关键字段
- 快速补一条日志或备注

所以右侧主区要优先做成“对象管理器”，而不是展示型工作台首页。

### Visual Language Rules

- 基础观感应接近原生 App，但细节比系统默认更精致
- 颜色控制克制，以中性底色 + 单一强调色为主
- 字重、留白、分组节奏要清楚，靠层级而不是装饰制造设计感
- 动画只保留必要反馈：
  - 选中切换
  - 列表插入/删除
  - sheet / popover 出入场
- 计时状态变化
- 不使用夸张渐变、玻璃炫技、强阴影、营销页式大卡片

### Typography System

首版完全使用 macOS 系统字体，不引入额外品牌字体：

- 主字体：`SF Pro Text`
- 标题与较大层级：`SF Pro Display`
- 计时器与数字：`SF Mono`

具体层级：

- 窗口主标题：`16-20pt`, `semibold`
- 分区标题：`13-14pt`, `semibold`
- 列表主标题：`13pt`, `medium`
- 次信息：`12pt`, `regular`
- 辅助说明：`11-12pt`, `regular`
- 计时器：`13pt`, `medium`, monospaced digits

规则：

- 不使用衬线标题
- 不使用网页品牌页式 display font
- 精致感来自层级、节奏、留白，而不是字体猎奇

### Color System

整体采用“冷中性底色 + 单一深靛蓝强调色”。

基础色建议：

- Window background: `#F3F4F6`
- Sidebar background: `#ECEFF3`
- Primary surface: `#FFFFFF`
- Secondary surface: `#F7F8FA`
- Divider: `#D9DEE6`
- Primary text: `#1E2430`
- Secondary text: `#667085`
- Accent: `#315AA9`
- Accent pressed: `#274987`

论文状态色原则：

- `Writing`：降饱和金棕
- `Submitted`：钢蓝
- `R&R`：烟紫
- `Accepted`：深绿
- `Published`：青灰绿

规则：

- 页面只允许一个真正的主强调色：蓝色
- 状态色只用于标签、小圆点、局部提示
- 不做大面积彩色卡片
- 不做暖米色书页感

### Material and Shape System

- 主容器 / sheet 圆角：`16`
- 行内控件圆角：`10`
- 小按钮 / 筛选器圆角：`8`
- 选中胶囊圆角：`10`

阴影规则：

- 主内容面只允许极轻阴影
- sidebar 不浮起
- popover / sheet 可以比主界面更明显一点，但仍需克制
- 禁止 marketing 风格强投影、发光、玻璃炫技

### Sidebar Visual Rules

- 左栏宽度稳定，不做极窄导航
- 分组标题使用小字号弱化文本
- 选中项使用柔和底色胶囊，不用重描边
- 图标与文字严格对齐
- 行高偏舒展，不做拥挤清单

底部状态区内容固定为：

- 最近保存时间
- AI 连接状态
- 备份入口

该区块应表现为静态系统信息，而不是一组强按钮

### Toolbar Visual Rules

右侧顶部工具栏不是 hero，而是 command bar：

- 页面标题
- 搜索框
- 状态筛选
- `+ New Paper`
- `AI Assist`

规则：

- 工具栏高度低而稳定
- 控件对齐严格
- 搜索框和筛选器比主按钮弱
- `+ New Paper` 是唯一主按钮
- `AI Assist` 是次主按钮，不能和新建抢层级

### List Row Visual Rules

论文列表行是核心视觉单元。

一行结构：

- 左：标题 + 期刊 / 摘要
- 中：状态、截止日
- 右：累计时间、开始/停止、更多操作

视觉优先级：

1. 论文标题
2. 当前状态
3. 计时状态
4. 截止日风险
5. 其他字段

规则：

- 默认行非常干净
- hover 轻微提亮
- 选中态明确但不重蓝
- 正在计时的行不再使用 pulse，而是：
  - 左侧 `2-3px` 细强调条
  - 时间数字切换为强调蓝
  - 标题字重略提升
  - 行背景微微提亮

### Form and Sheet Rules

- 完整编辑优先使用 `sheet`
- 快速改状态、快速备注优先使用 `popover`
- 主列表不堆过多 inline 表单

表单规则：

- label 在上，field 在下
- 每组最多两列
- 长文本独占一行
- 用间距做分组，不靠重边框包块
- 输入框高度、圆角、聚焦态统一
- 错误提示就地显示在字段下方

### Motion Rules

只保留必要反馈：

- sidebar 选中切换
- 列表插入 / 删除
- sheet 打开 / 关闭
- 计时状态切换
- hover / pressed 反馈

禁止：

- 持续脉冲动画
- 大面积模糊漂浮
- 花哨转场
- dashboard 式数据表演动效

### Component Rules

#### Buttons

只保留三级按钮体系：

- `Primary`
  - 用于 `+ New Paper`、`Save`、关键确认
  - 实色填充，唯一强调蓝
  - 高度稳定，圆角 `8-10`
  - `semibold`

- `Secondary`
  - 用于 `AI Assist`、`Import`、`Export`
  - 浅底或细边框
  - 与 primary 同高，但视觉更弱

- `Tertiary / Inline`
  - 用于 `Edit`、`More`、列表轻操作
  - 更像文字按钮或轻胶囊
  - hover 时才增强存在感

#### Search

- 搜索框位于右侧顶部工具栏
- 宽度中等，不占半屏
- 左侧搜索图标，右侧清空
- 背景略低于白卡面
- 边框极轻
- 聚焦时只增强一层，不做强蓝光

#### Filter Chips

- 视觉上介于 segmented control 和轻胶囊之间
- 默认弱存在感
- 选中后底色略深、文字更实
- 不做彩色 chip 海洋

#### Status Tags

- 左侧小圆点 + 右侧短文本
- 小字号
- 不做大药丸
- 尺寸一致
- 只改颜色，不改形状

#### Empty States

各区独立空状态：

- Papers Empty：强调这是论文管理器，并提供新建入口
- Reviews Empty：说明这里记录审稿任务
- Sessions Empty：说明开始计时或手动添加后会出现内容

规则：

- 图形极简
- 文案短
- 不卖萌
- 主按钮清楚

#### AI Assist Panel

- AI 面板必须是辅助角色，不是主舞台
- 入口位于工具栏，打开方式优先 sheet
- 结构固定为：
  1. 输入原始文本
  2. 生成建议
  3. 预览结构化字段
  4. 逐项应用
  5. 用户手动保存

规则：

- 不模仿聊天应用
- 不做大对话气泡
- 重点是结构化字段卡片与应用动作

#### Feedback

只在下面场景使用 toast：

- 保存成功
- 导出成功
- 备份成功
- AI 请求失败但不阻塞当前操作

下面场景必须就地显示，不用 toast：

- 表单校验错误
- 搜索无结果
- 空列表
- 导入预览阶段

### Page Blueprints

#### Papers Main Page

这是 App 默认首页，也是最重要的页面。

右侧内容区从上到下分三层：

1. 顶部工具栏
   - 页面标题：`Papers`
   - 搜索框
   - 状态筛选
   - `AI Assist`
   - `+ New Paper`

2. 次级状态条
   - 当前筛选结果数
   - 是否有正在计时的论文
   - 如有需要，仅显示轻量状态，如 `1 active timer`

3. 论文列表主体
   - 主列表是页面核心
   - 每行显示标题、期刊、状态、截止日、累计时间、操作

视觉要求：

- 第一眼必须看出哪些论文在进行中
- 第一眼必须看出哪篇正在计时
- 第一眼必须看出哪些快到 deadline
- 不能用大卡片、统计图、欢迎语稀释主任务

空状态：

- 主文案：`Start with your first paper`
- 短辅助文案说明这是论文管理器
- 主按钮：`New Paper`

#### Paper Edit Sheet

单篇论文编辑界面应像一张干净工作纸，而不是配置面板。

结构分四块：

1. Header
   - `New Paper` 或论文标题
   - 轻量副标题，如创建时间或当前状态
   - 关闭按钮

2. Basic Info
   - 标题
   - 期刊
   - 状态
   - 截止日期

3. Work Tracking
   - 累计时长
   - 当前是否运行
   - 最近一次 session 信息
   - `View Sessions`

4. Notes
   - 备注
   - 可承接 AI 生成建议

底部操作区：

- 左侧可放删除等危险操作
- 右侧固定 `Cancel` + `Save`

#### Reviews Page

Reviews 页与 Papers 页同源，但更轻。

结构：

- 顶部工具栏：`Reviews`
- 搜索
- 状态筛选
- `+ New Review`

列表字段：

- Journal
- Deadline
- Status
- Note preview
- Actions

视觉重点：

- 哪些审稿快到期
- 哪些正在进行
- 哪些已完成

空状态：

- 说明这里记录审稿任务
- 主按钮：`New Review`

#### Sessions Page

Sessions 页更像活动记录，不是对象管理器。

结构：

- 顶部工具栏：`Sessions`
- 筛选：`All / Papers / Reviews / Today / This Week`
- 可选 `+ Add Session`

主体为倒序时间流：

- 按日期分组
- 每条显示对象、类型、起止时间、时长、备注
- 每条可快速编辑备注

视觉优先级：

1. 做了什么
2. 花了多久
3. 什么时候做的
4. 备注

#### Settings Page

Settings 必须克制，不做高级控制台。

建议分区：

1. Data
   - 数据文件位置说明
   - 导出备份
   - 恢复备份
   - 导入旧数据

2. AI
   - Base URL
   - Model
   - API Key
   - Test Connection

3. App
   - 少量显示偏好
   - 如默认页、日期显示方式

要求：

- 每个设置块可单独理解
- 敏感项和危险项明确分开
- API key 配置体验干净，不暴露多余技术细节

#### AI Assist Sheet

AI 界面必须是结构化助手，不是聊天窗口。

布局分三段：

1. Input
   - 大文本输入框
   - 引导用户粘贴摘要、邮件、笔记或原始描述

2. Suggested Fields
   - 结构化字段卡片：
     - `title`
     - `journal`
     - `status`
     - `deadline`
     - `note`
   - 每项支持 `Apply`

3. Final Action
   - `Apply Selected`
   - `Close`

体验重点：

- 用户必须能一眼分清 AI 建议和当前真实数据
- 应用前可挑字段
- 不自动保存
- 不做聊天记录堆叠

#### Lightweight Global Status

全局轻量状态位：

1. Sidebar Bottom
   - `Saved just now`
   - `AI connected`
   - `Backup`

2. 顶部轻提示
   - 如果有正在计时：
     - `Writing now`
     - 当前论文标题
     - 已运行时长

规则：

- 这些状态必须轻，不做大 banner
- 不让主界面变成 dashboard

#### Cross-Page Consistency Rules

所有页面都必须共享：

- 同一套 toolbar 高度
- 同一套按钮层级
- 同一套列表节奏
- 同一套 sheet 结构
- 同一套空状态语言
- 同一套状态标签样式

### SwiftUI Implementation Mapping

#### Top-Level Container

主窗口固定使用 `NavigationSplitView`：

- 左栏：sidebar
- 右栏：detail container
- 首版不启用第三栏

原因：

- 已确认产品结构是双栏
- `NavigationSplitView` 更稳定、更原生
- 避免自行用 `HStack` 拼出伪原生壳子

#### Navigation State Ownership

导航状态必须独立于业务数据模型。

建议使用明确的导航枚举：

- `allPapers`
- `writing`
- `submitted`
- `rnr`
- `acceptedPublished`
- `reviews`
- `sessions`
- `today`

状态归属：

- 当前 sidebar 选中项：app 级 UI state
- 搜索词：页面级 UI state
- 当前选中的论文 id：论文页级 UI state
- 当前打开的 sheet / popover：页面级或 app shell 级 UI state

原则：

- 业务数据放 `DataStore`
- 导航和展示状态不塞进数据模型

#### View Decomposition

建议视图拆分如下：

1. App 层
   - `PaperTrackerApp`
   - `AppEnvironment`
   - `RootContentView`

2. Shell 层
   - `SidebarView`
   - `DetailContainerView`
   - `TopStatusStripView`

3. Papers 功能
   - `PaperPageView`
   - `PaperToolbarView`
   - `PaperListView`
   - `PaperRowView`
   - `PaperEditorSheet`
   - `PaperQuickActionsPopover`

4. Reviews 功能
   - `ReviewPageView`
   - `ReviewListView`
   - `ReviewRowView`
   - `ReviewEditorSheet`

5. Sessions 功能
   - `SessionPageView`
   - `SessionTimelineView`
   - `SessionRowView`
   - `SessionEditorSheet`

6. Settings / AI
   - `SettingsView`
   - `AIAssistSheet`
   - `AIAssistSuggestionCard`

规则：

- 页面壳子和行组件分开
- sheet 和主页面分开
- toolbar 不和 list 写进一个超大文件

#### Sheet Usage Rules

优先用 `sheet` 的场景：

- 新建论文
- 编辑论文
- 新建审稿
- 编辑审稿
- `AI Assist`
- `Settings`
- 导入 / 恢复前的确认流程

原因：

- 这些都是完整任务
- 需要明显脱离列表上下文
- 更符合精致原生感

#### Popover Usage Rules

优先用 `popover` 的场景：

- 快速改状态
- 快速补备注
- 行内更多操作
- 小型筛选扩展

规则：

- 短动作用 popover
- 完整任务不用 popover 硬撑

#### Inline Editing Constraints

首版避免以下模式：

- 在主列表里铺开大表单
- 一行展开成半屏编辑器
- 同时让多个 row 进入编辑态

主列表职责只保留：

- 浏览
- 选择
- 快速操作
- 进入编辑

#### Design Tokens Placement

需要一层轻量 Theme / Tokens 文件，不做过重主题系统。

至少统一：

1. Colors
   - window background
   - sidebar background
   - primary surface
   - secondary surface
   - divider
   - primary text
   - secondary text
   - accent
   - status colors

2. Radius
   - sheet
   - control
   - chip
   - selection capsule

3. Spacing
   - page padding
   - section gap
   - row padding
   - control height

4. Typography
   - window title
   - section title
   - row title
   - metadata
   - mono timer

#### Sidebar Implementation

`SidebarView` 必须独立实现：

- 不是文件树
- 不做复杂 `DisclosureGroup`
- 每项包含 icon、title、可选 count
- 选中态完全统一
- 底部状态区独立，不混入导航项

可观察状态：

- 当前导航
- 最近保存状态
- AI 是否已配置
- 是否存在活跃计时

#### Papers Page Implementation

右侧论文页建议拆成：

- `PaperPageView`
  - `PaperToolbarView`
  - `PaperSecondaryStatusView`
  - `PaperListView`

其中 `PaperListView` 内每行独立为 `PaperRowView`。

目的：

- 让 row 级计时高亮逻辑局部化
- 避免整页因计时器每秒重绘
- 便于后续扩展 selection、context menu、drag

#### Timer Update Strategy

计时器刷新不能驱动整页每秒重绘。

必须尽量做到：

- 只有运行中的 row 需要更新显示秒数
- 其他 row 保持静止

建议：

- `PaperTimerController` 提供当前时间 tick
- `PaperRowView` 只在自身 paper 为 running 时订阅或计算显示时间

#### Sessions Page Implementation

Sessions 页优先实现为：

- 外层 `ScrollView`
- 内层按日期分组
- 每组一个轻标题
- 每条是标准 `SessionRowView`

不优先做生硬 `Table`

#### AI Assist Data Flow

AI Assist 必须做成独立 `sheet`，数据流固定为：

1. 用户输入原始文本
2. `AIService` 请求并返回结构化建议
3. suggestions 只保存在 AI sheet state
4. 用户点 `Apply`
5. 把选中字段写回目标表单 state
6. 用户点 `Save` 后才真正落盘

原则：

- AI sheet 不直接改 `DataStore`
- 先改表单态，再由表单保存

#### Shared Components

建议抽共享组件，避免每页各写一套：

- `AppToolbar`
- `SectionHeader`
- `StatusTag`
- `EmptyStateView`
- `PrimaryButton`
- `SecondaryButton`
- `SearchField`
- `FilterChip`
- `MetadataText`

#### UI Build Order

按已确认产品路径，UI 落地顺序固定为：

1. `NavigationSplitView` 壳子
2. `SidebarView`
3. Papers 默认页
4. `PaperRowView`
5. `PaperEditorSheet`
6. Timer feedback
7. Reviews
8. Sessions
9. Settings
10. `AIAssistSheet`

### Design Token Draft

#### Color Tokens

首版先固定 light theme，dark mode 预留接口但不强行首发。

基础色：

- `windowBg = #F3F4F6`
- `sidebarBg = #ECEFF3`
- `surfacePrimary = #FFFFFF`
- `surfaceSecondary = #F7F8FA`
- `surfaceTertiary = #EEF1F5`

文字色：

- `textPrimary = #1E2430`
- `textSecondary = #667085`
- `textTertiary = #8A94A6`
- `textOnAccent = #FFFFFF`

线条色：

- `lineSubtle = #E3E7EE`
- `lineStandard = #D9DEE6`
- `lineStrong = #C8D0DB`

强调色：

- `accentPrimary = #315AA9`
- `accentPressed = #274987`
- `accentSoft = #E7EEF9`
- `accentTint = rgba(49, 90, 169, 0.10)`

状态色：

- `statusWriting = #9C7A2B`
- `statusSubmitted = #4E708F`
- `statusRNR = #75618A`
- `statusAccepted = #46745B`
- `statusPublished = #4B7C78`

反馈色：

- `success = #3F7A5A`
- `warning = #B4882E`
- `danger = #B24A45`
- `dangerSoft = #FBE9E7`

规则：

- 蓝色是唯一真正主强调色
- 状态色只用于标签、小圆点、局部风险提示
- 所有浅背景保持冷中性，不做奶油暖色

#### Radius Tokens

- `radiusWindow = 18`
- `radiusSheet = 16`
- `radiusControl = 10`
- `radiusChip = 8`
- `radiusPill = 999`

使用规则：

- 大容器 / sheet：`16`
- 输入框 / 按钮 / 搜索框：`10`
- filter chip / 小按钮：`8`
- 完整胶囊选择态才使用 `pill`

#### Spacing Tokens

基础节奏：

- `space2 = 4`
- `space3 = 6`
- `space4 = 8`
- `space5 = 10`
- `space6 = 12`
- `space8 = 16`
- `space10 = 20`
- `space12 = 24`
- `space14 = 28`
- `space16 = 32`

语义化间距：

- `pagePadding = 20`
- `sidebarPadding = 14`
- `toolbarHeight = 52`
- `toolbarInnerGap = 10`
- `sectionGap = 20`
- `cardPadding = 16`
- `sheetPadding = 20`
- `rowPaddingVertical = 10`
- `rowPaddingHorizontal = 14`
- `fieldGap = 14`
- `formSectionGap = 20`

#### Typography Tokens

- `windowTitle`: `SF Pro Display`, `18`, `semibold`
- `pageTitle`: `SF Pro Display`, `16`, `semibold`
- `sectionTitle`: `SF Pro Text`, `13`, `semibold`
- `bodyPrimary`: `SF Pro Text`, `13`, `regular`
- `bodySecondary`: `SF Pro Text`, `12`, `regular`
- `bodyTertiary`: `SF Pro Text`, `11`, `regular`
- `buttonLabel`: `SF Pro Text`, `13`, `semibold`
- `chipLabel`: `SF Pro Text`, `12`, `medium`
- `fieldLabel`: `SF Pro Text`, `11`, `medium`
- `metaLabel`: `SF Pro Text`, `11`, `regular`
- `timerText`: `SF Mono`, `13`, `medium`
- `numericMeta`: `SF Mono`, `11`, `regular`

#### Control Metrics

- `controlHeightLarge = 36`
- `controlHeightStandard = 32`
- `controlHeightCompact = 28`
- `sidebarRowHeight = 30`
- `paperRowMinHeight = 56`
- `toolbarSearchWidth = 220`

规则：

- `+ New Paper`、`AI Assist`、搜索框默认使用 `32`
- filter chip 默认使用 `28`
- sidebar item 高度固定 `30`
- 论文列表行最小高度固定 `56`

#### Shadow and Elevation Tokens

只保留三档：

- `shadowNone`
- `shadowSoft`
- `shadowOverlay`

规则：

- 主内容面只允许 `shadowSoft`
- sheet / popover 使用 `shadowOverlay`
- 色调偏冷灰，不做纯黑重投影

#### Border Tokens

- `borderSubtle = 1px lineSubtle`
- `borderStandard = 1px lineStandard`

规则：

- 搜索框、输入框：`borderSubtle`
- 列表容器、sheet 局部区块：`borderStandard`
- 不允许所有块都画边框

#### Status Tag Metrics

- 圆点直径：`6`
- 圆点与文本间距：`6`
- 标签字体：`12`, `medium`
- 纵向 padding：`0`
- 横向 padding：`0`

状态标签应更像状态文本，而不是 badge。

#### Selection Tokens

Sidebar Selected:

- background: `accentSoft`
- text: `accentPrimary`
- icon: `accentPrimary`

List Row Selected:

- background: `#EEF3FB`
- title weight 略提升
- 不加重描边

Running Row:

- left accent bar: `accentPrimary`
- timer text: `accentPrimary`
- row background: 轻 `accentTint`

#### Toast Tokens

- 成功 toast：中性色底 + 成功色点缀
- 错误 toast：中性色底 + 错误色 icon / label
- 圆角：`10`
- 内边距：`12 x 14`
- 字号：`12`

#### Token Code Organization

SwiftUI 代码中至少拆分为：

- `AppColors`
- `AppTypography`
- `AppSpacing`
- `AppRadius`
- `AppMetrics`

如果不拆多个文件，也必须有集中定义源，禁止在各 View 中散落 hex、字号、圆角魔法值。

### SwiftUI Component Specification

#### `SidebarView`

责任：

- 展示主导航
- 展示分区数量或状态
- 展示底部状态区
- 负责导航选择，不负责业务数据变换

内容结构：

1. 顶部 App 标识区
   - `PaperTracker`
   - 可选轻副标题：`Research Workspace`

2. 导航区
   - `All Papers`
   - `Writing`
   - `Submitted`
   - `R&R`
   - `Accepted / Published`
   - `Reviews`
   - `Sessions`
   - `Today`

3. 底部状态区
   - `Saved just now`
   - `AI connected` / `AI not configured`
   - `Backup`

规则：

- 选中项是柔和胶囊，不是重蓝块
- count 弱于标题
- 底部状态区与导航区明确分层
- 不直接负责筛选业务数据

#### `AppToolbar`

责任：

- 统一 toolbar 高度和布局
- 承载标题、搜索、筛选、主次按钮
- 保证 Papers / Reviews / Sessions 页顶部结构一致

建议插槽：

- `title`
- `leadingMeta`
- `search`
- `filters`
- `secondaryActions`
- `primaryAction`

规则：

- 高度固定
- 内容垂直居中
- 主按钮永远在最右
- 不允许每页长成不同 toolbar

#### `SearchField`

责任：

- 输入搜索词
- 提供清空
- 保持搜索框样式一致

组成：

- 左侧放大镜 icon
- 中间文本
- 右侧清空按钮

规则：

- 高度固定 `32`
- 圆角 `10`
- 浅底色 + 极轻边框
- focus 时只轻微增强

#### `FilterChip`

责任：

- 展示筛选项是否激活
- 支持单选或多选切换
- 保持筛选视觉一致

规则：

- 高度 `28`
- 文字 `12 medium`
- 默认弱存在感
- 激活后使用轻 accent 背景

#### `PaperPageView`

责任：

- 组合 toolbar、状态条、list
- 持有页面级 UI state
- 决定何时打开 `PaperEditorSheet`
- 决定何时打开 `AIAssistSheet`

持有状态：

- 搜索词
- 当前筛选
- 当前选中 paper id
- 是否打开新建 / 编辑 sheet
- 是否打开 AI Assist

不负责：

- 不直接计算计时器秒数
- 不处理单个 row 的展示细节

#### `PaperListView`

责任：

- 渲染 rows
- 处理 selection
- 管理空状态显示
- 管理滚动容器

规则：

- 更像 list，不像硬表格
- header 很轻
- row 间距稳定
- 分隔线很淡

#### `PaperRowView`

责任：

- 显示单篇论文核心信息
- 展示选中态
- 展示运行中状态
- 提供最少量快速操作

结构：

- 左：标题、期刊、次信息
- 中：状态、deadline
- 右：时间、start/stop、more

规则：

- 标题是最重要文本
- 运行中状态靠细强调条和时间高亮表达
- deadline 风险可见但不喧宾夺主
- 不自己写入 session 逻辑

#### `StatusTag`

责任：

- 展示状态点和文本
- 根据语义状态选择颜色
- 保持 Papers / Reviews 一致

规则：

- 小圆点 + 文本
- 不做胶囊 badge
- 字号 `12`

#### `EmptyStateView`

责任：

- 展示标题
- 展示一句说明
- 展示一个主操作按钮
- 可选辅助操作

使用场景：

- Papers 空
- Reviews 空
- Sessions 空
- 搜索无结果

规则：

- 同一套版式
- 只换文案与按钮

#### `PaperEditorSheet`

责任：

- 承载新建 / 编辑论文表单
- 承载 AI 建议应用结果
- 管理表单级校验
- 保存前汇总字段

内部结构：

- Header
- Basic Info section
- Work Tracking section
- Notes section
- Footer actions

持有状态：

- `title`
- `journal`
- `status`
- `deadline`
- `note`
- `isDirty`
- `validationErrors`

规则：

- 不直接调用低层 JSON 写盘
- 不自己做 AI 请求

#### `PaperQuickActionsPopover`

责任：

- 快速改状态
- 快速补备注
- 快速跳转到完整编辑
- 可选删除入口

规则：

- 只容纳短动作
- 不放复杂表单

#### `SessionTimelineView`

责任：

- 按日期分组
- 渲染 session rows
- 保持 timeline 节奏感

规则：

- 日期标题弱但清楚
- 每条 session 比 paper row 更轻

#### `SettingsView`

责任：

- 分区展示 `Data / AI / App`
- 管理用户设置项
- 承接备份恢复和连接测试入口

规则：

- 每区块可独立理解
- 破坏性操作分开

#### `AIAssistSheet`

责任：

- 输入原始文本
- 发请求
- 展示结构化建议
- 把建议应用到目标表单

内部结构：

- 输入区
- 结果区
- 应用区

边界：

- 不直接保存数据
- 不拥有论文实体
- 只是建议生成器

#### `AIAssistSuggestionCard`

责任：

- 展示单个建议字段
- 显示字段名、建议值、可信度
- 支持单项应用

规则：

- 像结构化结果卡
- 不像聊天气泡

#### Shared Buttons

建议统一封装：

- `PrimaryButton`
- `SecondaryButton`

目的：

- 保证按钮高度、圆角、字重、padding 一致

#### Component Hierarchy Principle

组件系统遵守三条：

1. 页面容器负责结构和导航
2. 功能组件负责交互和局部状态
3. 共享组件负责统一视觉，不负责业务判断

### Interaction and State Transition Rules

#### Sidebar Selection

默认：

- 未选中项保持安静
- icon 与文字使用次级色
- hover 不做强跳变

Hover：

- 背景轻微提亮
- 文字变得更实一点

Selected：

- 胶囊底色出现
- icon 与文字切到 `accentPrimary`
- 字重轻微提高
- 不做重描边和膨胀阴影

切换规则：

- 点击 sidebar 项时，右侧内容立即切换
- 若右侧存在未保存编辑态，必须先触发保护逻辑

#### List Row Selection

Default：

- 行背景透明
- 标题使用主色
- 次信息使用次级色

Hover：

- 行背景轻微提亮
- 操作按钮更清晰

Selected：

- 行背景切换为轻 `accentTint`
- 标题字重略提升
- 不做 Finder 式重蓝高亮块

Keyboard Focus：

- 键盘移动 selection 时，focus 与 selected 合并表现
- focus ring 只用于真正需要输入焦点的控件

#### Timer Start / Stop

Start 时必须立刻发生：

1. 当前行进入 running state
2. 若已有其他运行中论文，先自动停止对方
3. 顶部轻状态或 sidebar 底部状态同步更新
4. 时间显示立即开始变化

Stop 时必须立刻发生：

1. 当前行退出 running state
2. 累积时长固定写入显示
3. 自动生成 session
4. 提供轻反馈提示

视觉反馈以 row 自身变化为主：

- 左侧细强调条
- 时间高亮
- 按钮从 `Start` 切到 `Stop`

toast 只是补充，不是主反馈。

#### Timer Recovery

如果上次退出时有运行中的 timer：

- 启动时先恢复累计时间
- 再把 UI 切到 running state
- 不弹阻断警告

可选轻提示：

- `Timer restored`

该提示优先放轻状态区，不必强制 toast。

#### Sheet Open / Close

打开：

- 使用标准 sheet 动画
- 不做夸张缩放表演

关闭：

- 无脏数据时直接关闭
- 有脏数据时必须弹确认

Dirty State 保护：

- 只要字段被修改，就进入 `dirty`
- 关闭时若 `dirty && 未保存`：
  - `Discard Changes`
  - `Keep Editing`

#### Save Behavior

Save 成功：

- sheet 关闭
- 主列表立即反映新数据
- 可显示轻 toast：`Saved`
- sidebar 保存时间同步更新

Save 失败：

- sheet 不关闭
- 错误就地显示或在 sheet 顶部显示
- 不允许静默失败

#### Delete Behavior

删除论文：

- 必须二次确认
- 确认内容明确说明对象名称
- 如影响相关 sessions，必须提示
- 明确不可撤销

删除 session / review：

- 也要确认
- 但层级可低于论文删除

#### Search States

输入中：

- 实时过滤
- 不做 toast

无结果：

- 列表区域切换为空状态
- 显示短说明
- 提供清空搜索入口

清空：

- 恢复原列表
- 不做表演型动画

#### Filter States

选择筛选器后：

- 立刻更新列表
- 顶部次级状态条同步结果数

若有组合筛选：

- 必须能一眼看出当前筛选条件
- 可使用轻量 filter summary

重置：

- 提供 `Clear Filters`
- 作为次操作

#### AI Assist State Machine

状态固定为：

1. `Idle`
2. `Generating`
3. `Success`
4. `Failure`
5. `Apply`

行为要求：

- `Idle`：显示输入引导
- `Generating`：禁用重复提交，显示加载状态
- `Success`：展示结构化建议，支持部分应用
- `Failure`：显示失败原因，允许重试
- `Apply`：只写回表单态，不直接保存

AI 应用后，目标表单必须进入 `dirty` 状态。

#### Toast vs Inline Feedback

允许 toast：

- 保存成功
- 导出成功
- 备份成功
- AI 请求失败但不阻塞主流程

禁止用 toast：

- 表单字段错误
- 删除确认
- 导入预览
- 搜索无结果
- 空列表
- API key 缺失

这些都必须就地展示。

#### Keyboard Interaction

首版建议支持：

- `Cmd + N`：新建论文
- `Cmd + F`：聚焦搜索
- `Esc`：关闭 sheet / popover
- 上下箭头：移动列表选择
- `Enter`：打开当前选中项编辑

首版不默认绑定 `Space` 到计时，避免误触。

#### Focus Rules

- 输入框 focus 明确
- 搜索框 focus 明确
- button focus 不夸张
- row selection 与输入 focus 必须区分

解释：

- selection 表示当前对象
- focus 表示当前输入位置

#### Empty-State Variants

必须区分三种空状态：

1. 真空状态
   - 从未有数据
   - 引导新建

2. 搜索空状态
   - 有数据，但搜索无结果
   - 引导清空搜索

3. 筛选空状态
   - 有数据，但当前筛选为空
   - 引导清空筛选

三种文案和按钮不能完全相同。

#### Update Rhythm

关键状态更新节奏固定为：

1. 先更新局部 UI
2. 再同步全局轻状态
3. 再落盘
4. 失败则回退或提示

#### Interaction Principles

首版交互遵守四条：

1. `快`
2. `轻`
3. `稳`
4. `可恢复`

### UI Review Checklist

#### Direction Consistency Review

必须检查：

- 当前界面是否仍然是“精致原生管理器”
- 是否长成 dashboard
- 是否长成后台管理系统
- 是否长成网页套壳
- 是否为了“设计感”损害高频操作效率

一票否决项：

- 默认页不是论文列表
- 主界面不再是双栏
- AI 面板开始抢主界面中心
- 视觉依赖大卡片、大阴影、大渐变

#### Structure Review

必须检查：

- `NavigationSplitView` 双栏是否清楚
- sidebar、toolbar、detail 区职责是否混淆
- 页面结构是否在不同页面间保持一致
- sheet / popover 是否承担了正确复杂度的任务

一票否决项：

- 右侧各页面结构完全不同
- 论文列表里塞进大段 inline 编辑
- 本该 sheet 的任务被塞进 popover
- 本该 popover 的小动作反而打开整页编辑

#### Visual Consistency Review

必须检查：

- 字体层级是否稳定
- 间距是否来自统一 token
- 圆角是否统一
- 蓝色是否仍然是唯一主强调色
- 状态色是否被滥用
- Papers / Reviews / Sessions 是否像同一个产品

一票否决项：

- 某一页突然换了不同按钮风格
- 控件圆角系统不一致
- 同一状态标签在不同页面长得不一样
- toolbar 高度每页不同

#### List Experience Review

必须检查：

- 论文行是否一眼可扫
- 当前状态是否很快能看出来
- 正在计时的行是否明显但不焦躁
- deadline 风险是否可见但不过度惊扰
- `hover / selected / running` 三种状态是否分得清

一票否决项：

- 行太像硬表格
- 行太像卡片墙
- running 仍靠 pulse 感知
- selected 和 hover 混在一起
- 信息主次不清，标题不突出

#### Sidebar Review

必须检查：

- 选中态是否克制
- count 是否压过标题
- 底部状态区是否像信息区，而不是按钮堆
- icon、文字、count 对齐是否稳定

一票否决项：

- 左栏太像文件树
- 左栏太像网页菜单
- 底部状态区过吵
- 选中态像 Finder 式重蓝高亮块

#### Sheet and Popover Review

必须检查：

- 论文编辑是否主要在 sheet 内完成
- 快速状态修改是否主要在 popover 内解决
- 关闭 sheet 时 dirty protection 是否可靠
- sheet 内部结构是否分组清楚

一票否决项：

- 主列表承担大编辑任务
- popover 被塞成半个表单页
- sheet 没有清楚的 `Save / Cancel` 层级
- dirty 状态没有保护

#### AI Review

必须检查：

- AI 是否仍然是辅助角色
- 是否是结构化助手，而不是聊天窗
- suggestions 是否先写回表单态，而不是直接落盘
- 失败时是否不会污染现有数据

一票否决项：

- AI 直接修改 `DataStore`
- AI 界面像聊天产品
- `AI Assist` 比 `+ New Paper` 更抢眼
- 无 key / 请求失败时用户不知道发生了什么

#### Interaction Stability Review

必须检查：

- 点击 sidebar 是否总是可预测
- timer start / stop 是否立即反馈
- save 失败时是否可见
- search / filter / empty state 是否分得清
- selection 和 focus 是否区分清楚

一票否决项：

- 点击后界面没有立刻反馈
- 状态变化靠 toast 才知道
- 关闭 sheet 会悄悄丢内容
- 空状态都长得一样
- focus 和 selection 混乱

#### Native Feel Review

必须检查：

- toolbar 是否足够克制
- sidebar 是否足够原生
- 控件尺寸是否像桌面产品
- 动画是否轻
- 阴影是否克制
- 输入框、按钮、sheet 是否像同一系统

一票否决项：

- 太像网页后台
- 太像营销页组件拼出来的 App
- 动画太花
- 阴影太重
- 颜色太热或太花

#### High-Frequency Use Review

必须检查：

- 连续看一小时会不会累
- 高频按钮是否容易点
- 主路径是否最短
- 最常见动作是否不需要绕路
- 信息密度是否刚好够用

一票否决项：

- 为了“好看”牺牲效率
- 常见动作藏进二级层
- 页面太松，操作要滚很多
- 页面太挤，信息一团

#### Stage-Specific Review Gates

Task 4 之后重点检查：

- Direction Consistency Review
- Structure Review
- Sidebar Review
- List Experience Review

Task 5 之后重点检查：

- List Experience Review
- Interaction Stability Review
- High-Frequency Use Review

Task 6 之后重点检查：

- Visual Consistency Review
- Reviews / Sessions 是否同源
- 空状态与列表语言是否统一

Task 8 之后重点检查：

- AI Review
- Sheet and Popover Review
- Interaction Stability Review

Task 9 之前：

- 全量通过以上所有 Review

#### Final UI Acceptance

只有满足下面条件，UI 首版才算达标：

- 第一眼像成熟的 macOS 工具
- 第二眼能感觉出比系统默认更精致
- 默认进入论文列表，主任务非常清楚
- timer 自然融入，不吵
- AI 是助手，不是主角
- Papers / Reviews / Sessions / Settings 明显属于同一产品
- 没有页面像临时占位页
- 没有控件像网页组件直接搬进桌面

### Execution Order Adjustment

#### Why Reorder

原始任务顺序总体正确，但在当前 UI 方案已经确定后，需要把“产品壳子、视觉语言、共享组件”提前，否则后续每个页面都会各自长样，统一成本会很高。

已经确定的关键约束包括：

- 双栏 `NavigationSplitView`
- 默认进入论文列表
- `精致原生管理器` 方向
- `sheet / popover` 明确分工
- AI 只是辅助角色
- token 和共享组件必须先行

#### Recommended Phases

##### Phase 0: 工程与基础层

对应原 Task 1、Task 2、Task 3 的前半部分。

先做：

1. Xcode 工程骨架
2. `DataStore`
3. 数据模型
4. 旧数据迁移能力
5. 基础错误提示机制

目标：

- 工程能跑
- 数据可信
- 旧数据能导入
- 失败路径可见

##### Phase 1: UI 壳子与 Design Tokens

这层要提前。

先做：

1. `NavigationSplitView` 壳子
2. `SidebarView`
3. `DetailContainerView`
4. `AppColors / AppTypography / AppSpacing / AppRadius / AppMetrics`
5. `AppToolbar`
6. `PrimaryButton / SecondaryButton / SearchField / FilterChip / StatusTag / EmptyStateView`

原因：

- 决定后续所有页面的长相
- 不先做会导致每页各写一套
- 是精致原生感真正落地的起点

Phase 1 Review Gate：

- `Direction Consistency Review`
- `Structure Review`
- `Visual Consistency Review`
- `Native Feel Review`

##### Phase 2: Papers 默认页骨架

最早落成的完整业务页面。

先做：

1. `PaperPageView`
2. `PaperListView`
3. `PaperRowView`
4. 论文页 toolbar
5. 空状态
6. `selection / hover / running` 基本视觉反馈

目标：

- 打开 App 后就是目标中的主界面
- 论文列表成为产品中心
- row 节奏和视觉优先级被验证

Phase 2 Review Gate：

- `List Experience Review`
- `Sidebar Review`
- `High-Frequency Use Review`

##### Phase 3: Paper Editor 与 Timer

第一批深交互。

先做：

1. `PaperEditorSheet`
2. 表单 dirty state
3. `PaperTimerController`
4. `start / stop / recover` 规则
5. 自动生成 session
6. 顶部轻状态和 sidebar 底部状态联动

原因：

- 主页面壳子已经稳定
- row 视觉已落定
- 可以直接验证主使用路径

Phase 3 Review Gate：

- `Interaction Stability Review`
- `Sheet and Popover Review`
- `List Experience Review`

##### Phase 4: Reviews 与 Sessions

再扩展第二、第三个内容页。

先做：

1. `ReviewPageView`
2. `ReviewListView`
3. `ReviewEditorSheet`
4. `SessionPageView`
5. `SessionTimelineView`
6. `SessionRowView`

目标：

- 验证它们沿用了同一产品语言
- `Sessions` 真正像 activity timeline，而不是又一张表格

Phase 4 Review Gate：

- `Visual Consistency Review`
- `Reviews / Sessions` 是否同源
- 空状态与列表语言是否统一

##### Phase 5: Settings、备份、导入恢复

在主业务页稳定后补齐。

先做：

1. `SettingsView`
2. `BackupService`
3. `ImportExportPanel`
4. 恢复确认流
5. Keychain 配置页

原因：

- 对主视觉语言影响较小
- 适合在主业务页稳定后完成
- 但在 AI 前必须完成，因为它关系到数据安全和配置

Phase 5 Review Gate：

- `Interaction Stability Review`
- `Native Feel Review`
- Settings 是否克制，不像技术后台

##### Phase 6: AI Assist

AI 明确后置。

先做：

1. `AIAssistSheet`
2. `AIAssistSuggestionCard`
3. `AIService`
4. 表单态应用
5. 失败状态与重试

原因：

- AI 是辅助能力，不是产品骨架
- 结构、编辑、保存逻辑稳定后再接 AI 最安全
- 也更容易限制它的边界

Phase 6 Review Gate：

- `AI Review`
- `Sheet and Popover Review`
- `Interaction Stability Review`

##### Phase 7: 整体抛光与验收

最后统一收尾。

包括：

1. 全局 spacing 微调
2. token 统一校对
3. 键盘交互
4. toast / inline feedback 统一
5. `README / AGENTS / workflow` 文档更新
6. 全量 `build / test / manual QA`

Final Review Gate：

- `Direction Consistency Review`
- `Structure Review`
- `Visual Consistency Review`
- `List Experience Review`
- `Sidebar Review`
- `Sheet and Popover Review`
- `AI Review`
- `Interaction Stability Review`
- `Native Feel Review`
- `High-Frequency Use Review`

#### Mapping Back To Original Tasks

若仍保留原 Task 编号，映射关系如下：

- 原 `Task 1-3`：继续不动，属于基础设施阶段
- 原 `Task 4`：拆成 `Phase 1 + Phase 2`
- 原 `Task 5`：归入 `Phase 3`
- 原 `Task 6`：归入 `Phase 4`
- 原 `Task 7`：归入 `Phase 5`
- 原 `Task 8`：归入 `Phase 6`
- 原 `Task 9`：归入 `Phase 7`

核心调整：

- 把 UI 壳子、tokens、共享组件提前
- 把 Papers 默认页提前做完整感
- 把 AI 明确后置

#### Practical Recommendation

正式实现时，不建议再按旧 Task 4 直接把“主界面 + 论文区 + 计时器”一起推进。

更稳的顺序是：

1. 先做 App 壳子和 tokens
2. 再把 Papers 首页做对
3. 再接 editor 和 timer
4. 再扩 `Reviews / Sessions`
5. 最后再接 AI

### Implementation Consequences

这套 UI 决策会直接约束后续实现：

- Task 4 必须先落双栏结构，而不是自由探索多种窗口组织方式
- 论文列表必须是默认入口，不能先做 dashboard
- Reviews / Sessions 也要沿用同一套“轻侧栏 + 主内容列表”语言
- 后续 AI 面板必须作为辅助入口，不能抢占主界面中心
- 字体必须优先使用系统字族
- 正在计时状态必须采用“细强调条 + 数字高亮”的原生化反馈，而不是 pulse
- 页面级结构必须优先遵守上述 blueprint，不允许先用 dashboard 占位
- SwiftUI 顶层必须优先尝试 `NavigationSplitView`，不先用自拼壳子占位
- design token 必须先集中定义，再进入大规模页面样式实现
- 核心共享组件必须先抽象出一致视觉，再扩展到各页面
- 首版交互必须先遵守上述状态切换规则，再考虑额外快捷操作和动画润色
- 各阶段完成后必须按上述 UI review checklist 过关，才能进入下一阶段

## Global Constraints

- 平台仅支持 macOS，不考虑 Windows/Linux。
- 首版不要求继续兼容网页版实现细节；网页版只作为原型参考。
- 权威数据文件固定放在 `~/Library/Application Support/PaperTracker/data.json`。
- 保留 JSON 持久化，不引入数据库、SwiftData、Core Data。
- 首版不依赖第三方 Swift 包，优先用系统框架完成。
- API key 不写入 JSON，不写入源码，不写入 plist；统一放 Keychain。
- AI 只生成建议，不直接决定业务状态、计时逻辑或数据落盘。
- 所有写盘、导入、迁移、AI 请求失败都必须有用户可见提示，不能 `try?` 静默吞掉。
- 每个大任务结束前都要跑最小相关检查；共享行为改动后再跑一轮更完整检查。
- 每个大任务结束后都要经过一次 review gate，再进入下一任务。

---

## Execution Overlay: Canonical Fixes Before Implementation

本节是正式执行时的硬约束，覆盖下方旧任务中与它冲突的表述。

1. **当前机器的 Xcode license preflight 已解决。** 执行前仍先跑 `xcodebuild -showsdks`；只要能列出 SDK，就可以继续。
2. **执行顺序以 Phase 0-7 为准。** 下方 `Task 1-9` 只保留为任务内容来源；如果 Task 编号与 Phase 顺序冲突，按 Phase 顺序执行。
3. **文件命名统一。** 使用 `PaperEditorSheet.swift`、`ReviewEditorSheet.swift`、`SessionPageView.swift`、`SessionTimelineView.swift`、`SessionEditorSheet.swift`、`AIAssistSheet.swift`；不再使用 `PaperFormView.swift`、`ReviewFormView.swift`、`SessionListView.swift`、`SessionFormView.swift`、`AIAssistPanel.swift` 这些旧名。
4. **首版 ID 类型统一用 `String`。** 旧原型已有 `p_001` 这类字符串 id；新模型继续使用 `String` id，新增对象用 `UUID().uuidString`。不要在迁移阶段强制转成 `UUID`，避免破坏旧 sessions 的关联。
5. **`AGENTS.md` 默认不改。** 只有稳定、重复适用的协作规则变化时才改；实现状态、使用说明、架构事实写入 `README.md` 或 `docs/architecture/MACOS_WORKFLOW.md`。
6. **测试必须使用可注入路径。** `DataStore` 需要支持测试传入临时目录或 `dataURL`，不得在单元测试中直接读写真实 `~/Library/Application Support/PaperTracker/data.json`。
7. **每个任务的“Coverage”都要落成具体断言。** 测试至少断言输入、输出和失败路径；不能只验证“没有崩溃”。
8. **每个 Phase 使用独立 GitHub 分支和 draft PR。** 阶段分支命名为 `codex/phase-N-short-name`，例如 `codex/phase-0-foundation`。每个 Phase 验证通过后提交、push 当前阶段分支，并创建 draft PR；PR 合并后再从更新后的 `main` 创建下一阶段分支。默认不直接 push 到 `main`。

## File Structure

### New App Files

- Create: `PaperTracker.xcodeproj`
- Create: `PaperTracker/PaperTrackerApp.swift`
- Create: `PaperTracker/App/RootContentView.swift`
- Create: `PaperTracker/App/AppEnvironment.swift`
- Create: `PaperTracker/Models/AppData.swift`
- Create: `PaperTracker/Models/Paper.swift`
- Create: `PaperTracker/Models/Review.swift`
- Create: `PaperTracker/Models/Session.swift`
- Create: `PaperTracker/Models/AppSettings.swift`
- Create: `PaperTracker/Storage/DataStore.swift`
- Create: `PaperTracker/Storage/DataMigration.swift`
- Create: `PaperTracker/Storage/BackupService.swift`
- Create: `PaperTracker/Storage/ImportService.swift`
- Create: `PaperTracker/Security/KeychainService.swift`
- Create: `PaperTracker/AI/AIService.swift`
- Create: `PaperTracker/AI/AIModels.swift`
- Create: `PaperTracker/AI/AIPromptBuilder.swift`
- Create: `PaperTracker/Shared/UI/AppColors.swift`
- Create: `PaperTracker/Shared/UI/AppTypography.swift`
- Create: `PaperTracker/Shared/UI/AppSpacing.swift`
- Create: `PaperTracker/Shared/UI/AppRadius.swift`
- Create: `PaperTracker/Shared/UI/AppMetrics.swift`
- Create: `PaperTracker/Shared/UI/AppToolbar.swift`
- Create: `PaperTracker/Shared/UI/PrimaryButton.swift`
- Create: `PaperTracker/Shared/UI/SecondaryButton.swift`
- Create: `PaperTracker/Shared/UI/SearchField.swift`
- Create: `PaperTracker/Shared/UI/FilterChip.swift`
- Create: `PaperTracker/Shared/UI/StatusTag.swift`
- Create: `PaperTracker/Shared/UI/EmptyStateView.swift`
- Create: `PaperTracker/App/SidebarView.swift`
- Create: `PaperTracker/App/DetailContainerView.swift`
- Create: `PaperTracker/App/TopStatusStripView.swift`
- Create: `PaperTracker/Features/Papers/PaperPageView.swift`
- Create: `PaperTracker/Features/Papers/PaperListView.swift`
- Create: `PaperTracker/Features/Papers/PaperRowView.swift`
- Create: `PaperTracker/Features/Papers/PaperEditorSheet.swift`
- Create: `PaperTracker/Features/Papers/PaperQuickActionsPopover.swift`
- Create: `PaperTracker/Features/Papers/PaperTimerController.swift`
- Create: `PaperTracker/Features/Reviews/ReviewPageView.swift`
- Create: `PaperTracker/Features/Reviews/ReviewListView.swift`
- Create: `PaperTracker/Features/Reviews/ReviewRowView.swift`
- Create: `PaperTracker/Features/Reviews/ReviewEditorSheet.swift`
- Create: `PaperTracker/Features/Sessions/SessionPageView.swift`
- Create: `PaperTracker/Features/Sessions/SessionTimelineView.swift`
- Create: `PaperTracker/Features/Sessions/SessionRowView.swift`
- Create: `PaperTracker/Features/Sessions/SessionEditorSheet.swift`
- Create: `PaperTracker/Features/Settings/SettingsView.swift`
- Create: `PaperTracker/Features/ImportExport/ImportExportPanel.swift`
- Create: `PaperTracker/Features/AI/AIAssistSheet.swift`
- Create: `PaperTracker/Features/AI/AIAssistSuggestionCard.swift`
- Create: `PaperTracker/Shared/UI/AppToast.swift`
- Create: `PaperTracker/Shared/UI/ErrorAlertState.swift`
- Create: `PaperTracker/Shared/Utils/DateFormatting.swift`
- Create: `PaperTracker/Shared/Utils/CSVExporter.swift`

### New Test Files

- Create: `PaperTrackerTests/DataStoreTests.swift`
- Create: `PaperTrackerTests/DataMigrationTests.swift`
- Create: `PaperTrackerTests/PaperTimerControllerTests.swift`
- Create: `PaperTrackerTests/CSVExporterTests.swift`
- Create: `PaperTrackerTests/AIResponseParsingTests.swift`

### Existing Files To Keep

- Keep: `prototypes/web/tracker.html`
- Keep: `prototypes/web/data.json`
- Keep: `README.md`
- Keep: `docs/archive/PLANS.md`
- Keep: `docs/architecture/MACOS_WORKFLOW.md`

### Docs To Update

- Modify: `README.md`
- Modify: `docs/architecture/MACOS_WORKFLOW.md`
- Modify only if collaboration rules actually change: `AGENTS.md`

### Artifact Placement

- App 源码统一放 `PaperTracker/`
- 单元测试统一放 `PaperTrackerTests/`
- UI 测试统一放 `PaperTrackerUITests/`
- 架构、迁移、设计决策统一放 `docs/architecture/`
- 当前实现计划统一放 `docs/superpowers/plans/`
- 历史网页方案和废弃文档统一放 `docs/archive/`
- 暂未归档但需要提交的工作文档统一放 `docs/working/`
- 样例数据、导入样本、测试夹具统一放 `fixtures/`
- 历史网页原型统一放 `prototypes/web/`
- 如果出现本计划未单独规定的新文档，先放 `docs/working/`
- 如果出现本计划未单独规定的新数据文件，先放 `fixtures/`

---

## Execution Flow

执行顺序以本节为准：

1. **Phase 0 / Task 1-3:** 工程骨架、数据模型、`DataStore`、旧数据迁移、错误提示。
2. **Phase 1 / Task 4A:** `NavigationSplitView` 壳子、sidebar、detail container、design tokens、共享 UI 组件。
3. **Phase 2 / Task 4B:** Papers 默认页、paper row、搜索/筛选、空状态、基础 selection/hover/running 视觉。
4. **Phase 3 / Task 5:** `PaperEditorSheet`、dirty state、timer start/stop/recover、自动 session。
5. **Phase 4 / Task 6:** Reviews、Sessions、CSV 导出。
6. **Phase 5 / Task 7:** Settings、备份、恢复、导入恢复入口、Keychain。
7. **Phase 6 / Task 8:** AI Assist sheet、AIService、结构化建议、表单态应用。
8. **Phase 7 / Task 9:** 全量测试、手动验收、文档更新、最终 review。

每个阶段都要经过：

- 实现者自测
- 本地命令验证
- 差异 review
- 阶段提交
- push 阶段分支
- 创建 draft PR
- 阶段结论记录，包含 PR URL
- 通过后再进入下阶段

推荐阶段分支：

- `codex/phase-0-foundation`
- `codex/phase-1-app-shell`
- `codex/phase-2-papers-page`
- `codex/phase-3-editor-timer`
- `codex/phase-4-reviews-sessions`
- `codex/phase-5-settings-backup`
- `codex/phase-6-ai-assist`
- `codex/phase-7-release-polish`

---

### Task 1: 建立工程骨架与运行基线

**Files:**
- Create: `PaperTracker.xcodeproj`
- Create: `PaperTracker/PaperTrackerApp.swift`
- Create: `PaperTracker/App/RootContentView.swift`
- Create: `PaperTracker/App/AppEnvironment.swift`
- Modify: `README.md`

**Produces:**
- 可在 Xcode 打开的原生 macOS App 工程
- 空白但可运行的主窗口
- 一个集中注入 `DataStore` / `PaperTimerController` / `AIService` 的环境入口

- [ ] **Step 1: 创建 Xcode 工程**
  Run: `open -a Xcode .`
  Expected: 能在 Xcode 中创建 `App > macOS > SwiftUI` 工程，工程名 `PaperTracker`，关闭 sandbox capability。创建后立即关闭 Xcode，再用下面的 `xcodebuild` 命令验证；不要在 Xcode 里继续做不可追踪的实现改动。

- [ ] **Step 2: 建立源码目录骨架**
  Action: 在 Xcode 中按 `App / Models / Storage / Security / AI / Features / Shared` 分组整理源码，不把所有文件堆在根组下。
  Expected: 文件系统中存在同名目录，Xcode group 与文件系统目录一致。

- [ ] **Step 3: 写最小入口代码**
  Example:
  ```swift
  @main
  struct PaperTrackerApp: App {
      @StateObject private var environment = AppEnvironment.bootstrap()
      
      var body: some Scene {
          WindowGroup {
              RootContentView()
                  .environmentObject(environment.dataStore)
                  .environmentObject(environment.timerController)
                  .environmentObject(environment.aiService)
          }
      }
  }
  ```

- [ ] **Step 4: 运行工程确认能启动**
  Run: `xcodebuild -project PaperTracker.xcodeproj -scheme PaperTracker -destination 'platform=macOS' build`
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Review Gate 1**
  Review checklist:
  - 工程能否在另一台没有上下文的 Mac 上直接打开
  - 目录分层是否已经清楚
  - 当前是否有不必要的模板文件或 storyboard 残留
  - 是否已经明确“不启用 sandbox”这个首版决策

- [ ] **Step 6: 阶段提交**
  Run:
  ```bash
  git add PaperTracker.xcodeproj PaperTracker README.md
  git commit -m "chore: scaffold macOS app project"
  ```

---

### Task 2: 数据模型、持久化与失败可见化

**Files:**
- Create: `PaperTracker/Models/AppData.swift`
- Create: `PaperTracker/Models/Paper.swift`
- Create: `PaperTracker/Models/Review.swift`
- Create: `PaperTracker/Models/Session.swift`
- Create: `PaperTracker/Models/AppSettings.swift`
- Create: `PaperTracker/Storage/DataStore.swift`
- Create: `PaperTracker/Shared/UI/ErrorAlertState.swift`
- Create: `PaperTrackerTests/DataStoreTests.swift`

**Consumes:**
- `AppEnvironment`

**Produces:**
- App 独立使用的新 JSON 数据模型
- 固定的 `Application Support` 数据目录
- 读写失败时有明确错误状态

- [ ] **Step 1: 先写 `DataStore` 测试**
  Coverage:
  - `DataStore(dataURL: temporaryDirectory.appendingPathComponent("data.json"))` 初始化时创建父目录
  - 文件不存在时生成 `AppData(papers: [], reviews: [], sessions: [], settings: AppSettings())`
  - 写入 `{not json` 时 `load()` 设置 `activeError`，并且不覆盖坏文件
  - 保存包含一篇 paper、一条 review、一条 session 的数据后，重新初始化 `DataStore` 能读回相同 `id/title/status/durationSeconds`

- [ ] **Step 2: 跑测试确认当前失败**
  Run: `xcodebuild test -project PaperTracker.xcodeproj -scheme PaperTracker -destination 'platform=macOS' -only-testing:PaperTrackerTests/DataStoreTests`
  Expected: 至少有“类型不存在”或“方法未实现”的失败

- [ ] **Step 3: 定义新模型**
  Model constraints:
  - `Paper`: `id: String`, `title`, `status`, `journal`, `deadline`, `totalSeconds`, `isRunning`, `sessionStart`, `createdAt`, `updatedAt`, `note`
  - `Review`: `id: String`, `journal`, `deadline`, `status`, `note`, `createdAt`, `updatedAt`
  - `Session`: `id: String`, `type`, `targetId: String`, `targetName`, `startedAt`, `endedAt`, `durationSeconds`, `note`, `source`
  - `AppSettings`: `lastBackupAt`, `hasImportedLegacyData`, `preferredExportDirectoryBookmark`
  - 新建对象的 `id` 用 `UUID().uuidString` 生成，但类型保持 `String`

- [ ] **Step 4: 实现 `DataStore`**
  Required behavior:
  - 初始化时创建目录
  - 从 `Application Support/PaperTracker/data.json` 读取
  - 写入时用 `.atomic`
  - 失败时写入 `@Published var activeError: ErrorAlertState?`
  - 成功保存后更新时间戳

- [ ] **Step 5: 把错误状态接到根视图**
  Required UI:
  - 读失败：阻止继续编辑，显示“数据文件无法读取”
  - 写失败：保留内存态，但明确提示“尚未保存到磁盘”

- [ ] **Step 6: 再跑数据层测试**
  Run: `xcodebuild test -project PaperTracker.xcodeproj -scheme PaperTracker -destination 'platform=macOS' -only-testing:PaperTrackerTests/DataStoreTests`
  Expected: `Executed ... tests, with 0 failures`

- [ ] **Step 7: Review Gate 2**
  Review checklist:
  - 是否完全去掉 `try?` 静默吞错
  - 是否把“文件失败”和“业务校验失败”分开
  - JSON 结构是否已经足够支撑后续 AI / 备份 / 日志
  - 数据目录是否只出现一处真源定义

- [ ] **Step 8: 阶段提交**
  Run:
  ```bash
  git add PaperTracker/Models PaperTracker/Storage PaperTracker/Shared/UI PaperTrackerTests
  git commit -m "feat: add app data models and persistent store"
  ```

---

### Task 3: 旧数据导入与迁移

**Files:**
- Create: `PaperTracker/Storage/DataMigration.swift`
- Create: `PaperTracker/Storage/ImportService.swift`
- Create: `PaperTrackerTests/DataMigrationTests.swift`

**Consumes:**
- `AppData`
- `DataStore`

**Produces:**
- 从当前仓库 `prototypes/web/data.json` 或用户选择的旧 JSON 导入数据
- 首次导入后写入新模型

- [ ] **Step 1: 写迁移测试**
  Coverage:
  - 导入当前原型 `prototypes/web/data.json` 后，第一篇 paper 的 `id == "p_001"`、`title == "中国引文偏见"`、`status == .submitted`
  - 原型中的 `sessionStart` 数字时间戳按毫秒 Unix 时间转成 `Date`；`null` 保持为 `nil`
  - 缺少 `note`、`updatedAt` 时自动补默认值，并产生 warning
  - 非法中文状态值不静默改成默认值；该条进入 warnings，迁移结果保留原始 title 供用户识别

- [ ] **Step 2: 实现 `DataMigration`**
  Required interfaces:
  ```swift
  struct MigrationResult {
      let data: AppData
      let warnings: [String]
  }

  enum DataMigration {
      static func migrateLegacyJSON(_ data: Data) throws -> MigrationResult
  }
  ```

- [ ] **Step 3: 实现导入流程**
  Behavior:
  - `NSOpenPanel` 选旧 JSON
  - 预览导入条目数
  - 展示 warnings
  - 当前库为空时允许直接导入
  - 当前库非空时只允许“合并”或“取消”，覆盖恢复只能走 Task 7 的恢复流程

- [ ] **Step 4: 跑迁移测试**
  Run: `xcodebuild test -project PaperTracker.xcodeproj -scheme PaperTracker -destination 'platform=macOS' -only-testing:PaperTrackerTests/DataMigrationTests`
  Expected: `0 failures`

- [ ] **Step 5: 手动导入现有仓库 `prototypes/web/data.json`**
  Expected:
  - 论文条目出现在 App 中
  - 无崩溃
  - 如果有字段差异，warnings 可见

- [ ] **Step 6: Review Gate 3**
  Review checklist:
  - 迁移逻辑是否只存在一处
  - 导入是否会意外覆盖现有正式数据
  - warning 是否可理解，而不是程序员术语

- [ ] **Step 7: 阶段提交**
  Run:
  ```bash
  git add PaperTracker/Storage PaperTrackerTests
  git commit -m "feat: add legacy data import and migration"
  ```

---

### Task 4A-4B: UI 壳子、Design Tokens 与 Papers 默认页

**Files:**
- Modify: `PaperTracker/App/RootContentView.swift`
- Create: `PaperTracker/App/SidebarView.swift`
- Create: `PaperTracker/App/DetailContainerView.swift`
- Create: `PaperTracker/App/TopStatusStripView.swift`
- Create: `PaperTracker/Shared/UI/AppColors.swift`
- Create: `PaperTracker/Shared/UI/AppTypography.swift`
- Create: `PaperTracker/Shared/UI/AppSpacing.swift`
- Create: `PaperTracker/Shared/UI/AppRadius.swift`
- Create: `PaperTracker/Shared/UI/AppMetrics.swift`
- Create: `PaperTracker/Shared/UI/AppToolbar.swift`
- Create: `PaperTracker/Shared/UI/PrimaryButton.swift`
- Create: `PaperTracker/Shared/UI/SecondaryButton.swift`
- Create: `PaperTracker/Shared/UI/SearchField.swift`
- Create: `PaperTracker/Shared/UI/FilterChip.swift`
- Create: `PaperTracker/Shared/UI/StatusTag.swift`
- Create: `PaperTracker/Shared/UI/EmptyStateView.swift`
- Create: `PaperTracker/Features/Papers/PaperPageView.swift`
- Create: `PaperTracker/Features/Papers/PaperListView.swift`
- Create: `PaperTracker/Features/Papers/PaperRowView.swift`
- Create: `PaperTracker/Shared/Utils/DateFormatting.swift`

**Consumes:**
- `DataStore`

**Produces:**
- 双栏 `NavigationSplitView` 壳子
- 统一 design tokens 和共享 UI 组件
- Papers 默认页、论文列表、状态样式、截止日高亮

- [ ] **Step 1: 先做静态布局**
  Required sections:
  - `NavigationSplitView` 双栏
  - 左侧轻量导航栏 `SidebarView`
  - 右侧主内容区
  - 右侧默认论文列表页
  - 顶部工具栏

- [ ] **Step 2: 先落 design tokens 和共享组件**
  Required files:
  - `AppColors / AppTypography / AppSpacing / AppRadius / AppMetrics`
  - `AppToolbar / PrimaryButton / SecondaryButton / SearchField / FilterChip / StatusTag / EmptyStateView`
  Check:
  - View 里不得散落新的 hex 颜色、重复字号、重复圆角常量
  - `+ New Paper` 使用 `PrimaryButton`
  - `AI Assist` 使用 `SecondaryButton`

- [ ] **Step 3: 先验证结构符合已定 UI 基线**
  Check:
  - 是否是双栏，不是三栏
  - 默认页是否是论文列表，不是 dashboard
  - 编辑入口是否预留给 `PaperEditorSheet` / `PaperQuickActionsPopover`
  - 左栏是否包含 `All Papers / Writing / Submitted / R&R / Accepted / Published / Reviews / Sessions / Today`

- [ ] **Step 4: 再接论文列表**
  Required UI:
  - 标题
  - 状态
  - 期刊
  - 截止日
  - 累计时间
  - 操作列
  - 真空状态、搜索空状态、筛选空状态三类文案不同

- [ ] **Step 5: 本地运行做视觉校对**
  Check:
  - 是否有 Things/Craft 式精致原生感，而不是完全系统默认
  - 左栏选中态是否克制、清楚
  - 右栏是否首先呈现“论文管理器”而非展示页
  - 标题字体、正文、等宽计时字体是否符合既定风格
  - 列宽是否在常见 Mac 窗口尺寸下可读

- [ ] **Step 6: Review Gate 4**
  Review checklist:
  - 首版 UI 有没有过早追求复杂组件
  - 双栏骨架是否被坚持执行
  - 默认论文列表入口是否被坚持执行
  - 论文区是否已经足够可用
  - 现有字段是否支持后面计时和 AI 辅助填写

- [ ] **Step 7: 阶段提交**
  Run:
  ```bash
  git add PaperTracker/App PaperTracker/Features/Papers PaperTracker/Shared/UI PaperTracker/Shared/Utils
  git commit -m "feat: add app shell and papers page"
  ```

---

### Task 5: Paper Editor、计时器控制器与日志自动生成

**Files:**
- Create: `PaperTracker/Features/Papers/PaperEditorSheet.swift`
- Create: `PaperTracker/Features/Papers/PaperQuickActionsPopover.swift`
- Create: `PaperTracker/Features/Papers/PaperTimerController.swift`
- Modify: `PaperTracker/Features/Papers/PaperListView.swift`
- Modify: `PaperTracker/Storage/DataStore.swift`
- Create: `PaperTrackerTests/PaperTimerControllerTests.swift`

**Consumes:**
- `DataStore`

**Produces:**
- 论文新建、编辑、删除确认、表单校验和 dirty state
- 单一运行中的论文计时器
- 停止计时时自动生成 session
- 崩溃恢复或重启恢复

- [ ] **Step 1: 实现 `PaperEditorSheet`**
  Required behavior:
  - 新建
  - 编辑
  - 删除前确认，确认文案包含论文标题
  - 标题必填，空标题就地显示错误
  - 截止日为空时允许保存
  - 修改任意字段后 `dirty == true`；关闭 sheet 时提示 `Discard Changes / Keep Editing`

- [ ] **Step 2: 写计时测试**
  Coverage:
  - 启动一篇论文时自动停止另一篇
  - 停止后累计秒数增加，例如从 `totalSeconds = 10`、运行 90 秒后变成 `100`
  - 停止后自动生成一条 `Session(type: .paper, targetId: paper.id, durationSeconds: elapsed)`
  - 重启恢复时能补算运行中的秒数，并保留 `isRunning == true`

- [ ] **Step 3: 实现控制器**
  Required interface:
  ```swift
  final class PaperTimerController: ObservableObject {
      func start(paperID: String)
      func stop(paperID: String)
      func recoverIfNeeded()
      func displayedSeconds(for paper: Paper, now: Date) -> Int
  }
  ```

- [ ] **Step 4: 把 UI 刷新限制在最小范围**
  Rule:
  - 不做全局粗暴每秒重绘整个窗口
  - 只让运行中的计时显示刷新

- [ ] **Step 5: 跑计时测试**
  Run: `xcodebuild test -project PaperTracker.xcodeproj -scheme PaperTracker -destination 'platform=macOS' -only-testing:PaperTrackerTests/PaperTimerControllerTests`
  Expected: `0 failures`

- [ ] **Step 6: 手动验证关键路径**
  Script:
  - 新建两篇论文
  - 启动 A
  - 再启动 B，确认 A 自动停
  - 强制退出 App 后重开，确认恢复累计时间

- [ ] **Step 7: Review Gate 5**
  Review checklist:
  - 表单 dirty protection 是否可靠
  - 计时逻辑是否只在控制器里，不散落在 View
  - 是否有重复写盘
  - 是否会在频繁 tick 时造成性能问题

- [ ] **Step 8: 阶段提交**
  Run:
  ```bash
  git add PaperTracker/Features/Papers PaperTracker/Storage PaperTrackerTests
  git commit -m "feat: add paper editor timer and session logging"
  ```

---

### Task 6: 审稿区、日志区与 CSV 导出

**Files:**
- Create: `PaperTracker/Features/Reviews/ReviewPageView.swift`
- Create: `PaperTracker/Features/Reviews/ReviewListView.swift`
- Create: `PaperTracker/Features/Reviews/ReviewRowView.swift`
- Create: `PaperTracker/Features/Reviews/ReviewEditorSheet.swift`
- Create: `PaperTracker/Features/Sessions/SessionPageView.swift`
- Create: `PaperTracker/Features/Sessions/SessionTimelineView.swift`
- Create: `PaperTracker/Features/Sessions/SessionRowView.swift`
- Create: `PaperTracker/Features/Sessions/SessionEditorSheet.swift`
- Create: `PaperTracker/Shared/Utils/CSVExporter.swift`
- Create: `PaperTrackerTests/CSVExporterTests.swift`

**Consumes:**
- `DataStore`

**Produces:**
- 审稿 CRUD
- 手动日志
- CSV 导出

- [ ] **Step 1: 写 CSV 测试**
  Coverage:
  - papers 表头精确等于 `title,status,journal,deadline,total_seconds,total_hours,note`
  - reviews 表头精确等于 `journal,deadline,status,note`
  - sessions 表头精确等于 `type,target,start,end,duration_seconds,duration_minutes,note`
  - 字段值 `A, "B"\nC` 导出为合法 RFC 4180 风格 CSV 字段

- [ ] **Step 2: 实现审稿与日志视图**
  Required behavior:
  - 审稿增删改
  - 手动添加日志
  - 编辑日志备注
  - 删除日志前确认
  - Sessions 使用按日期倒序分组的 timeline，不做硬表格

- [ ] **Step 3: 实现 `CSVExporter` 和导出面板**
  Behavior:
  - 用户选择导出目录
  - 一次导出三个 CSV 文件
  - 成功后提示文件夹位置

- [ ] **Step 4: 跑导出测试**
  Run: `xcodebuild test -project PaperTracker.xcodeproj -scheme PaperTracker -destination 'platform=macOS' -only-testing:PaperTrackerTests/CSVExporterTests`
  Expected: `0 failures`

- [ ] **Step 5: Review Gate 6**
  Review checklist:
  - 审稿和日志的界面模式是否与论文区一致
  - 是否沿用了同一套双栏 + 主列表语言，而不是长成另一种产品
  - 导出的字段名是否稳定、易读
  - 删除操作是否都带确认

- [ ] **Step 6: 阶段提交**
  Run:
  ```bash
  git add PaperTracker/Features/Reviews PaperTracker/Features/Sessions PaperTracker/Shared/Utils PaperTrackerTests
  git commit -m "feat: add reviews sessions and csv export"
  ```

---

### Task 7: 备份、恢复、设置与 Keychain

**Files:**
- Create: `PaperTracker/Storage/BackupService.swift`
- Create: `PaperTracker/Security/KeychainService.swift`
- Create: `PaperTracker/Features/Settings/SettingsView.swift`
- Create: `PaperTracker/Features/ImportExport/ImportExportPanel.swift`
- Modify: `PaperTracker/App/RootContentView.swift`

**Consumes:**
- `DataStore`

**Produces:**
- 完整 JSON 备份
- JSON 恢复
- API key 设置页

- [ ] **Step 1: 实现完整备份**
  Behavior:
  - `NSSavePanel` 选择位置
  - 文件名默认 `papertracker-backup-YYYY-MM-DD.json`
  - 保存成功后记录 `lastBackupAt`

- [ ] **Step 2: 实现恢复流程**
  Behavior:
  - 读取备份 JSON
  - 预览摘要
  - 二次确认覆盖当前库

- [ ] **Step 3: 实现 Keychain 服务**
  Required interface:
  ```swift
  protocol KeychainService {
      func saveAPIKey(_ value: String) throws
      func loadAPIKey() throws -> String?
      func deleteAPIKey() throws
  }
  ```

- [ ] **Step 4: 设置页接入 Keychain**
  Required fields:
  - Base URL
  - API Key
  - Model Name
  - 测试连接按钮

- [ ] **Step 5: 手动验证**
  Check:
  - 关闭 App 再打开，API key 仍可读取
  - 删除 key 后不能继续发 AI 请求

- [ ] **Step 6: Review Gate 7**
  Review checklist:
  - 是否把敏感信息留在 JSON 或 UserDefaults
  - 备份/恢复文案是否足够明确，避免误覆盖
  - 设置页是否暴露了不必要的高级配置

- [ ] **Step 7: 阶段提交**
  Run:
  ```bash
  git add PaperTracker/Storage PaperTracker/Security PaperTracker/Features/Settings PaperTracker/Features/ImportExport PaperTracker/App
  git commit -m "feat: add backup restore and keychain settings"
  ```

---

### Task 8: AI 辅助填写

**Files:**
- Create: `PaperTracker/AI/AIService.swift`
- Create: `PaperTracker/AI/AIModels.swift`
- Create: `PaperTracker/AI/AIPromptBuilder.swift`
- Create: `PaperTracker/Features/AI/AIAssistSheet.swift`
- Create: `PaperTracker/Features/AI/AIAssistSuggestionCard.swift`
- Modify: `PaperTracker/Features/Papers/PaperEditorSheet.swift`
- Modify: `PaperTracker/Features/Reviews/ReviewEditorSheet.swift`
- Create: `PaperTrackerTests/AIResponseParsingTests.swift`

**Consumes:**
- `KeychainService`
- `DataStore`

**Produces:**
- 在论文表单、审稿表单中调用 AI 生成填写建议
- 用户确认后再写入字段

- [ ] **Step 1: 先定义 AI 输出契约**
  Required response shape:
  ```json
  {
    "title": "",
    "journal": "",
    "status": "",
    "deadline": "",
    "note": "",
    "confidence": 0.0
  }
  ```

- [ ] **Step 2: 写解析测试**
  Coverage:
  - 正常 JSON 返回可解析为 `AISuggestion`
  - 返回 ```json fenced block``` 时可以剥离代码围栏再解析
  - 多余说明文字无法安全剥离时返回 `.invalidResponse`，不写入表单
  - 缺少 `title` / `journal` / `status` / `deadline` / `note` 中任一字段时给出友好错误
  - 非法日期不会直接写入模型，UI 显示该字段不可应用

- [ ] **Step 3: 实现 `AIService`**
  Behavior:
  - 读取 Base URL / Model / API key
  - 组装 prompt
  - 请求超时
  - 解析响应
  - 输出结构化建议

- [ ] **Step 4: 实现 AI 面板**
  Required UX:
  - 输入原始文本
  - 点击“生成建议”
  - 预览建议字段
  - 单字段勾选应用
  - 确认后写回表单

- [ ] **Step 5: 跑解析测试**
  Run: `xcodebuild test -project PaperTracker.xcodeproj -scheme PaperTracker -destination 'platform=macOS' -only-testing:PaperTrackerTests/AIResponseParsingTests`
  Expected: `0 failures`

- [ ] **Step 6: 手动验证**
  Script:
  - 配置测试 API key
  - 粘贴一段论文摘要
  - 生成建议
  - 修改其中一个字段后再应用
  - 确认不会直接落盘，必须点保存表单才生效

- [ ] **Step 7: Review Gate 8**
  Review checklist:
  - AI 是否只提供建议而不是直接改数据
  - AI 面板是否仍然是辅助入口，而不是抢占主界面中心
  - 网络失败、限流、无 key、返回脏 JSON 时是否都能提示
  - prompt 是否泄露本地路径、无关数据或敏感内容

- [ ] **Step 8: 阶段提交**
  Run:
  ```bash
  git add PaperTracker/AI PaperTracker/Features/AI PaperTracker/Features/Papers PaperTracker/Features/Reviews PaperTrackerTests
  git commit -m "feat: add ai-assisted form filling"
  ```

---

### Task 9: 集成验证、文档与最终 review

**Files:**
- Modify: `README.md`
- Modify: `docs/architecture/MACOS_WORKFLOW.md`

**Consumes:**
- 全部前置任务产物

**Produces:**
- 可交付首版
- 文档与实际实现一致

- [ ] **Step 1: 跑完整测试**
  Run: `xcodebuild test -project PaperTracker.xcodeproj -scheme PaperTracker -destination 'platform=macOS'`
  Expected: `** TEST SUCCEEDED **`

- [ ] **Step 2: 跑完整构建**
  Run: `xcodebuild -project PaperTracker.xcodeproj -scheme PaperTracker -destination 'platform=macOS' build`
  Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: 做一轮手动验收**
  Checklist:
  - 新建论文
  - 启动/停止计时
  - 自动写日志
  - 新建审稿
  - 导出 CSV
  - 备份 JSON
  - 导入旧数据
  - 配置 API key
  - AI 生成建议并手动确认写入

- [ ] **Step 4: 更新文档**
  Required updates:
  - `README.md` 改成 App 使用说明
  - `docs/architecture/MACOS_WORKFLOW.md` 改成“已实现架构/后续路线”，移除过时状态
  - 仅当协作规则或文件放置规则实际变化时，另行提出 `AGENTS.md` diff 并等待确认

- [ ] **Step 5: Final Review Gate**
  Review checklist:
  - 是否还有静默失败路径
  - 是否还有模型直接操控 UI 状态的混乱边界
  - 最终产品是否仍保持“精致原生管理器”方向
  - 主界面是否仍是双栏，默认仍是论文列表
  - 是否有未清理的调试代码、示例 key、测试 URL
  - 文档是否仍把网页版当主入口

- [ ] **Step 6: 最终提交**
  Run:
  ```bash
  git add README.md docs/architecture/MACOS_WORKFLOW.md
  git commit -m "docs: update app documentation for macOS release"
  ```

---

## Review Rhythm

整个执行过程里的 review 采用固定节奏：

1. **任务内自检**
   - 先看测试是否覆盖了这一步真正改变的行为
   - 再看代码有没有把状态和视图耦死

2. **任务完成 review gate**
   - 对照本计划里的 review checklist
   - 看 diff 是否只触及当前任务范围
   - 决定是否进入下一任务

3. **跨任务集成 review**
   - 在 Task 5、Task 8、Task 9 后做
   - 重点查：状态一致性、写盘时机、错误提示、AI 边界

4. **最终验收 review**
   - 从用户视角走完整路径
   - 从维护者视角看目录、文档、测试、错误处理

---

## Risks To Watch

- 过早引入太多抽象，导致首版难落地。
- 计时器刷新写得太粗，造成整个界面每秒重绘。
- 导入旧数据时 silently 修正过多字段，用户却不知道。
- AI 响应解析不严格，导致脏数据写进表单。
- 备份和恢复文案不清，误操作覆盖正式数据。

---

## Done Criteria

满足下面条件才算首版完成：

- App 可以在 macOS 本地独立运行，不依赖浏览器。
- `Application Support` 下存在稳定可读写的权威 JSON。
- 论文、审稿、日志、计时、备份、旧数据导入都能用。
- AI 辅助填写可用，但失败不会污染现有数据。
- 所有关键失败路径都有用户可见反馈。
- `xcodebuild build` 和 `xcodebuild test` 都通过。
- 文档已更新，不再把网页版描述为主形态。
