import SwiftUI

extension View {
    /// Adds accessibility traits for a button with custom styling.
    /// When disabled, the .isButton trait is removed to indicate non-interactivity.
    func accessibleButton(label: String, hint: String? = nil, isDisabled: Bool = false) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
            .accessibilityRemoveTraits(isDisabled ? .isButton : [])
    }
    
    /// Adds accessibility support for a card that acts as a button
    func accessibleCard(label: String, hint: String? = nil, isSelected: Bool = false) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits([.isButton])
            .accessibilityValue(isSelected ? "Selected" : "Not selected")
    }
    
    /// Adds accessibility support for status indicators
    func accessibleStatus(status: String) -> some View {
        self
            .accessibilityLabel(status)
            .accessibilityAddTraits(.updatesFrequently)
    }
    
    /// Makes text more readable for dynamic type
    func adaptiveFont(_ textStyle: Font.TextStyle = .body, weight: Font.Weight = .regular) -> some View {
        self
            .font(.system(textStyle, design: .default, weight: weight))
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

/// Helper for VoiceOver announcements
struct AccessibilityAnnouncement {
    static func post(_ message: String, priority: UIAccessibility.Notification = .announcement) {
        UIAccessibility.post(notification: priority, argument: message)
    }
    
    static func screenChanged(to element: Any? = nil) {
        UIAccessibility.post(notification: .screenChanged, argument: element)
    }
    
    static func layoutChanged(to element: Any? = nil) {
        UIAccessibility.post(notification: .layoutChanged, argument: element)
    }
}

/// Environment value for detecting if VoiceOver is running
struct VoiceOverRunningKey: EnvironmentKey {
    static let defaultValue = UIAccessibility.isVoiceOverRunning
}

extension EnvironmentValues {
    var voiceOverRunning: Bool {
        get { self[VoiceOverRunningKey.self] }
        set { self[VoiceOverRunningKey.self] = newValue }
    }
}

/// Environment value for detecting if reduced motion is enabled
struct ReducedMotionKey: EnvironmentKey {
    static let defaultValue = UIAccessibility.isReduceMotionEnabled
}

extension EnvironmentValues {
    var reducedMotion: Bool {
        get { self[ReducedMotionKey.self] }
        set { self[ReducedMotionKey.self] = newValue }
    }
}
