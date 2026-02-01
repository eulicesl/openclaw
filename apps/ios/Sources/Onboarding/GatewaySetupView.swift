import SwiftUI

struct GatewaySetupView: View {
    @Environment(GatewayConnectionController.self) private var controller
    let onComplete: () -> Void
    
    @State private var selectedGateway: GatewayDiscoveryModel.DiscoveredGateway?
    @State private var showManualSetup = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "network")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(.blue)
                        .padding(.top, 40)
                    
                    Text("Connect to Gateway")
                        .font(.title.bold())
                        .foregroundStyle(.primary)
                    
                    Text("Moltbot will automatically discover gateways on your local network")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom, 32)
                
                // Discovery Status
                HStack(spacing: 12) {
                    ProgressView()
                        .tint(.blue)
                    
                    Text(self.controller.discoveryStatusText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 24)
                
                // Discovered Gateways
                if self.controller.gateways.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "antenna.radiowaves.left.and.right.slash")
                            .font(.system(size: 54, weight: .light))
                            .foregroundStyle(.tertiary)
                        
                        Text("No Gateways Found")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Text("Make sure your gateway is running and connected to the same network")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.vertical, 40)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(self.controller.gateways, id: \.stableID) { gateway in
                                GatewayRow(
                                    gateway: gateway,
                                    isSelected: self.selectedGateway?.stableID == gateway.stableID)
                                {
                                    self.selectedGateway = gateway
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    if let selectedGateway = self.selectedGateway {
                        Button(action: {
                            Task {
                                await self.controller.connect(selectedGateway)
                                self.onComplete()
                            }
                        }) {
                            Text("Connect to \(selectedGateway.displayName ?? "Gateway")")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Color.blue))
                        }
                    }
                    
                    Button(action: { self.showManualSetup = true }) {
                        Text("Manual Setup")
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                    }
                    .padding(.bottom, 8)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color(.systemBackground))
            .sheet(isPresented: self.$showManualSetup) {
                ManualGatewaySetupSheet(onComplete: self.onComplete)
            }
        }
    }
}

private struct GatewayRow: View {
    let gateway: GatewayDiscoveryModel.DiscoveredGateway
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: self.onTap) {
            HStack(spacing: 16) {
                Image(systemName: self.gateway.tlsEnabled ? "lock.shield.fill" : "network")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(self.isSelected ? .white : .blue)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(self.isSelected ? Color.blue : Color.blue.opacity(0.15)))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(self.gateway.displayName ?? "Moltbot Gateway")
                        .font(.headline)
                        .foregroundStyle(self.isSelected ? .white : .primary)
                    
                    HStack(spacing: 8) {
                        if let host = self.gateway.lanHost {
                            Text(host)
                                .font(.caption)
                                .foregroundStyle(self.isSelected ? .white.opacity(0.8) : .secondary)
                        }
                        
                        if self.gateway.tlsEnabled {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.caption2)
                                Text("Secure")
                                    .font(.caption2)
                            }
                            .foregroundStyle(self.isSelected ? .white.opacity(0.9) : .green)
                        }
                    }
                }
                
                Spacer()
                
                if self.isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(self.isSelected ? Color.blue : Color(.secondarySystemBackground)))
        }
        .buttonStyle(.plain)
    }
}

private struct ManualGatewaySetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(GatewayConnectionController.self) private var controller
    let onComplete: () -> Void
    
    @State private var host = ""
    @State private var port = "18789"
    @State private var useTLS = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Host", text: self.$host)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    
                    TextField("Port", text: self.$port)
                        .keyboardType(.numberPad)
                    
                    Toggle("Use TLS", isOn: self.$useTLS)
                } header: {
                    Text("Gateway Address")
                } footer: {
                    Text("Enter your gateway's IP address or hostname. TLS is recommended for security.")
                }
            }
            .navigationTitle("Manual Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        self.dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Connect") {
                        Task {
                            await self.controller.connectManual(
                                host: self.host,
                                port: Int(self.port) ?? 18789,
                                useTLS: self.useTLS)
                            self.dismiss()
                            self.onComplete()
                        }
                    }
                    .disabled(self.host.isEmpty)
                }
            }
        }
    }
}
