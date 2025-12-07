import Cocoa
import SwiftUI
import Combine
import Carbon.HIToolbox
import ApplicationServices

// MARK: - Settings Model

final class SettingsModel: ObservableObject {
    static let shared = SettingsModel()

    enum ModifierChoice: String, CaseIterable, Identifiable {
        case cmdOpt       = "⌘⌥"
        case cmdCtrl      = "⌘⌃"
        case cmdShiftOpt  = "⌘⇧⌥"
        case cmdOptCtrl   = "⌘⌥⌃"

        var id: String { rawValue }

        var mask: UInt32 {
            switch self {
            case .cmdOpt:      return UInt32(cmdKey) | UInt32(optionKey)
            case .cmdCtrl:     return UInt32(cmdKey) | UInt32(controlKey)
            case .cmdShiftOpt: return UInt32(cmdKey) | UInt32(shiftKey) | UInt32(optionKey)
            case .cmdOptCtrl:  return UInt32(cmdKey) | UInt32(optionKey) | UInt32(controlKey)
            }
        }

        static func fromStored(_ s: String?) -> ModifierChoice {
            Self.allCases.first { $0.rawValue == s } ?? .cmdOpt
        }
    }

    @Published var baseModifiers: ModifierChoice {
        didSet { UserDefaults.standard.set(baseModifiers.rawValue, forKey: "baseModifiers") }
    }

    @Published var enableCorners: Bool {
        didSet { UserDefaults.standard.set(enableCorners, forKey: "enableCorners") }
    }

    private init() {
        baseModifiers = ModifierChoice.fromStored(UserDefaults.standard.string(forKey: "baseModifiers"))
        enableCorners = UserDefaults.standard.object(forKey: "enableCorners") as? Bool ?? true
    }

    func promptAccessibility() {
        let opts = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(opts)
    }

    func openLoginItems() {
        // Ventura/Sonoma+
        if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
            NSWorkspace.shared.open(url); return
        }
        // Fallback
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.users") {
            NSWorkspace.shared.open(url)
        }
    }
}

// MARK: - Preferences UI

struct PreferencesView: View {
    @ObservedObject var settings = SettingsModel.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Apricot Preferences")
                .font(.title2).bold()

            GroupBox("Hotkeys") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Modifier combo for arrows")
                        Spacer()
                        Picker("", selection: $settings.baseModifiers) {
                            ForEach(SettingsModel.ModifierChoice.allCases) { choice in
                                Text(choice.rawValue).tag(choice)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 280)
                    }
                    Toggle("Enable corner snaps (use same modifiers + Shift)", isOn: $settings.enableCorners)
                        .help("Corners use the same modifiers as above plus ⇧ Shift.")
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current bindings:")
                            .font(.callout).bold()
                        Text("• \(settings.baseModifiers.rawValue)+←/→/↑/↓ = halves")
                        Text("• \(settings.enableCorners ? settings.baseModifiers.rawValue + "⇧+←/→/↓/↑ = corners" : "Corners disabled")")
                        Text("• \(settings.baseModifiers.rawValue)+⏎ = maximize  •  \(settings.baseModifiers.rawValue)+C = center 70%")
                            .fixedSize(horizontal: false, vertical: true)
                    }.font(.callout).foregroundStyle(.secondary)
                }
                .padding(8)
            }

            GroupBox("Permissions & Startup") {
                HStack {
                    Button("Grant Accessibility…") { settings.promptAccessibility() }
                    Button("Open Login Items…") { settings.openLoginItems() }
                    Spacer()
                    Text("For auto-start, add Apricot in System Settings → General → Login Items.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding(8)
            }

            Spacer()
        }
        .padding(20)
        .frame(width: 560)
    }
}

// MARK: - App

@main
struct ApricotApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        Settings { PreferencesView() } // ⌘, and menu item open this
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var eventHandler: EventHandlerRef?
    private var hotKeys: [EventHotKeyRef?] = []
    private var cancellable: AnyCancellable?
    private var prefsWindow: NSWindow?
    private enum HDir { case left, right }
    private enum VDir { case up, down }
    private enum Direction { case left, right, up, down }

    private var lastHorizontal: HDir?
    private var lastVertical: VDir?

    private func handleDirection(_ dir: Direction) {
    let cornersEnabled = SettingsModel.shared.enableCorners

    switch dir {
    case .left, .right:

        let h: HDir = (dir == .left) ? .left : .right

        if cornersEnabled, let v = lastVertical {
            // We have a vertical context already → snap to corner
            let target: SnapTarget
            switch (h, v) {
            case (.left, .up):    target = .topLeft
            case (.right, .up):   target = .topRight
            case (.left, .down):  target = .bottomLeft
            case (.right, .down): target = .bottomRight
            }

            snap(target)
            
            lastHorizontal = h
            lastVertical = nil
        } else {
            // Just a horizontal half
            snap(dir == .left ? .left : .right)

            lastHorizontal = h
            lastVertical = nil
        }
        
        lastHorizontal = h

    case .up, .down:
        
        let v: VDir = (dir == .up) ? .up : .down
        
        if cornersEnabled, let h = lastHorizontal {
            // We have a horizontal context already → snap to corner
            let target: SnapTarget
            switch (h, v) {
            case (.left, .up):    target = .topLeft
            case (.right, .up):   target = .topRight
            case (.left, .down):  target = .bottomLeft
            case (.right, .down): target = .bottomRight
                
            }

            snap(target)
            lastVertical = v
            lastHorizontal = nil
        } else {
            // Just a vertical half
            snap(dir == .up ? .top : .bottom)
            
            lastVertical = v
            lastHorizontal = nil
        }
        
        lastVertical = v
    }
}

    
    @objc private func quit() {
        NSApp.terminate(nil)
    }
    
    private func makeStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let btn = statusItem.button, let img = NSImage(named: "StonefruitIcon") {
                img.isTemplate = true              // ensure macOS tints it for light/dark
                btn.image = img
                btn.imagePosition = .imageOnly
                btn.image?.size = NSSize(width: 18, height: 18) 
            }

        // Build the dropdown menu
        let menu = NSMenu()

        // Preferences…
        let prefsItem = NSMenuItem(title: "Preferences…",
                                   action: #selector(openPreferences),
                                   keyEquivalent: ",") // ⌘, works when this menu is open
        prefsItem.target = self
        menu.addItem(prefsItem)

        menu.addItem(.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit Apricot",
                                  action: #selector(quit),
                                  keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        makeStatusBar()
        SettingsModel.shared.promptAccessibility()
        installHotKeyEventHandler()
        registerHotKeys()

        // Re-register when preferences change
        cancellable = SettingsModel.shared.objectWillChange
            .sink { [weak self] _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self?.reRegisterHotKeys()
                }
            }
    }

    // MARK: - Menubar
    @objc func openPreferences() {
        // Bring app forward so the window shows on top
        NSApp.activate(ignoringOtherApps: true)

        if let w = prefsWindow {
            w.makeKeyAndOrderFront(nil)
            return
        }

        // Build the window once
        let w = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 420),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered, defer: false
        )
        w.isReleasedWhenClosed = false
        w.center()
        w.title = "Apricot Preferences"
        w.contentViewController = NSHostingController(rootView: PreferencesView())

        // Optional polish
        w.standardWindowButton(.zoomButton)?.isHidden = true

        prefsWindow = w
        w.makeKeyAndOrderFront(nil)
    }

    // MARK: - Accessibility prompt (already handled in SettingsModel)

    // MARK: - Hotkeys
    private func installHotKeyEventHandler() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))

        let handler: EventHandlerUPP = { (_, theEvent, userData) -> OSStatus in
            var hkID = EventHotKeyID()
            let status = GetEventParameter(theEvent,
                                           EventParamName(kEventParamDirectObject),
                                           EventParamType(typeEventHotKeyID),
                                           nil,
                                           MemoryLayout<EventHotKeyID>.size,
                                           nil,
                                           &hkID)
            if status == noErr, let userData {
                let app = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
                app.handleHotKey(hkID.id)
            }
            return noErr
        }

        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, userData, &eventHandler)
    }

    private func reRegisterHotKeys() {
        // Unregister old
        for ref in hotKeys { if let r = ref { UnregisterEventHotKey(r) } }
        hotKeys.removeAll()
        registerHotKeys()
    }

    private func registerHotKeys() {
    let settings = SettingsModel.shared
    let base = settings.baseModifiers.mask

    // Halves / directional inputs
    registerHotKey(keyCode: UInt32(kVK_LeftArrow),  modifiers: base, id: 1)
    registerHotKey(keyCode: UInt32(kVK_RightArrow), modifiers: base, id: 2)
    registerHotKey(keyCode: UInt32(kVK_UpArrow),    modifiers: base, id: 3)
    registerHotKey(keyCode: UInt32(kVK_DownArrow),  modifiers: base, id: 4)

    // Extras
    registerHotKey(keyCode: UInt32(kVK_Return),     modifiers: base, id: 9)  // maximize
    registerHotKey(keyCode: UInt32(kVK_ANSI_C),     modifiers: base, id: 10) // center 70%
}


    private func registerHotKey(keyCode: UInt32, modifiers: UInt32, id: UInt32) {
        var ref: EventHotKeyRef?
        let hkID = EventHotKeyID(signature: OSType(0x41505243), id: id) // 'APRC'
        RegisterEventHotKey(keyCode, modifiers, hkID, GetApplicationEventTarget(), 0, &ref)
        hotKeys.append(ref)
    }

    private func handleHotKey(_ id: UInt32) {
    switch id {
    case 1: handleDirection(.left)
    case 2: handleDirection(.right)
    case 3: handleDirection(.up)
    case 4: handleDirection(.down)
    case 9: snap(.maximize)
    case 10: snap(.center70)
    default: break
    }
}


    // MARK: - Snapping

    private enum SnapTarget {
        case left, right, top, bottom
        case topLeft, topRight, bottomLeft, bottomRight
        case maximize, center70
    }

    private func snap(_ target: SnapTarget) {
        guard let screen = screenUnderMouse() ?? NSScreen.main else { return }
        let vf = screen.visibleFrame
        var rect = vf
        
        let halfW = vf.width / 2.0
        let halfH = vf.height / 2.0
        
        
        switch target {
            
        //Halves:
        case .left:
            rect.origin.x = vf.minX
            rect.origin.y = vf.minY
            rect.size.width = halfW
            rect.size.height = vf.height
            
        case .right:
                // Anchor to RIGHT edge
                rect.size.width  = halfW
                rect.size.height = vf.height
                rect.origin.x = vf.maxX - rect.width
                rect.origin.y = vf.minY

            case .top:
                // Anchor to TOP edge
                rect.size.width  = vf.width
                rect.size.height = halfH
                rect.origin.x = vf.minX
                rect.origin.y = vf.maxY - rect.height

            case .bottom:
                // Anchor to BOTTOM edge
                rect.size.width  = vf.width
                rect.size.height = halfH
                rect.origin.x = vf.minX
                rect.origin.y = vf.minY

            // CORNERS (2×2 grid)
            case .topLeft:
                rect.size.width  = halfW
                rect.size.height = halfH
                rect.origin.x = vf.minX                       // left edge
                rect.origin.y = vf.maxY - rect.height        // top edge

            case .topRight:
                rect.size.width  = halfW
                rect.size.height = halfH
                rect.origin.x = vf.maxX - rect.width         // right edge
                rect.origin.y = vf.maxY - rect.height        // top edge

            case .bottomLeft:
                rect.size.width  = halfW
                rect.size.height = halfH
                rect.origin.x = vf.minX                       // left edge
                rect.origin.y = vf.minY                       // bottom edge

            case .bottomRight:
                rect.size.width  = halfW
                rect.size.height = halfH
                rect.origin.x = vf.maxX - rect.width         // right edge
                rect.origin.y = vf.minY                       // bottom edge

            case .maximize:
                rect = vf

            case .center70:
                let w = vf.width * 0.70
                let h = vf.height * 0.70
                rect = CGRect(
                    x: vf.minX + (vf.width - w) / 2.0,
                    y: vf.minY + (vf.height - h) / 2.0,
                    width:  w,
                    height: h
                )
            
        }

        setFrontWindowFrame(rect, on: screen)
    }

    private func screenUnderMouse() -> NSScreen? {
        let loc = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(loc, $0.frame, false) }
    }

    private func setFrontWindowFrame(_ rect: CGRect, on screen: NSScreen) {
        guard let app = NSWorkspace.shared.frontmostApplication else { return }
        let axApp = AXUIElementCreateApplication(app.processIdentifier)

        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axApp, kAXFocusedWindowAttribute as CFString, &value) == .success,
              let window = value else { return }

        // Convert Cocoa global coords (origin bottom-left) → AX coords (origin top-left)
        let screenFrame = screen.frame
        let topOfScreenY = screenFrame.origin.y + screenFrame.height
        var axOrigin = CGPoint(x: rect.origin.x,
                               y: topOfScreenY - (rect.origin.y + rect.height))
        var axSize = CGSize(width: rect.width, height: rect.height)

        guard let posVal  = AXValueCreate(.cgPoint, &axOrigin),
              let sizeVal = AXValueCreate(.cgSize,  &axSize) else { return }

        _ = AXUIElementSetAttributeValue(window as! AXUIElement, kAXPositionAttribute as CFString, posVal)
        _ = AXUIElementSetAttributeValue(window as! AXUIElement, kAXSizeAttribute as CFString,   sizeVal)
    }
}
