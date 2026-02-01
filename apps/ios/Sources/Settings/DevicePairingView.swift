import SwiftUI
import MoltbotKit

/// Device pairing view for authorizing this device with a gateway.
///
/// The pairing flow works as follows:
/// 1. User enters an 8-character pairing code displayed on the gateway
/// 2. The app validates the code format (alphanumeric, uppercase)
/// 3. The app sends a pairing verification request to the gateway
/// 4. On success, the device receives authorization tokens
///
/// Note: The gateway must be connected for pairing to work. The actual pairing
/// verification is handled through the GatewayNodeSession's request mechanism.
struct DevicePairingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var pairingCode: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
    /// The gateway session to use for pairing requests.
    /// When nil, the view will show an error about gateway connectivity.
    let gatewaySession: GatewayNodeSession?
    
    init(gatewaySession: GatewayNodeSession? = nil) {
        self.gatewaySession = gatewaySession
    }
    
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
                        // Sanitize input: uppercase, alphanumeric only, no ambiguous chars, max 8 chars
                        // Filter out 0, O, 1, I, L to match validation logic in isValidPairingCode
                        self.pairingCode = String(
                            newValue.uppercased()
                                .filter { ($0.isLetter || $0.isNumber) && !"0O1IL".contains($0) }
                                .prefix(8)
                        )
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
                    self.logPairingEvent(success: false, details: "User cancelled pairing")
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
        
        Task {
            do {
                // Verify gateway is connected
                guard let gateway = self.gatewaySession else {
                    throw PairingError.gatewayNotConnected
                }
                
                // Validate pairing code format before sending
                guard self.isValidPairingCode(self.pairingCode) else {
                    throw PairingError.invalidCodeFormat
                }
                
                // Send pairing verification request to gateway.
                // The gateway method "device.pair.verify" expects:
                // - code: the 8-character pairing code
                // Returns success if the code matches a pending pairing request.
                // Note: The response is intentionally ignored because on success,
                // the gateway automatically issues device tokens via the connect flow.
                // The pairing verification only confirms the code is valid.
                let paramsPayload = ["code": self.pairingCode]
                let paramsData = try JSONEncoder().encode(paramsPayload)
                guard let paramsJSON = String(data: paramsData, encoding: .utf8) else {
                    throw PairingError.invalidCodeFormat
                }
                _ = try await gateway.request(
                    method: "device.pair.verify",
                    paramsJSON: paramsJSON,
                    timeoutSeconds: 30
                )
                
                await MainActor.run {
                    self.isLoading = false
                    self.successMessage = "Device paired successfully!"
                    self.logPairingEvent(success: true, details: "Device paired with code")
                    
                    // Auto-dismiss after success
                    Task {
                        try? await Task.sleep(for: .seconds(2))
                        await MainActor.run {
                            self.dismiss()
                        }
                    }
                }
            } catch let error as PairingError {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.userFacingMessage
                    self.logPairingEvent(success: false, details: error.logMessage)
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    // Don't expose internal error details to user
                    self.errorMessage = "Pairing failed. Please check the code and try again."
                    // Include error type for debugging while keeping sensitive details out
                    let errorType = String(describing: type(of: error))
                    self.logPairingEvent(success: false, details: "Pairing request failed: \(errorType)")
                }
            }
        }
    }
    
    /// Validates the pairing code format.
    /// Valid codes are 8 characters, alphanumeric, no ambiguous characters (0, O, 1, I, L).
    private func isValidPairingCode(_ code: String) -> Bool {
        guard code.count == 8 else { return false }
        let ambiguousChars = CharacterSet(charactersIn: "0O1IL")
        return code.unicodeScalars.allSatisfy { scalar in
            CharacterSet.alphanumerics.contains(scalar) && !ambiguousChars.contains(scalar)
        }
    }
    
    /// Logs a pairing event to the security audit log.
    private func logPairingEvent(success: Bool, details: String) {
        Task { @MainActor in
            SecurityAuditLogger.shared.log(
                .authenticationAttempt,
                details: details,
                severity: success ? .info : .warning
            )
        }
    }
}

/// Errors that can occur during device pairing.
/// Note: codeExpired, codeNotFound, and alreadyPaired are reserved for future use
/// when gateway response parsing is implemented to return specific error codes.
private enum PairingError: Error {
    case gatewayNotConnected
    case invalidCodeFormat
    /// Reserved: Gateway returns this when pairing code has expired (1 hour TTL)
    case codeExpired
    /// Reserved: Gateway returns this when pairing code doesn't match any pending request
    case codeNotFound
    /// Reserved: Gateway returns this when device is already paired
    case alreadyPaired
    
    var userFacingMessage: String {
        switch self {
        case .gatewayNotConnected:
            return "Not connected to gateway. Please check your connection."
        case .invalidCodeFormat:
            return "Invalid code format. Please check and try again."
        case .codeExpired:
            return "This pairing code has expired. Please request a new one."
        case .codeNotFound:
            return "Pairing code not found. Please verify the code."
        case .alreadyPaired:
            return "This device is already paired."
        }
    }
    
    var logMessage: String {
        switch self {
        case .gatewayNotConnected: return "Gateway not connected"
        case .invalidCodeFormat: return "Invalid code format"
        case .codeExpired: return "Code expired"
        case .codeNotFound: return "Code not found"
        case .alreadyPaired: return "Device already paired"
        }
    }
}

#Preview {
    NavigationStack {
        DevicePairingView(gatewaySession: nil)
    }
}
