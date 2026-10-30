import CoreGraphics

enum ReadingAction: String, CaseIterable {
    case previousPage, nextPage, previousChapter, nextChapter
    case chapterStart, chapterEnd, up, down, confirm, cancel
    case bookmark, contents, search, fullScreen, bookmarks, notes, resetFont
    case smallerFont, largerFont, pause

    var title: String {
        switch self {
        case .previousPage: return "上一页"
        case .nextPage: return "下一页"
        case .previousChapter: return "上一章"
        case .nextChapter: return "下一章"
        case .chapterStart: return "本章开头"
        case .chapterEnd: return "本章结尾"
        case .up: return "向上选择 / 上一页"
        case .down: return "向下选择 / 下一页"
        case .confirm: return "确认 / 执行搜索"
        case .cancel: return "取消 / 关闭弹出层"
        case .bookmark: return "添加书签"
        case .contents: return "目录"
        case .search: return "书内搜索"
        case .fullScreen: return "切换全屏"
        case .bookmarks: return "书签列表"
        case .notes: return "笔记与高亮"
        case .resetFont: return "恢复默认字号"
        case .smallerFont: return "缩小字号"
        case .largerFont: return "放大字号"
        case .pause: return "暂停 / 恢复手柄映射"
        }
    }

    var shortcut: (key: CGKeyCode, flags: CGEventFlags)? {
        switch self {
        case .previousPage: return (123, [])
        case .nextPage: return (124, [])
        case .previousChapter: return (123, .maskAlternate)
        case .nextChapter: return (124, .maskAlternate)
        case .chapterStart: return (126, .maskAlternate)
        case .chapterEnd: return (125, .maskAlternate)
        case .up: return (126, [])
        case .down: return (125, [])
        case .confirm: return (36, [])
        case .cancel: return (53, [])
        case .bookmark: return (2, .maskCommand)
        case .contents: return (17, .maskCommand)
        case .search: return (3, .maskCommand)
        case .fullScreen: return (3, [.maskControl, .maskCommand])
        case .bookmarks: return (2, [.maskShift, .maskCommand])
        case .notes: return (45, [.maskShift, .maskCommand])
        case .resetFont: return (29, .maskCommand)
        case .smallerFont: return (27, .maskCommand)
        case .largerFont: return (24, [.maskShift, .maskCommand])
        case .pause: return nil
        }
    }

    func reversed(_ reverse: Bool) -> ReadingAction {
        guard reverse else { return self }
        switch self {
        case .previousPage: return .nextPage
        case .nextPage: return .previousPage
        case .previousChapter: return .nextChapter
        case .nextChapter: return .previousChapter
        default: return self
        }
    }

    static let guide: [(String, String)] = [
        ("L1 / R1", "上一页 / 下一页 · 最常用，食指轻按"),
        ("L2 / R2 深按", "上一章 / 下一章 · 回弹后才能再次触发"),
        ("左、右摇杆 ← →", "上一页 / 下一页 · 回中后再推"),
        ("左摇杆 ↑ ↓", "本章开头 / 本章结尾"),
        ("右摇杆 ↑ ↓", "放大 / 缩小字号"),
        ("方向键 ← →", "上一页 / 下一页；菜单内左右导航"),
        ("方向键 ↑ ↓", "菜单内上下选择；正文中上一页 / 下一页"),
        ("×", "确认选择 / 执行搜索（Return）"),
        ("○", "取消 / 关闭弹出层（Esc，视图书界面而定）"),
        ("□", "添加当前页书签"),
        ("△", "打开目录"),
        ("SHARE", "打开书内搜索；搜索词仍需键盘输入"),
        ("OPTIONS", "切换全屏"),
        ("触摸板按下", "显示书签列表"),
        ("L3（左摇杆按下）", "显示笔记与高亮"),
        ("R3（右摇杆按下）", "恢复默认字号"),
        ("PS", "暂停 / 恢复映射 · 仅图书前台；可能被系统拦截")
    ]
}

// First sample establishes a baseline. A button held across app changes never fires.
struct ButtonGate {
    private var previous: Bool?
    mutating func update(pressed: Bool) -> Bool {
        defer { previous = pressed }
        guard let previous else { return false }
        return pressed && !previous
    }
}

struct TriggerGate {
    private var armed = false
    mutating func update(value: Float) -> Bool {
        guard value.isFinite else { armed = false; return false }
        if value <= 0.25 { armed = true; return false }
        guard armed, value >= 0.65 else { return false }
        armed = false
        return true
    }
}
