import SwiftUI
import MoltbotKit

struct DevicePairingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var pairingCode: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    var body: some View {
        Form {
            Section {
                Text("Enter the 8-character pairing code shown by the gateway to authorize this device.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                
                TextField("Pairing Code", text: self.$pairingCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.system(.body, design: .monospaced))
                    .onChange(of: self.pairingCode) { _, newValue in
                        self.pairingCode = newValue.uppercased().filter { $0.isLetter || $0.isNumber }
                        if self.pairingCode.count > 8 {
                            self.pairingCode = String(self.pairingCode.prefix(8))
                        }
                    }
            } header: {
                Text("Device Authorization")
            }
            
            if let errorMessage = self.errorMessage {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }
            
            if let successMessage = self.successMessage {
                Section {
                    Label(successMessage, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }
            
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Gateway displays code", systemImage: "1.circle.fill")
                    Label("Enter code above", systemImage: "2.circle.fill")
                    Label("Tap Pair Device", systemImage: "3.circle.fill")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            } header: {
                Text("How to Pair")
            }
        }
        .navigationTitle("Pair Device")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    self.dismiss()
                }
                .disabled(self.isLoading)
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button("Pair") {
                    self.pairDevice()
                }
                .disabled(self.pairingCode.count != 8 || self.isLoading)
                .fontWeight(.semibold)
            }
        }
        .overlay {
            if self.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
            }
        }
    }
    
    private func pairDevice() {
        self.isLoading = true
        self.errorMessage = nil
        self.successMessage = nil
        
        // Simulate pairing request - in production, this would call the gateway
        Task {
            do {
                // TODO: Implement actual gateway pairing request
                // await gatewayController.pairWithCode(self.pairingCode)
                
                try await Task.sleep(for: .seconds(1))
                
                await MainActor.run {
                    self.isLoading = false
                    self.successMessage = "Device paired successfully!"
                    
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        await MainActor.run {
                            self.dismiss()
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = "Pairing failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DevicePairingView()
    }
}
