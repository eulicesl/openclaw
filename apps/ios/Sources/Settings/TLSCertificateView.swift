import SwiftUI
import MoltbotKit

struct TLSCertificateView: View {
    @State private var certificates: [StoredCertificate] = []
    @State private var showDeleteConfirmation: StoredCertificate?
    
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
    }
    
    var body: some View {
        List {
            Section {
                Text("Moltbot uses TLS certificate pinning (TOFU - Trust On First Use) to secure connections to your gateway. Pinned certificates are stored locally.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            
            if self.certificates.isEmpty {
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
    
    private func loadCertificates() {
        // TODO: Load actual certificates from GatewayTLSStore
        // For now, this is a placeholder
        self.certificates = []
    }
    
    private func deleteCertificate(_ cert: StoredCertificate) {
        // TODO: Implement certificate deletion via GatewayTLSStore
        self.certificates.removeAll { $0.id == cert.id }
    }
}

#Preview {
    NavigationStack {
        TLSCertificateView()
    }
}
