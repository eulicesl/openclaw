import SwiftUI

struct WelcomeView: View {
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Hero Section
            VStack(spacing: 16) {
                // App Icon Display
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing))
                    .frame(width: 120, height: 120)
                    .overlay {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 54, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    .shadow(color: .black.opacity(0.2), radius: 20, y: 10)
                
                Text("Welcome to Moltbot")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Your Personal AI Assistant")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            Spacer()
            
            // Features List
            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(
                    icon: "waveform.circle.fill",
                    title: "Voice Wake",
                    description: "Activate hands-free with voice commands",
                    color: .blue)
                
                FeatureRow(
                    icon: "bubble.left.and.bubble.right.fill",
                    title: "Chat Interface",
                    description: "Natural conversation experience",
                    color: .green)
                
                FeatureRow(
                    icon: "rectangle.on.rectangle.fill",
                    title: "Canvas Mode",
                    description: "Rich visual interactions and content",
                    color: .purple)
                
                FeatureRow(
                    icon: "lock.shield.fill",
                    title: "Privacy First",
                    description: "Your data stays on your gateway",
                    color: .orange)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
            
            // Continue Button
            Button(action: self.onContinue) {
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
    }
}

private struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: self.icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(self.color)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(self.color.opacity(0.15)))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(self.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(self.description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
    }
}
