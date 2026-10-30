import AppKit
import ApplicationServices
import GameController

private let booksBundleIDs: Set<String> = ["com.apple.iBooks", "com.apple.iBooksX"]

final class BookPadDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var window: NSWindow!
    private var statusItem: NSStatusItem!
    private var timer: Timer?
    private var gates: [String: StickGate] = [:]
    private var buttonGates: [String: ButtonGate] = [:]
    private var triggerGates: [String: TriggerGate] = [:]
    private var guideWindow: NSWindow?
    private var lastContext = ""
    private var lastFlip = -Double.infinity
    private var lastUI = 0.0
    private var flipCount = 0
    private var enabled = true
    private let controllerLabel = NSTextField(wrappingLabelWithString: "正在检测手柄…")
    private let permissionLabel = NSTextField(labelWithString: "")
    private let activityLabel = NSTextField(labelWithString: "")
    private let eventLabel = NSTextField(labelWithString: "等待手柄操作")
    private let toggle = NSButton(checkboxWithTitle: "启用手柄阅读控制", target: nil, action: nil)
    private let reverse = NSButton(checkboxWithTitle: "反转翻页方向（适用于反向排版书籍）", target: nil, action: nil)

    func applicationDidFinishLaunching(_ notification: Notification) {
        GCController.shouldMonitorBackgroundEvents = true
        buildMenu()
        buildWindow()
        timer = Timer(timeInterval: 1.0 / 60.0, target: self, selector: #selector(tick), userInfo: nil, repeats: true)
        RunLoop.main.add(timer!, forMode: .common)
        showWindow()
    }

    private func buildMenu() {
        let appMenu = NSMenu()
        let root = NSMenuItem()
        let sub = NSMenu()
        sub.addItem(withTitle: "退出 BookPad", action: #selector(quit), keyEquivalent: "q").target = self
        root.submenu = sub
        appMenu.addItem(root)
        NSApp.mainMenu = appMenu
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "gamecontroller", accessibilityDescription: "BookPad")
        let menu = NSMenu()
        menu.addItem(withTitle: "显示 BookPad", action: #selector(showWindow), keyEquivalent: "").target = self
        menu.addItem(withTitle: "打开图书", action: #selector(openBooks), keyEquivalent: "").target = self
        menu.addItem(withTitle: "按键说明…", action: #selector(showGuide), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "退出", action: #selector(quit), keyEquivalent: "q").target = self
        statusItem.menu = menu
    }

    private func buildWindow() {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 560, height: 470),
                          styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.title = "BookPad · 手柄翻书"
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.center()
        let content = window.contentView!
        let title = NSTextField(labelWithString: "用手柄，舒服地读书。")
        title.font = .systemFont(ofSize: 25, weight: .semibold)
        let intro = NSTextField(wrappingLabelWithString: "L1 / R1 轻按翻页，L2 / R2 深按跳章节。两个摇杆横向翻页；右摇杆上下调字号。所有操作单次触发。")
        intro.font = .systemFont(ofSize: 14)
        toggle.state = .on
        toggle.target = self
        toggle.action = #selector(toggleEnabled)
        reverse.state = UserDefaults.standard.bool(forKey: "reverseDirection") ? .on : .off
        reverse.target = self
        reverse.action = #selector(reverseChanged)
        let mapping = NSTextField(labelWithString: "← 上一页                       下一页 →")
        mapping.font = .monospacedSystemFont(ofSize: 18, weight: .medium)
        let grant = NSButton(title: "授权辅助功能…", target: self, action: #selector(requestPermission))
        grant.bezelStyle = .rounded
        let books = NSButton(title: "打开图书", target: self, action: #selector(openBooks))
        books.bezelStyle = .rounded
        let guide = NSButton(title: "按键说明…", target: self, action: #selector(showGuide))
        guide.bezelStyle = .rounded
        let buttons = NSStackView(views: [grant, books, guide])
        buttons.orientation = .horizontal
        buttons.spacing = 12
        let help = NSTextField(wrappingLabelWithString: "首次使用：连接 PS4 手柄 → 授权辅助功能 → 打开图书并点击书籍正文。\n蓝牙配对：关机时按住 PS + SHARE，灯条闪烁后在系统蓝牙设置中连接。\n仅当“图书”位于前台时翻页；关闭此窗口后仍可从菜单栏打开。")
        help.font = .systemFont(ofSize: 12)
        help.textColor = .secondaryLabelColor
        controllerLabel.font = .systemFont(ofSize: 13, weight: .medium)
        permissionLabel.font = .systemFont(ofSize: 13)
        activityLabel.font = .systemFont(ofSize: 13)
        eventLabel.textColor = .secondaryLabelColor
        let stack = NSStackView(views: [title, intro, mapping, toggle, reverse, controllerLabel,
                                        permissionLabel, activityLabel, eventLabel, buttons, help])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 28),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -28),
            stack.topAnchor.constraint(equalTo: content.topAnchor, constant: 26),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: content.bottomAnchor, constant: -20),
            intro.widthAnchor.constraint(equalTo: stack.widthAnchor),
            help.widthAnchor.constraint(equalTo: stack.widthAnchor),
            controllerLabel.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
        window.setContentSize(NSSize(width: 560, height: 540))
    }

    @objc private func showGuide() {
        if guideWindow == nil {
            let panel = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 670, height: 620),
                                 styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
            panel.title = "BookPad · 完整按键说明"
            panel.isReleasedWhenClosed = false
            panel.minSize = NSSize(width: 620, height: 400)
            let scroll = NSScrollView(frame: panel.contentView!.bounds)
            scroll.autoresizingMask = [.width, .height]
            scroll.hasVerticalScroller = true
            let text = NSTextView(frame: NSRect(x: 0, y: 0, width: 650, height: 900))
            text.isEditable = false
            text.isSelectable = true
            text.isVerticallyResizable = true
            text.isHorizontallyResizable = false
            text.autoresizingMask = [.width]
            text.textContainerInset = NSSize(width: 22, height: 22)
            text.textContainer?.widthTracksTextView = true
            let result = NSMutableAttributedString(string: "")
            for (input, output) in ReadingAction.guide {
                result.append(NSAttributedString(string: input + "\n", attributes: [
                    .font: NSFont.systemFont(ofSize: 14, weight: .semibold), .foregroundColor: NSColor.labelColor]))
                result.append(NSAttributedString(string: output + "\n\n", attributes: [
                    .font: NSFont.systemFont(ofSize: 13), .foregroundColor: NSColor.secondaryLabelColor]))
            }
            result.append(NSAttributedString(string: "反转方向会交换翻页和章节左右方向，方向键在列表中的导航保持原样。\n\n所有按键须松开才能再次触发。切换应用后，已按住的键不会误触。摇杆按下时忽略其偏移。\n\n字号、章节、书签功能取决于书籍格式及图书当前界面。搜索文字仍需键盘输入。PS 键可能先被 macOS 接管，此时请用主窗口的启用开关。", attributes: [.font: NSFont.systemFont(ofSize: 12), .foregroundColor: NSColor.secondaryLabelColor]))
            text.textStorage?.setAttributedString(result)
            scroll.documentView = text
            panel.contentView?.addSubview(scroll)
            panel.center()
            guideWindow = panel
        }
        guideWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func tick() {
        let now = ProcessInfo.processInfo.systemUptime
        let front = NSWorkspace.shared.frontmostApplication
        let trusted = AXIsProcessTrusted()
        let booksFront = booksBundleIDs.contains(front?.bundleIdentifier ?? "")
        let active = enabled && trusted && booksFront
        let context = "\(active)-\(front?.processIdentifier ?? 0)"
        if context != lastContext {
            resetInputs()
            lastContext = context
        }
        let controllers = GCController.controllers()
        var liveKeys = Set<String>()
        var requests: [ReadingAction] = []
        for controller in controllers {
            guard let pad = controller.extendedGamepad else { continue }
            let prefix = "\(ObjectIdentifier(controller))"
            for (index, stick) in [pad.leftThumbstick, pad.rightThumbstick].enumerated() {
                let key = "\(prefix)-stick-\(index)"
                liveKeys.insert(key)
                let click = index == 0 ? pad.leftThumbstickButton : pad.rightThumbstickButton
                if click?.isPressed == true { gates[key] = StickGate(); continue }
                var gate = gates[key] ?? StickGate()
                if let direction = gate.updateDirection(x: stick.xAxis.value, y: stick.yAxis.value) {
                    switch direction {
                    case .left: requests.append(.previousPage)
                    case .right: requests.append(.nextPage)
                    case .up: requests.append(index == 0 ? .chapterStart : .largerFont)
                    case .down: requests.append(index == 0 ? .chapterEnd : .smallerFont)
                    }
                }
                gates[key] = gate
            }
            let buttons: [(String, GCControllerButtonInput?, ReadingAction)] = [
                ("L1", pad.leftShoulder, .previousPage), ("R1", pad.rightShoulder, .nextPage),
                ("dleft", pad.dpad.left, .previousPage), ("dright", pad.dpad.right, .nextPage),
                ("dup", pad.dpad.up, .up), ("ddown", pad.dpad.down, .down),
                ("cross", pad.buttonA, .confirm), ("circle", pad.buttonB, .cancel),
                ("square", pad.buttonX, .bookmark), ("triangle", pad.buttonY, .contents),
                ("share", pad.buttonOptions, .search), ("options", pad.buttonMenu, .fullScreen),
                ("L3", pad.leftThumbstickButton, .notes), ("R3", pad.rightThumbstickButton, .resetFont),
                ("PS", pad.buttonHome, .pause),
                ("touch", (pad as? GCDualShockGamepad)?.touchpadButton, .bookmarks)
            ]
            for (name, button, action) in buttons {
                guard let button else { continue }
                let key = "\(prefix)-\(name)"
                liveKeys.insert(key)
                var gate = buttonGates[key] ?? ButtonGate()
                if gate.update(pressed: button.isPressed) { requests.append(action) }
                buttonGates[key] = gate
            }
            for (name, button, action) in [("L2", pad.leftTrigger, ReadingAction.previousChapter),
                                            ("R2", pad.rightTrigger, ReadingAction.nextChapter)] {
                let key = "\(prefix)-\(name)"
                liveKeys.insert(key)
                var gate = triggerGates[key] ?? TriggerGate()
                if gate.update(value: button.value) { requests.append(action) }
                triggerGates[key] = gate
            }
        }
        gates = gates.filter { liveKeys.contains($0.key) }
        buttonGates = buttonGates.filter { liveKeys.contains($0.key) }
        triggerGates = triggerGates.filter { liveKeys.contains($0.key) }
        if booksFront, requests.contains(.pause) {
            enabled.toggle()
            toggle.state = enabled ? .on : .off
            eventLabel.stringValue = enabled ? "PS · 已恢复阅读控制" : "PS · 已暂停，再按一次恢复"
            resetInputs()
        } else if let request = requests.first, active, let front,
                  requests.allSatisfy({ $0 == request }) {
            // Direction reversal is for content navigation; D-pad also needs standard list navigation.
            let dpadLeft = controllers.contains { $0.extendedGamepad?.dpad.left.isPressed == true }
            let dpadRight = controllers.contains { $0.extendedGamepad?.dpad.right.isPressed == true }
            let reversePages = reverse.state == .on && !(dpadLeft || dpadRight)
            let action = request.reversed(reversePages)
            let pageAction = action == .previousPage || action == .nextPage
            if (!pageAction || now - lastFlip >= 0.18), send(action: action, to: front.processIdentifier) {
                if pageAction { lastFlip = now }
                flipCount += 1
                eventLabel.stringValue = "已发送：\(action.title) · 累计 \(flipCount) 次"
            }
        }
        if now - lastUI > 0.3 {
            lastUI = now
            let usable = controllers.filter { $0.extendedGamepad != nil }
            controllerLabel.stringValue = usable.isEmpty ? "手柄：未连接，请用蓝牙或 USB 连接" :
                "手柄：" + usable.map { $0.vendorName ?? "已连接" }.joined(separator: "、")
            permissionLabel.stringValue = trusted ? "辅助功能：已授权 ✓" : "辅助功能：尚未授权，请点击下方按钮"
            permissionLabel.textColor = trusted ? .systemGreen : .systemOrange
            activityLabel.stringValue = !enabled ? "已暂停 · 图书前台按 PS 可恢复" : (active ? "已就绪 · 手柄阅读控制中" : "等待图书窗口位于前台并完成授权")
        }
    }

    private func send(action: ReadingAction, to pid: pid_t) -> Bool {
        guard enabled, AXIsProcessTrusted(), NSWorkspace.shared.frontmostApplication?.processIdentifier == pid,
              booksBundleIDs.contains(NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? ""),
              let shortcut = action.shortcut,
              let source = CGEventSource(stateID: .privateState),
              let down = CGEvent(keyboardEventSource: source, virtualKey: shortcut.key, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: shortcut.key, keyDown: false)
        else { return false }
        down.flags = shortcut.flags
        up.flags = shortcut.flags
        down.postToPid(pid)
        up.postToPid(pid)
        return true
    }

    private func resetInputs() { gates.removeAll(); buttonGates.removeAll(); triggerGates.removeAll() }
    @objc private func toggleEnabled() { enabled = toggle.state == .on; resetInputs() }
    @objc private func reverseChanged() {
        UserDefaults.standard.set(reverse.state == .on, forKey: "reverseDirection")
        resetInputs()
    }
    @objc private func requestPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    @objc private func openBooks() {
        if let url = booksBundleIDs.sorted().compactMap({ NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0) }).first {
            NSWorkspace.shared.openApplication(at: url, configuration: .init(), completionHandler: nil)
        }
    }
    @objc private func showWindow() { window.makeKeyAndOrderFront(nil); NSApp.activate(ignoringOtherApps: true) }
    @objc private func quit() { NSApp.terminate(nil) }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showWindow(); return true
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
}

let app = NSApplication.shared
app.setActivationPolicy(.regular)
let delegate = BookPadDelegate()
app.delegate = delegate
app.run()
