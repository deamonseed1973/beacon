import AppKit
import Carbon

typealias HotKeyTask = (NSEvent?) -> Void

final class HotKey: Hashable {
    let keyCode: UInt32
    let modifierFlags: NSEvent.ModifierFlags
    let task: HotKeyTask

    fileprivate var hotKeyRef: EventHotKeyRef?
    fileprivate var hotKeyID: UInt32 = 0

    init(keyCode: UInt32, modifierFlags: NSEvent.ModifierFlags, task: @escaping HotKeyTask) {
        self.keyCode = keyCode
        self.modifierFlags = modifierFlags
        self.task = task
    }

    static func == (lhs: HotKey, rhs: HotKey) -> Bool {
        lhs.keyCode == rhs.keyCode && lhs.modifierFlags == rhs.modifierFlags
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(keyCode)
        hasher.combine(modifierFlags.rawValue)
    }
}

protocol HotKeyRegistrar {
    func registerHotKey(keyCode: UInt32, modifiers: UInt32, hotKeyID: UInt32, signature: OSType) -> EventHotKeyRef?
    func unregisterHotKey(_ hotKeyRef: EventHotKeyRef)
}

struct CarbonHotKeyRegistrar: HotKeyRegistrar {
    func registerHotKey(keyCode: UInt32, modifiers: UInt32, hotKeyID: UInt32, signature: OSType) -> EventHotKeyRef? {
        let eventHotKeyID = EventHotKeyID(signature: signature, id: hotKeyID)
        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(keyCode, modifiers, eventHotKeyID, GetEventDispatcherTarget(), 0, &hotKeyRef)
        guard status == noErr else { return nil }
        return hotKeyRef
    }

    func unregisterHotKey(_ hotKeyRef: EventHotKeyRef) {
        UnregisterEventHotKey(hotKeyRef)
    }
}

private let hotKeySignature: OSType = 0x68746B31
private var hotKeyEventHandlerInstalled = false

private func beaconHotKeyHandler(
    nextHandler: EventHandlerCallRef?,
    event: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus {
    guard let event else { return noErr }
    return HotKeyCenter.shared.handleEvent(event)
}

final class HotKeyCenter {
    static let shared = HotKeyCenter()

    private let registrar: HotKeyRegistrar
    private var registeredHotKeys = Set<HotKey>()
    private var nextHotKeyID: UInt32 = 1

    init(registrar: HotKeyRegistrar = CarbonHotKeyRegistrar(), installsEventHandler: Bool = true) {
        self.registrar = registrar
        if installsEventHandler {
            installEventHandlerIfNeeded()
        }
    }

    @discardableResult
    func registerHotKey(keyCode: UInt32, modifierFlags: NSEvent.ModifierFlags, task: @escaping HotKeyTask) -> HotKey? {
        guard !hasRegisteredHotKey(keyCode: keyCode, modifierFlags: modifierFlags) else { return nil }

        let hotKey = HotKey(keyCode: keyCode, modifierFlags: modifierFlags, task: task)
        return registerHotKey(hotKey)
    }

    @discardableResult
    func registerHotKey(_ hotKey: HotKey) -> HotKey? {
        guard !registeredHotKeys.contains(hotKey) else { return hotKey }

        guard let hotKeyRef = registrar.registerHotKey(
            keyCode: hotKey.keyCode,
            modifiers: carbonModifierFlags(from: hotKey.modifierFlags),
            hotKeyID: nextHotKeyID,
            signature: hotKeySignature
        ) else {
            return nil
        }

        hotKey.hotKeyRef = hotKeyRef
        hotKey.hotKeyID = nextHotKeyID
        nextHotKeyID += 1
        registeredHotKeys.insert(hotKey)
        return hotKey
    }

    func hasRegisteredHotKey(keyCode: UInt32, modifierFlags: NSEvent.ModifierFlags) -> Bool {
        registeredHotKeys.contains { $0.keyCode == keyCode && $0.modifierFlags == modifierFlags }
    }

    func unregisterHotKey(_ hotKey: HotKey) {
        if let hotKeyRef = hotKey.hotKeyRef {
            registrar.unregisterHotKey(hotKeyRef)
            hotKey.hotKeyRef = nil
        }
        registeredHotKeys.remove(hotKey)
    }

    func unregisterAllHotKeys() {
        let keys = registeredHotKeys
        for hotKey in keys {
            unregisterHotKey(hotKey)
        }
    }

    func registeredHotKeysSet() -> Set<HotKey> {
        registeredHotKeys.filter { $0.hotKeyRef != nil }
    }

    fileprivate func handleEvent(_ event: EventRef) -> OSStatus {
        var hotKeyID = EventHotKeyID()
        let status = GetEventParameter(
            event,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hotKeyID
        )
        guard status == noErr else { return status }
        guard let hotKey = registeredHotKeys.first(where: { $0.hotKeyID == hotKeyID.id }) else { return noErr }

        let keyEvent = NSEvent.keyEvent(
            with: .keyUp,
            location: .zero,
            modifierFlags: hotKey.modifierFlags,
            timestamp: ProcessInfo.processInfo.systemUptime,
            windowNumber: -1,
            context: nil,
            characters: "",
            charactersIgnoringModifiers: "",
            isARepeat: false,
            keyCode: UInt16(hotKey.keyCode)
        )
        hotKey.task(keyEvent)
        return noErr
    }

    private func installEventHandlerIfNeeded() {
        guard !hotKeyEventHandlerInstalled else { return }
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyReleased))
        var handlerRef: EventHandlerRef?
        InstallEventHandler(GetApplicationEventTarget(), beaconHotKeyHandler, 1, &eventSpec, nil, &handlerRef)
        hotKeyEventHandlerInstalled = true
    }
}
