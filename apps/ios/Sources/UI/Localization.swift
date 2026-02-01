import Foundation

/// Localization helper to make string lookups cleaner
enum L10n {
    // Onboarding
    enum Onboarding {
        static let welcomeTitle = NSLocalizedString("onboarding.welcome.title", comment: "Welcome screen title")
        static let welcomeSubtitle = NSLocalizedString("onboarding.welcome.subtitle", comment: "Welcome screen subtitle")
        static let `continue` = NSLocalizedString("onboarding.welcome.continue", comment: "Continue button")
        
        enum Gateway {
            static let title = NSLocalizedString("onboarding.gateway.title", comment: "Gateway setup title")
            static let subtitle = NSLocalizedString("onboarding.gateway.subtitle", comment: "Gateway setup subtitle")
            static let noGateways = NSLocalizedString("onboarding.gateway.noGateways", comment: "No gateways found")
            static let manualSetup = NSLocalizedString("onboarding.gateway.manualSetup", comment: "Manual setup button")
        }
        
        enum Permissions {
            static let title = NSLocalizedString("onboarding.permissions.title", comment: "Permissions title")
            static let subtitle = NSLocalizedString("onboarding.permissions.subtitle", comment: "Permissions subtitle")
            static let required = NSLocalizedString("onboarding.permissions.required", comment: "Required badge")
        }
    }
    
    // Settings
    enum Settings {
        static let title = NSLocalizedString("settings.title", comment: "Settings title")
        
        enum Privacy {
            static let title = NSLocalizedString("privacy.title", comment: "Privacy title")
            static let subtitle = NSLocalizedString("privacy.subtitle", comment: "Privacy subtitle")
        }
    }
    
    // Status
    enum Status {
        static let connected = NSLocalizedString("status.connected", comment: "Connected status")
        static let connecting = NSLocalizedString("status.connecting", comment: "Connecting status")
        static let disconnected = NSLocalizedString("status.disconnected", comment: "Disconnected status")
        static let error = NSLocalizedString("status.error", comment: "Error status")
    }
    
    // Accessibility
    enum Accessibility {
        static let chat = NSLocalizedString("accessibility.chat.button", comment: "Chat button label")
        static let settings = NSLocalizedString("accessibility.settings.button", comment: "Settings button label")
        static let talkMode = NSLocalizedString("accessibility.talkMode.button", comment: "Talk mode button label")
        static let close = NSLocalizedString("accessibility.close.button", comment: "Close button label")
    }
    
    // Errors
    enum Errors {
        static let generic = NSLocalizedString("error.generic", comment: "Generic error message")
        static let connectionFailed = NSLocalizedString("error.connectionFailed", comment: "Connection failed error")
        static let permissionDenied = NSLocalizedString("error.permissionDenied", comment: "Permission denied error")
        static let retry = NSLocalizedString("error.retry", comment: "Retry button")
    }
    
    // Common
    enum Common {
        static let cancel = NSLocalizedString("common.cancel", comment: "Cancel button")
        static let done = NSLocalizedString("common.done", comment: "Done button")
        static let save = NSLocalizedString("common.save", comment: "Save button")
        static let delete = NSLocalizedString("common.delete", comment: "Delete button")
        static let allow = NSLocalizedString("common.allow", comment: "Allow button")
        static let notNow = NSLocalizedString("common.notNow", comment: "Not now button")
    }
}
