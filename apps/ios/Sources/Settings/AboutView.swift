import SwiftUI

struct AboutView: View {
    @Environment(\.openURL) private var openURL
    
    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    private let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    
    var body: some View {
        Form {
            Section {
                VStack(spacing: 16) {
                    // App Icon
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing))
                        .frame(width: 100, height: 100)
                        .overlay {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 46, weight: .medium))
                                .foregroundStyle(.white)
                        }
                        .shadow(color: .black.opacity(0.2), radius: 16, y: 8)
                    
                    VStack(spacing: 4) {
                        Text("Moltbot")
                            .font(.title2.bold())
                        
                        Text("Version \(self.version) (\(self.build))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("Your Personal AI Assistant")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            .listRowBackground(Color.clear)
            
            Section {
                Link(destination: URL(string: "https://docs.molt.bot")!) {
                    HStack {
                        Label("Documentation", systemImage: "book.fill")
                        Spacer()
                        Image(systemName: "arrow.up.forward")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                }
                
                Link(destination: URL(string: "https://clawd.me")!) {
                    HStack {
                        Label("Website", systemImage: "globe")
                        Spacer()
                        Image(systemName: "arrow.up.forward")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                }
                
                Link(destination: URL(string: "https://github.com/steipete/moltbot")!) {
                    HStack {
                        Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                        Spacer()
                        Image(systemName: "arrow.up.forward")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Resources")
            }
            
            Section {
                NavigationLink {
                    LicensesView()
                } label: {
                    Label("Open Source Licenses", systemImage: "doc.text.fill")
                }
                
                Button {
                    self.openURL(URL(string: "https://docs.molt.bot/privacy")!)
                } label: {
                    Label("Privacy Policy", systemImage: "hand.raised.fill")
                }
                
                Button {
                    self.openURL(URL(string: "https://docs.molt.bot/support")!)
                } label: {
                    Label("Support", systemImage: "questionmark.circle.fill")
                }
            } header: {
                Text("Legal")
            }
            
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Moltbot was built for Molty, a space lobster AI assistant by Peter Steinberger and the community.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("© 2026 Moltbot Community")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct LicensesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Open Source Licenses")
                    .font(.title.bold())
                    .padding(.bottom, 8)
                
                LicenseSection(
                    name: "Moltbot",
                    license: "MIT License",
                    description: "Copyright © 2026 Moltbot Community. Permission is hereby granted, free of charge, to any person obtaining a copy of this software...")
                
                LicenseSection(
                    name: "SwiftUI",
                    license: "Apple",
                    description: "SwiftUI and related frameworks are provided by Apple Inc.")
                
                Text("For a complete list of dependencies and licenses, visit:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Link("github.com/steipete/moltbot", destination: URL(string: "https://github.com/steipete/moltbot")!)
                    .font(.caption)
            }
            .padding(20)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Licenses")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct LicenseSection: View {
    let name: String
    let license: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(self.name)
                    .font(.headline)
                
                Spacer()
                
                Text(self.license)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color(.secondarySystemBackground)))
            }
            
            Text(self.description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground)))
    }
}
