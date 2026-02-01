import OSLog
import SwiftUI

struct SecurityAuditEvent: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let eventType: EventType
    let details: String
    let severity: Severity
    
    enum EventType: String, Codable {
        case gatewayConnection = "Gateway Connection"
        case tlsVerification = "TLS Verification"
        case authenticationAttempt = "Authentication"
        case permissionRequest = "Permission Request"
        case dataAccess = "Data Access"
        case configurationChange = "Configuration Change"
    }
    
    enum Severity: String, Codable {
        case info = "Info"
        case warning = "Warning"
        case error = "Error"
        case critical = "Critical"
        
        var color: Color {
            switch self {
            case .info: return .blue
            case .warning: return .orange
            case .error: return .red
            case .critical: return .purple
            }
        }
        
        var icon: String {
            switch self {
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.octagon.fill"
            case .critical: return "exclamationmark.shield.fill"
            }
        }
    }
    
    init(id: UUID = UUID(), timestamp: Date = Date(), eventType: EventType, details: String, severity: Severity = .info) {
        self.id = id
        self.timestamp = timestamp
        self.eventType = eventType
        self.details = details
        self.severity = severity
    }
}

@MainActor
@Observable
final class SecurityAuditLogger {
    private(set) var events: [SecurityAuditEvent] = []
    private let maxEvents = 1000
    
    static let shared = SecurityAuditLogger()
    
    private init() {
        self.loadEvents()
    }
    
    /// Logs a security event. The details parameter should NOT contain sensitive data
    /// such as tokens, passwords, or full fingerprints. Use redacted/truncated values.
    func log(_ eventType: SecurityAuditEvent.EventType, details: String, severity: SecurityAuditEvent.Severity = .info) {
        // Redact potentially sensitive information from details
        let redactedDetails = Self.redactSensitiveInfo(details)
        let event = SecurityAuditEvent(eventType: eventType, details: redactedDetails, severity: severity)
        self.events.insert(event, at: 0)
        
        // Trim to max events
        if self.events.count > self.maxEvents {
            self.events = Array(self.events.prefix(self.maxEvents))
        }
        
        self.saveEvents()
    }
    
    func clearEvents() {
        self.events = []
        self.saveEvents()
    }
    
    /// Redacts potentially sensitive information from log details.
    /// Tokens, fingerprints, and long hex strings are truncated.
    private static func redactSensitiveInfo(_ input: String) -> String {
        var result = input
        
        // Redact tokens (long alphanumeric strings, typically 32+ chars)
        // Using try! since the pattern is a compile-time constant - any regex error should fail fast
        let tokenPattern = #"\b[A-Za-z0-9_-]{32,}\b"#
        let tokenRegex = try! NSRegularExpression(pattern: tokenPattern)
        let tokenRange = NSRange(result.startIndex..., in: result)
        result = tokenRegex.stringByReplacingMatches(in: result, range: tokenRange, withTemplate: "[REDACTED]")
        
        // Truncate fingerprints (64-char hex strings) to first 8 chars
        // Using try! since the pattern is a compile-time constant - any regex error should fail fast
        let fingerprintPattern = #"\b([a-fA-F0-9]{8})[a-fA-F0-9]{56}\b"#
        let fingerprintRegex = try! NSRegularExpression(pattern: fingerprintPattern)
        let fingerprintRange = NSRange(result.startIndex..., in: result)
        result = fingerprintRegex.stringByReplacingMatches(in: result, range: fingerprintRange, withTemplate: "$1...")
        
        return result
    }
    
    // MARK: - Secure File Storage
    
    private static let logger = Logger(subsystem: "bot.molt", category: "SecurityAudit")
    
    /// Returns the URL for the secure audit log file.
    /// The file is stored in the app's Library/Application Support directory
    /// with file protection until first user authentication (allows background access).
    private static var auditLogFileURL: URL {
        // Use guard-let to safely unwrap directory URLs with fallbacks
        let baseDir: URL
        if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            baseDir = appSupport
        } else if let libraryDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first {
            baseDir = libraryDir
        } else {
            baseDir = FileManager.default.temporaryDirectory
        }
        
        let securityDir = baseDir.appendingPathComponent("SecurityAudit", isDirectory: true)
        
        // Ensure directory exists with appropriate protection
        if !FileManager.default.fileExists(atPath: securityDir.path) {
            try? FileManager.default.createDirectory(at: securityDir, withIntermediateDirectories: true)
            // Use completeFileProtectionUntilFirstUserAuthentication to allow background logging
            try? FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                ofItemAtPath: securityDir.path
            )
        }
        
        return securityDir.appendingPathComponent("audit-events.json")
    }
    
    private func loadEvents() {
        let fileURL = Self.auditLogFileURL
        guard FileManager.default.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL),
              let events = try? JSONDecoder().decode([SecurityAuditEvent].self, from: data) else {
            return
        }
        self.events = events
    }
    
    private func saveEvents() {
        guard let data = try? JSONEncoder().encode(self.events) else {
            Self.logger.error("Failed to encode security audit events")
            return
        }
        let fileURL = Self.auditLogFileURL
        
        do {
            // Use completeUntilFirstUserAuthentication to allow background writes
            try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        } catch {
            // Log to OSLog so failures are visible in Console/diagnostics
            Self.logger.error("Failed to save security audit events: \(error.localizedDescription, privacy: .public)")
        }
    }
}

struct SecurityAuditView: View {
    @State private var auditLogger = SecurityAuditLogger.shared
    @State private var selectedFilter: SecurityAuditEvent.EventType?
    @State private var showClearConfirmation = false
    
    private var filteredEvents: [SecurityAuditEvent] {
        if let filter = self.selectedFilter {
            return self.auditLogger.events.filter { $0.eventType == filter }
        }
        return self.auditLogger.events
    }
    
    var body: some View {
        List {
            Section {
                Picker("Filter", selection: self.$selectedFilter) {
                    Text("All Events").tag(nil as SecurityAuditEvent.EventType?)
                    ForEach([
                        SecurityAuditEvent.EventType.gatewayConnection,
                        .tlsVerification,
                        .authenticationAttempt,
                        .permissionRequest,
                        .dataAccess,
                        .configurationChange
                    ], id: \.self) { type in
                        Text(type.rawValue).tag(type as SecurityAuditEvent.EventType?)
                    }
                }
            }
            
            if self.filteredEvents.isEmpty {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.green)
                            Text("No Security Events")
                                .font(.headline)
                            Text("Security events will appear here")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(self.filteredEvents) { event in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Label(event.eventType.rawValue, systemImage: event.severity.icon)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(event.severity.color)
                                Spacer()
                                Text(event.timestamp, style: .relative)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text(event.details)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text(event.timestamp.formatted(date: .abbreviated, time: .standard))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    HStack {
                        Text("Events")
                        Spacer()
                        Text("\(self.filteredEvents.count)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Security Audit")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !self.auditLogger.events.isEmpty {
                ToolbarItem(placement: .primaryAction) {
                    Button(role: .destructive) {
                        self.showClearConfirmation = true
                    } label: {
                        Label("Clear", systemImage: "trash")
                    }
                }
            }
        }
        .confirmationDialog("Clear Security Events?", isPresented: self.$showClearConfirmation) {
            Button("Clear All Events", role: .destructive) {
                self.auditLogger.clearEvents()
            }
        } message: {
            Text("This will permanently delete all security audit events. This action cannot be undone.")
        }
    }
}

#Preview {
    NavigationStack {
        SecurityAuditView()
    }
}
