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
    
    func log(_ eventType: SecurityAuditEvent.EventType, details: String, severity: SecurityAuditEvent.Severity = .info) {
        let event = SecurityAuditEvent(eventType: eventType, details: details, severity: severity)
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
    
    private func loadEvents() {
        guard let data = UserDefaults.standard.data(forKey: "securityAuditEvents"),
              let events = try? JSONDecoder().decode([SecurityAuditEvent].self, from: data) else {
            return
        }
        self.events = events
    }
    
    private func saveEvents() {
        guard let data = try? JSONEncoder().encode(self.events) else { return }
        UserDefaults.standard.set(data, forKey: "securityAuditEvents")
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
