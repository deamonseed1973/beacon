import AppKit

/// Calculates the notch frame on a given screen.
/// Inspired by boring.notch's sizeMatters.swift — uses auxiliaryTopLeftArea
/// and auxiliaryTopRightArea to derive the actual notch cutout width.
func notchFrame(on screen: NSScreen) -> CGRect {
    let topLeft = screen.auxiliaryTopLeftArea?.width ?? 0
    let topRight = screen.auxiliaryTopRightArea?.width ?? 0
    let notchWidth = screen.frame.width - topLeft - topRight + 4
    let notchHeight: CGFloat = max(screen.safeAreaInsets.top, 24)
    let x = screen.frame.minX + topLeft - 2
    let y = screen.frame.maxY - notchHeight
    return CGRect(x: x, y: y, width: notchWidth, height: notchHeight)
}

/// Whether the screen has a physical notch cutout.
func hasNotch(on screen: NSScreen) -> Bool {
    return screen.safeAreaInsets.top > 0
}
