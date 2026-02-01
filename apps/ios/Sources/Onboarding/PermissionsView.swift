import AVFoundation
import SwiftUI
import UserNotifications

struct PermissionsView: View {
    let onComplete: () -> Void
    
    @State private var showingPermissionAlert = false
    @State private var currentPermission: PermissionType?
    
    private enum PermissionType: String, CaseIterable {
        case microphone
        case camera
        case localNetwork
        case notifications
        
        var icon: String {
            switch self {
            case .microphone: "mic.fill"
            case .camera: "camera.fill"
            case .localNetwork: "network"
            case .notifications: "bell.fill"
            }
        }
        
        var title: String {
            switch self {
            case .microphone: "Microphone"
            case .camera: "Camera"
            case .localNetwork: "Local Network"
            case .notifications: "Notifications"
            }
        }
        
        var description: String {
            switch self {
            case .microphone: "Required for Voice Wake and Talk Mode"
            case .camera: "Capture photos and videos on request"
            case .localNetwork: "Discover gateways on your network"
            case .notifications: "Stay updated with important alerts"
            }
        }
        
        var color: Color {
            switch self {
            case .microphone: .blue
            case .camera: .purple
            case .localNetwork: .green
            case .notifications: .orange
            }
        }
        
        var isRequired: Bool {
            switch self {
            case .microphone, .localNetwork: true
            case .camera, .notifications: false
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "hand.raised.fill")
                    .font(.system(size: 54, weight: .medium))
                    .foregroundStyle(.blue)
                    .padding(.top, 60)
                
                Text("Permissions")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.primary)
                
                Text("Moltbot needs a few permissions to work properly. You can always change these in Settings later.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, 40)
            
            // Permissions List
            VStack(spacing: 16) {
                ForEach(PermissionType.allCases, id: \.self) { permission in
                    PermissionRow(permission: permission) {
                        self.currentPermission = permission
                        self.showingPermissionAlert = true
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Continue Button
            Button(action: self.onComplete) {
                Text("Continue")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.blue))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
        .alert(
            self.currentPermission?.title ?? "Permission",
            isPresented: self.$showingPermissionAlert,
            presenting: self.currentPermission)
        { permission in
            Button("Allow") {
                // Trigger actual permission request
                self.requestPermission(permission)
            }
            Button("Not Now", role: .cancel) {}
        } message: { permission in
            Text(permission.description)
        }
    }
    
    private func requestPermission(_ permission: PermissionType) {
        switch permission {
        case .microphone:
            // Request microphone access - the callback result is intentionally
            // not stored as the permission will be checked when actually needed
            AVAudioSession.sharedInstance().requestRecordPermission { _ in }
            
        case .camera:
            // Request camera access
            AVCaptureDevice.requestAccess(for: .video) { _ in }
            
        case .localNetwork:
            // Local network permission is requested automatically when
            // the app attempts to use Bonjour/NWBrowser. There's no direct API
            // to request it - the prompt appears when network access is first attempted.
            break
            
        case .notifications:
            // Request notification access
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
        }
    }
}

private struct PermissionRow: View {
    let permission: PermissionsView.PermissionType
    let onTap: () -> Void
    
    var body: some View {
        Button(action: self.onTap) {
            HStack(spacing: 16) {
                Image(systemName: self.permission.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(self.permission.color)
                    .frame(width: 54, height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(self.permission.color.opacity(0.15)))
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(self.permission.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        if self.permission.isRequired {
                            Text("Required")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(Color.red))
                        }
                    }
                    
                    Text(self.permission.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.secondarySystemBackground)))
        }
        .buttonStyle(.plain)
    }
}
