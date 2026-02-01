import AVFoundation
import SwiftUI

struct PrivacySettingsView: View {
    @AppStorage("camera.enabled") private var cameraEnabled = true
    @AppStorage(VoiceWakePreferences.enabledKey) private var voiceWakeEnabled = false
    @AppStorage("location.enabledMode") private var locationModeRaw = "off"
    @AppStorage("analytics.enabled") private var analyticsEnabled = false
    
    @State private var showPermissionDeniedAlert = false
    @State private var deniedPermissionType: String = ""
    
    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .font(.title2)
                            .foregroundStyle(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Privacy First")
                                .font(.headline)
                            
                            Text("Your data stays on your gateway")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Text("Moltbot processes all data on your self-hosted gateway. No information is sent to third-party servers without your explicit consent.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            Section {
                Toggle("Camera Access", isOn: self.$cameraEnabled)
                    .onChange(of: self.cameraEnabled) { _, newValue in
                        if newValue {
                            // Check system permission
                            self.checkCameraPermission()
                        }
                    }
                
                Toggle("Microphone (Voice Wake)", isOn: self.$voiceWakeEnabled)
                    .onChange(of: self.voiceWakeEnabled) { _, newValue in
                        if newValue {
                            // Check system permission
                            self.checkMicrophonePermission()
                        }
                    }
                
                Picker("Location Sharing", selection: self.$locationModeRaw) {
                    Text("Off").tag("off")
                    Text("When in Use").tag("whenInUse")
                    Text("Always").tag("always")
                }
            } header: {
                Text("Permissions")
            } footer: {
                Text("These permissions allow Moltbot to access device features. You can change them anytime in iOS Settings.")
            }
            
            Section {
                Toggle("Usage Analytics", isOn: self.$analyticsEnabled)
            } header: {
                Text("Analytics")
            } footer: {
                Text("Help improve Moltbot by sharing anonymous usage data. This data never leaves your gateway unless you explicitly enable cloud sync.")
            }
            
            Section {
                NavigationLink {
                    DataManagementView()
                } label: {
                    Label("Data Management", systemImage: "folder.fill")
                }
                
                NavigationLink {
                    PrivacyPolicyView()
                } label: {
                    Label("Privacy Policy", systemImage: "doc.text.fill")
                }
                
                Link(destination: URL(string: "https://docs.molt.bot/privacy")!) {
                    HStack {
                        Label("Learn More", systemImage: "info.circle.fill")
                        Spacer()
                        Image(systemName: "arrow.up.forward")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Information")
            }
        }
        .navigationTitle("Privacy & Security")
        .navigationBarTitleDisplayMode(.inline)
        .alert(
            NSLocalizedString("privacy.permissionRequired", value: "Permission Required", comment: "Alert title when system permission is denied"),
            isPresented: self.$showPermissionDeniedAlert
        ) {
            Button(NSLocalizedString("privacy.openSettings", value: "Open Settings", comment: "Button to open iOS Settings")) {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            }
            Button(L10n.Common.cancel, role: .cancel) {}
        } message: {
            Text(String(
                format: NSLocalizedString(
                    "privacy.permissionDenied.message",
                    value: "%@ access is denied at the system level. Please enable it in Settings to use this feature.",
                    comment: "Alert message explaining permission is denied. %@ is replaced with permission type (e.g., Camera, Microphone)"
                ),
                self.deniedPermissionType
            ))
        }
    }
    
    private func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .notDetermined:
            // Request permission
            AVCaptureDevice.requestAccess(for: .video) { granted in
                Task { @MainActor in
                    if !granted {
                        self.cameraEnabled = false
                        self.deniedPermissionType = "Camera"
                        self.showPermissionDeniedAlert = true
                    }
                }
            }
        case .denied, .restricted:
            // Permission denied at system level, show alert to open Settings
            self.cameraEnabled = false
            self.deniedPermissionType = "Camera"
            self.showPermissionDeniedAlert = true
        case .authorized:
            // Already authorized, nothing to do
            break
        @unknown default:
            break
        }
    }
    
    private func checkMicrophonePermission() {
        let status = AVAudioSession.sharedInstance().recordPermission
        switch status {
        case .undetermined:
            // Request permission
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                Task { @MainActor in
                    if !granted {
                        self.voiceWakeEnabled = false
                        self.deniedPermissionType = "Microphone"
                        self.showPermissionDeniedAlert = true
                    }
                }
            }
        case .denied:
            // Permission denied at system level, show alert to open Settings
            self.voiceWakeEnabled = false
            self.deniedPermissionType = "Microphone"
            self.showPermissionDeniedAlert = true
        case .granted:
            // Already authorized, nothing to do
            break
        @unknown default:
            break
        }
    }
}

private struct DataManagementView: View {
    @State private var showingDeleteAlert = false
    
    var body: some View {
        Form {
            Section {
                Text("All your data is stored on your gateway. Moltbot on this device only stores connection credentials and preferences.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Section {
                Button(role: .destructive) {
                    self.showingDeleteAlert = true
                } label: {
                    Label("Clear Local Data", systemImage: "trash.fill")
                }
            } header: {
                Text("Local Data")
            } footer: {
                Text("This will clear all local preferences and require you to set up the app again. Your gateway data will not be affected.")
            }
        }
        .navigationTitle("Data Management")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Clear Local Data?", isPresented: self.$showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                self.clearLocalData()
            }
        } message: {
            Text("This will clear all local preferences and connection credentials. You'll need to set up the app again.")
        }
    }
    
    private func clearLocalData() {
        // Clear UserDefaults
        let defaults = UserDefaults.standard
        let domain = Bundle.main.bundleIdentifier!
        defaults.removePersistentDomain(forName: domain)
        defaults.synchronize()
    }
}

private struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy")
                    .font(.largeTitle.bold())
                    .padding(.bottom, 8)
                
                Group {
                    PolicySection(
                        title: "Data Collection",
                        content: "Moltbot does not collect, store, or transmit any personal data to third-party servers. All processing happens on your self-hosted gateway.")
                    
                    PolicySection(
                        title: "Local Storage",
                        content: "The app stores gateway connection credentials and user preferences locally on your device. This data is protected by iOS security features.")
                    
                    PolicySection(
                        title: "Permissions",
                        content: "Camera, microphone, and location permissions are only used when explicitly requested by you through the gateway. These permissions can be revoked at any time in iOS Settings.")
                    
                    PolicySection(
                        title: "Third-Party Services",
                        content: "Moltbot does not integrate with any third-party analytics, advertising, or tracking services.")
                    
                    PolicySection(
                        title: "Changes to Policy",
                        content: "Any updates to this privacy policy will be communicated through app updates and reflected in our documentation.")
                }
                
                Text("Last updated: January 2026")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 20)
            }
            .padding(20)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PolicySection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(self.title)
                .font(.headline)
            
            Text(self.content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
