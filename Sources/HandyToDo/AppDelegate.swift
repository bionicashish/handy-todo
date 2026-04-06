import AppKit
import SwiftUI

// Borderless NSPanel doesn't become key by default — override to allow it.
final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem!
    private var panel: NSPanel!
    private var store: ChecklistStore!
    private var eventMonitor: Any?
    private var keyMonitor: Any?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        store = ChecklistStore()
        setupPanel()
        setupStatusItem()
        setupKeyMonitor()
    }

    func applicationWillTerminate(_ notification: Notification) {
        removeEventMonitor()
        if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
    }

    // MARK: - Cmd+R key monitor

    private func setupKeyMonitor() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.panel.isVisible else { return event }
            let cmd = event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command
            let key = event.charactersIgnoringModifiers

            if cmd && key == "r" {
                self.store.clearAll()
                return nil
            }

            if cmd {
                let selector: Selector? = switch key {
                case "a": #selector(NSText.selectAll(_:))
                case "c": #selector(NSText.copy(_:))
                case "v": #selector(NSText.paste(_:))
                case "x": #selector(NSText.cut(_:))
                default:  nil
                }
                if let sel = selector {
                    NSApp.sendAction(sel, to: nil, from: nil)
                    return nil
                }
            }

            return event
        }
    }

    // MARK: - Panel

    private func setupPanel() {
        let hostingView = NSHostingView(rootView: ContentView(store: store))

        // Clip all child views (including NSScrollView inside List) at the CALayer level
        hostingView.wantsLayer = true
        hostingView.layer?.cornerRadius = 32
        hostingView.layer?.masksToBounds = true
        hostingView.layer?.backgroundColor = NSColor.white.cgColor

        panel = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 520),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.isMovableByWindowBackground = false
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .transient]
        panel.contentView = hostingView
    }

    // MARK: - Status Item

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        guard let button = statusItem.button else { return }

        let image = NSImage(systemSymbolName: "checklist", accessibilityDescription: "HandyToDo")
        image?.isTemplate = true
        button.image = image
        button.toolTip = "Handy To-Do"
        button.action = #selector(togglePanel(_:))
        button.target = self
        button.sendAction(on: [.leftMouseUp])
    }

    // MARK: - Toggle

    @objc private func togglePanel(_ sender: AnyObject?) {
        if panel.isVisible {
            closePanel()
        } else {
            openPanel()
        }
    }

    private func openPanel() {
        guard let button = statusItem.button,
              let buttonWindow = button.window,
              let screen = buttonWindow.screen ?? NSScreen.main else { return }

        // Position panel below the status item button
        let buttonFrameOnScreen = buttonWindow.convertToScreen(
            button.convert(button.bounds, to: nil)
        )

        let panelWidth: CGFloat  = 400
        let panelHeight: CGFloat = 520
        let gap: CGFloat         = 6

        var x = buttonFrameOnScreen.midX - panelWidth / 2
        let y = buttonFrameOnScreen.minY - panelHeight - gap

        // Keep panel within screen bounds horizontally
        let screenRight = screen.visibleFrame.maxX
        if x + panelWidth > screenRight {
            x = screenRight - panelWidth - 4
        }
        if x < screen.visibleFrame.minX {
            x = screen.visibleFrame.minX + 4
        }

        panel.setFrameOrigin(NSPoint(x: x, y: y))
        panel.orderFront(nil)
        // Defer activation so it runs after the status-bar click event fully unwinds
        DispatchQueue.main.async {
            NSApp.activate(ignoringOtherApps: true)
            self.panel.makeKeyAndOrderFront(nil)
        }

        eventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] event in
            // Don't close if click is inside the panel
            if let self, let loc = self.panel.contentView?.convert(
                self.panel.mouseLocationOutsideOfEventStream, from: nil
            ), !self.panel.contentView!.bounds.contains(loc) {
                self.closePanel()
            }
        }
    }

    private func closePanel() {
        panel.orderOut(nil)
        removeEventMonitor()
    }

    private func removeEventMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}
