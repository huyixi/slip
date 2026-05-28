# MVP：macOS 原生快速记录收件箱

## 1. 产品定位

这是一个 macOS 原生的临时纯文本记录收件箱。

用户可以在任意 macOS 场景下，通过全局快捷键快速记录一段纯文本 note。保存后的 note 会进入本地收件箱，并以 Apple Notes-like 的柔和卡片墙形式展示。

MVP 阶段只关注：

```text
快速捕获
本地保存
卡片墙回看
复制内容
删除内容
```

它不是完整笔记系统，也不承担知识管理职责。

## 2. 产品原则

```text
Capture first, review only.
```

中文：

```text
优先捕获，只做回看。
```

第一版不做编辑、不做分类、不做搜索逻辑、不做同步、不做 AI。

用户记录之后，如果内容有用，可以复制到其他地方；如果无用，可以删除。

## 3. 核心用户路径

```text
Cmd + Option + N
↓
打开快速记录浮窗
↓
输入纯文本
↓
Cmd + Enter 保存
↓
窗口自动关闭
↓
Note 出现在主窗口卡片墙中
↓
用户可以复制或删除
```

## 4. MVP 功能范围

### In Scope

```text
- macOS 菜单栏 App
- 全局快捷键 Cmd + Option + N
- 快速记录浮窗
- 纯文本输入
- Cmd + Enter 保存
- Esc 关闭
- 本地保存 note
- 主窗口卡片墙
- 顶部 Search UI 占位
- Note content card
- 复制 note content
- 删除 note
```

### Out of Scope

```text
- 搜索逻辑
- 编辑 note
- 详情面板
- 编辑弹窗
- 图片 note
- 文件 note
- 链接预览
- Markdown 预览
- 富文本
- Sidebar
- Folder
- Tags
- Archive
- Pin
- Trash
- Undo
- AI
- iCloud / 云同步
- 多设备同步
```

## 5. App 结构

```text
NoteQuick
├── Menu Bar
│   ├── New Note
│   ├── Open Notes
│   └── Quit
│
├── Quick Capture Panel
│   └── Plain Text Input
│
└── Main Window
    ├── Search UI Placeholder
    └── Note Content Card Wall
```

## 6. 快速记录浮窗

快速记录浮窗是 MVP 中唯一的写入入口。

### 触发方式

```text
- Cmd + Option + N
- Menu Bar → New Note
```

### 行为

```text
- 屏幕中央弹出
- 自动聚焦文本输入框
- 只支持纯文本输入
- Cmd + Enter 保存
- Esc 关闭，不保存
- 空内容不可保存
- 保存后窗口自动关闭
- 新 note 自动出现在主窗口卡片墙中
```

### 不支持

```text
- 标题输入
- 标签选择
- 文件夹选择
- Markdown 工具栏
- 富文本格式
- 图片粘贴
- 文件附件
```

## 7. 主窗口

主窗口是一个只读 note 卡片墙。

它只包含：

```text
1. 顶部 Search 输入框
2. 下方 note content card grid
```

Search 在 MVP 阶段只是 UI 占位，不实现真实搜索。

### 主窗口规则

```text
- 无 sidebar
- 无文件夹树
- 无标签面板
- 无详情面板
- 无编辑区域
- 无复杂 toolbar
- 无分类导航
```

### 主窗口目的

```text
让用户快速回看临时捕获的 note，并进行轻量操作：复制或删除。
```

## 8. Note Card

每张 card 展示一条纯文本 note。

### 展示内容

```text
- note content preview
- created time
```

### 支持操作

```text
- Copy：复制完整 note content
- Delete：删除 note
```

### 不支持操作

```text
- 编辑
- 展开
- 详情查看
- 标签
- 文件夹
- 颜色标记
- Pin
- Archive
```

### 长文本处理

```text
- card 只展示前 6–8 行
- 超出内容截断
- 不支持展开
- Copy 时复制完整 note content
```

## 9. UI 风格

视觉风格采用：

```text
Apple Notes-like
```

关键词：

```text
- 系统原生
- 柔和
- 低密度
- 干净
- 低视觉噪音
- 轻边框
- 弱阴影
- 大留白
- 内容优先
```

界面不应该像：

```text
- Dashboard
- Database
- Kanban
- 重型素材管理器
- 命令启动器
```

## 10. 主窗口布局建议

```text
Main Window
- 默认尺寸：900 × 640
- 最小尺寸：640 × 420
- 顶部 Search 区高度：64
- 内容区 padding：24
- 卡片间距：16–20
- 卡片宽度：220–280
- 响应式列数：根据窗口宽度自动变化
```

结构示意：

```text
┌──────────────────────────────────────────────┐
│  Search                                      │
├──────────────────────────────────────────────┤
│                                              │
│   ┌────────────────┐  ┌────────────────┐     │
│   │ 今天想到一个... │  │ RSS reader...  │     │
│   │                │  │                │     │
│   │ 14:32          │  │ Yesterday      │     │
│   └────────────────┘  └────────────────┘     │
│                                              │
│   ┌────────────────┐  ┌────────────────┐     │
│   │ 需要整理...     │  │ Cmd+Opt+N...   │     │
│   └────────────────┘  └────────────────┘     │
│                                              │
└──────────────────────────────────────────────┘
```

## 11. 快速记录浮窗布局建议

```text
Quick Capture Panel
- 默认尺寸：520 × 220
- 居中显示
- 圆角窗口
- 自动聚焦
- 浅色背景
- 轻阴影
- 不显示复杂 toolbar
```

结构示意：

```text
┌──────────────────────────────────────┐
│                                      │
│  Write a note...                     │
│                                      │
│                                      │
│  ⌘↩ Save                 Esc Close   │
└──────────────────────────────────────┘
```

## 12. 数据模型

第一版保持极简。

```swift
Note {
  id: UUID
  content: String
  createdAt: Date
  updatedAt: Date
}
```

暂时不加入：

```text
status
tags
folder
pinned
color
archived
deletedAt
source
```

## 13. 技术栈建议

尽可能使用 macOS 原生技术栈：

```text
- Swift
- SwiftUI
- AppKit
- NSPanel / NSWindow
- MenuBarExtra
- SwiftData 或本地 JSON / SQLite
- SMAppService 后续支持开机启动
```

推荐组合：

```text
Swift + SwiftUI + AppKit NSPanel + SwiftData + MenuBarExtra
```

职责划分：

```text
SwiftUI：负责主窗口、卡片墙、基础 UI
AppKit：负责快速浮窗、窗口层级、焦点、全局快捷键相关能力
SwiftData：负责本地 note 存储
MenuBarExtra：负责菜单栏入口
```

## 14. 验收标准

| 场景                   | 预期                             |
| -------------------- | ------------------------------ |
| App 在后台              | 按 `Cmd + Option + N` 能打开快速记录浮窗 |
| 浮窗打开后                | 文本输入框自动聚焦                      |
| 输入内容后按 `Cmd + Enter` | note 保存到本地，浮窗关闭                |
| 输入为空按保存              | 不创建 note                       |
| 按 `Esc`              | 关闭浮窗，不保存                       |
| 打开主窗口                | 可以看到所有 note card               |
| 长文本 note             | card 只展示预览                     |
| 点击 Copy              | 复制完整 note content              |
| 点击 Delete            | 直接删除 note                      |
| 顶部 Search            | 只展示 UI，不过滤内容                   |
| 重启 App               | 已保存 note 仍然存在                  |

## 15. MVP 一句话版本

```text
一个 macOS 原生快速记录收件箱：用户按 Cmd + Option + N 快速记录纯文本 note，保存到本地，并在 Apple Notes-like 的极简卡片墙中回看、复制或删除。
```

