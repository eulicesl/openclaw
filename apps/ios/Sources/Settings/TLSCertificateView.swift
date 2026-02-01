import SwiftUI
import MoltbotKit

/// View for managing TLS certificate pinning (TOFU - Trust On First Use).
///
/// This view displays pinned certificates stored via `GatewayTLSStore` and allows
/// users to view fingerprints and remove certificates when needed.
struct TLSCertificateView: View {
    @State private var certificates: [StoredCertificate] = []
    @State private var showDeleteConfirmation: StoredCertificate?
    @State private var isLoading = true
    
    /// Represents a stored TLS certificate with its metadata.
    struct StoredCertificate: Identifiable {
        let id: String
        let stableID: String
        let fingerprint: String
        let addedDate: Date
        
        var displayName: String {
            if self.stableID.contains(":") {
                return self.stableID
            }
            return "Gateway \(self.stableID.prefix(8))..."
        }
        
        /// Returns a truncated fingerprint for display (first 16 chars + "...").
        var truncatedFingerprint: String {
            if self.fingerprint.count > 16 {
                return String(self.fingerprint.prefix(16)) + "..."
            }
            return self.fingerprint
        }
    }
    
    var body: some View {
        List {
            Section {
                Text("Moltbot uses TLS certificate pinning (TOFU - Trust On First Use) to secure connections to your gateway. Pinned certificates are stored locally.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            
            if self.isLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView()
                            .padding()
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
            } else if self.certificates.isEmpty {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "lock.shield")
                                .font(.system(size: 48))
                                .foregroundStyle(.secondary)
                            Text("No Pinned Certificates")
                                .font(.headline)
                            Text("Certificates will be pinned on first connection")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
            } else {
                Section("Pinned Certificates") {
                    ForEach(self.certificates) { cert in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label(cert.displayName, systemImage: "checkmark.shield.fill")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.green)
                                Spacer()
                                Button(role: .destructive) {
                                    self.showDeleteConfirmation = cert
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                }
                                .buttonStyle(.plain)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Fingerprint:")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                Text(cert.fingerprint)
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                    .textSelection(.enabled)
                            }
                            
                            Text("Pinned: \(cert.addedDate.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Automatic Pinning", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                    Text("First connection to a gateway automatically pins its certificate")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Label("Verification", systemImage: "lock.shield.fill")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Text("Future connections verify against the pinned certificate")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    
                    Label("Man-in-the-Middle Protection", systemImage: "exclamationmark.shield.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Text("Prevents unauthorized interception of your traffic")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("How It Works")
            }
        }
        .navigationTitle("TLS Certificates")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            self.loadCertificates()
        }
        .confirmationDialog("Delete Certificate?", isPresented: Binding(
            get: { self.showDeleteConfirmation != nil },
            set: { if !$0 { self.showDeleteConfirmation = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let cert = self.showDeleteConfirmation {
                    self.deleteCertificate(cert)
                }
            }
        } message: {
            if let cert = self.showDeleteConfirmation {
                Text("This will remove the pinned certificate for \(cert.displayName). You will be prompted to verify the certificate on next connection.")
            }
        }
    }
    
    /// Loads all pinned certificates from the shared GatewayTLSStore.
    ///
    /// The certificates are stored in UserDefaults with a specific suite name and key prefix.
    /// This method enumerates all keys matching the TLS certificate pattern.
    private func loadCertificates() {
        self.isLoading = true
        
        // Access the shared UserDefaults suite used by GatewayTLSStore
        let suiteName = "bot.molt.shared"
        let keyPrefix = "gateway.tls."
        
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            self.isLoading = false
            return
        }
        
        var loadedCerts: [StoredCertificate] = []
        let allKeys = defaults.dictionaryRepresentation().keys
        
        for key in allKeys where key.hasPrefix(keyPrefix) {
            guard let fingerprint = defaults.string(forKey: key),
                  !fingerprint.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                continue
            }
            
            let stableID = String(key.dropFirst(keyPrefix.count))
            let cert = StoredCertificate(
                id: key,
                stableID: stableID,
                fingerprint: fingerprint.trimmingCharacters(in: .whitespacesAndNewlines),
                // Note: GatewayTLSStore doesn't store dates, so we use a placeholder
                addedDate: Date.distantPast
            )
            loadedCerts.append(cert)
        }
        
        // Sort by stableID for consistent display
        self.certificates = loadedCerts.sorted { $0.stableID < $1.stableID }
        self.isLoading = false
        
        // Log the certificate load for security audit
        if !loadedCerts.isEmpty {
            Task { @MainActor in
                SecurityAuditLogger.shared.log(
                    .tlsVerification,
                    details: "Loaded \(loadedCerts.count) pinned certificate(s)",
                    severity: .info
                )
            }
        }
    }
    
    /// Deletes a pinned certificate from the TLS store.
    ///
    /// This removes the certificate fingerprint from UserDefaults, which means the
    /// next connection to this gateway will trigger a new TOFU verification.
    private func deleteCertificate(_ cert: StoredCertificate) {
        let suiteName = "bot.molt.shared"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return
        }
        
        // Remove from UserDefaults
        defaults.removeObject(forKey: cert.id)
        defaults.synchronize()
        
        // Remove from local list
        self.certificates.removeAll { $0.id == cert.id }
        
        // Log the deletion for security audit
        Task { @MainActor in
            SecurityAuditLogger.shared.log(
                .tlsVerification,
                details: "Removed pinned certificate for \(cert.stableID.prefix(8))...",
                severity: .warning
            )
        }
    }
}

#Preview {
    NavigationStack {
        TLSCertificateView()
    }
}
