import AppKit
import Carbon

private let keyCodeToCharacterMap: [UInt32: String] = [
    UInt32(kVK_ANSI_A): "A",
    UInt32(kVK_ANSI_B): "B",
    UInt32(kVK_ANSI_E): "E",
    UInt32(kVK_ANSI_Q): "Q",
    UInt32(kVK_ANSI_R): "R",
    UInt32(kVK_Return): "↩",
    UInt32(kVK_Tab): "⇥",
    UInt32(kVK_Space): "⎵",
    UInt32(kVK_Delete): "⌫",
    UInt32(kVK_Escape): "⎋",
    UInt32(kVK_Command): "⌘",
    UInt32(kVK_Shift): "⇧",
    UInt32(kVK_CapsLock): "⇪",
    UInt32(kVK_Option): "⌥",
    UInt32(kVK_Control): "⌃",
    UInt32(kVK_RightShift): "⇧",
    UInt32(kVK_RightOption): "⌥",
    UInt32(kVK_RightControl): "⌃",
    UInt32(kVK_VolumeUp): "🔊",
    UInt32(kVK_VolumeDown): "🔈",
    UInt32(kVK_Mute): "🔇",
    UInt32(kVK_Function): "⌘",
    UInt32(kVK_F1): "F1",
    UInt32(kVK_F2): "F2",
    UInt32(kVK_F3): "F3",
    UInt32(kVK_F4): "F4",
    UInt32(kVK_F5): "F5",
    UInt32(kVK_F6): "F6",
    UInt32(kVK_F7): "F7",
    UInt32(kVK_F8): "F8",
    UInt32(kVK_F9): "F9",
    UInt32(kVK_F10): "F10",
    UInt32(kVK_F11): "F11",
    UInt32(kVK_F12): "F12",
    UInt32(kVK_F13): "F13",
    UInt32(kVK_F14): "F14",
    UInt32(kVK_F15): "F15",
    UInt32(kVK_F16): "F16",
    UInt32(kVK_F17): "F17",
    UInt32(kVK_F18): "F18",
    UInt32(kVK_F19): "F19",
    UInt32(kVK_F20): "F20",
    UInt32(kVK_ForwardDelete): "⌦",
    UInt32(kVK_Home): "↖",
    UInt32(kVK_End): "↘",
    UInt32(kVK_PageUp): "⇞",
    UInt32(kVK_PageDown): "⇟",
    UInt32(kVK_LeftArrow): "←",
    UInt32(kVK_RightArrow): "→",
    UInt32(kVK_DownArrow): "↓",
    UInt32(kVK_UpArrow): "↑",
]

func carbonModifierFlags(from flags: NSEvent.ModifierFlags) -> UInt32 {
    var converted: UInt32 = 0
    if flags.contains(.control) { converted |= UInt32(controlKey) }
    if flags.contains(.command) { converted |= UInt32(cmdKey) }
    if flags.contains(.shift) { converted |= UInt32(shiftKey) }
    if flags.contains(.option) { converted |= UInt32(optionKey) }
    if flags.contains(.capsLock) { converted |= UInt32(alphaLock) }
    return converted
}

func hotKeyDisplayString(keyCode: UInt32, modifiers: NSEvent.ModifierFlags) -> String {
    var value = ""
    if modifiers.contains(.control) { value += "⌃" }
    if modifiers.contains(.option) { value += "⌥" }
    if modifiers.contains(.shift) { value += "⇧" }
    if modifiers.contains(.command) { value += "⌘" }

    if keyCode == UInt32(kVK_Control) || keyCode == UInt32(kVK_Option) ||
        keyCode == UInt32(kVK_Shift) || keyCode == UInt32(kVK_Command)
    {
        return value
    }

    if let mapped = keyCodeToCharacterMap[keyCode] {
        return value + mapped
    }

    return value + "?"
}
