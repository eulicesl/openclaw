import SwiftUI

struct LoadingView: View {
    let message: String?
    
    init(message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(.blue)
            
            if let message = self.message {
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String?
    let action: (() -> Void)?
    let actionTitle: String?
    
    init(
        icon: String,
        title: String,
        message: String? = nil,
        action: (() -> Void)? = nil,
        actionTitle: String? = nil)
    {
        self.icon = icon
        self.title = title
        self.message = message
        self.action = action
        self.actionTitle = actionTitle
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: self.icon)
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(.tertiary)
            
            VStack(spacing: 8) {
                Text(self.title)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                
                if let message = self.message {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            
            if let action = self.action, let actionTitle = self.actionTitle {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.blue))
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

struct ErrorView: View {
    let error: Error
    let retry: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 64, weight: .medium))
                .foregroundStyle(.orange)
            
            VStack(spacing: 8) {
                Text("Something Went Wrong")
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                
                Text(self.error.localizedDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            if let retry = self.retry {
                Button(action: retry) {
                    Text("Try Again")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.blue))
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
