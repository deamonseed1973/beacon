import AppKit
import Carbon
import Testing
@testable import Beacon

private final class StubHotKeyRegistrar: HotKeyRegistrar {
    var registeredIDs: [UInt32] = []
    var unregisteredCount = 0

    func registerHotKey(keyCode: UInt32, modifiers: UInt32, hotKeyID: UInt32, signature: OSType) -> EventHotKeyRef? {
        registeredIDs.append(hotKeyID)
        let pointer = UnsafeMutableRawPointer(Unmanaged.passRetained(NSNumber(value: hotKeyID)).toOpaque())
        return unsafeBitCast(pointer, to: EventHotKeyRef.self)
    }

    func unregisterHotKey(_ hotKeyRef: EventHotKeyRef) {
        unregisteredCount += 1
        let pointer = unsafeBitCast(hotKeyRef, to: UnsafeMutableRawPointer.self)
        Unmanaged<NSNumber>.fromOpaque(pointer).release()
    }
}

struct HotKeyCenterTests {
    @Test("Converts Cocoa modifier flags to Carbon flags")
    func carbonModifierConversion() {
        let converted = carbonModifierFlags(from: [.option, .shift, .control])
        #expect(converted & UInt32(optionKey) != 0)
        #expect(converted & UInt32(shiftKey) != 0)
        #expect(converted & UInt32(controlKey) != 0)
        #expect(converted & UInt32(cmdKey) == 0)
    }

    @Test("Rejects duplicate hotkey registrations")
    func duplicateRegistration() {
        let registrar = StubHotKeyRegistrar()
        let center = HotKeyCenter(registrar: registrar, installsEventHandler: false)

        let first = center.registerHotKey(keyCode: 0, modifierFlags: [.option, .shift]) { _ in }
        let duplicate = center.registerHotKey(keyCode: 0, modifierFlags: [.option, .shift]) { _ in }

        #expect(first != nil)
        #expect(duplicate == nil)
        #expect(registrar.registeredIDs == [1])
    }

    @Test("Unregistering all hotkeys clears the registry")
    func unregisterAllHotKeys() {
        let registrar = StubHotKeyRegistrar()
        let center = HotKeyCenter(registrar: registrar, installsEventHandler: false)

        _ = center.registerHotKey(keyCode: 0, modifierFlags: [.option]) { _ in }
        _ = center.registerHotKey(keyCode: 11, modifierFlags: [.shift]) { _ in }

        center.unregisterAllHotKeys()

        #expect(center.registeredHotKeysSet().isEmpty)
        #expect(registrar.unregisteredCount == 2)
    }
}
