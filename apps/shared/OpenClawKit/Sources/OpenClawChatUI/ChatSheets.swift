import Observation
import SwiftUI

@MainActor
struct ChatSessionsSheet: View {
    @Bindable var viewModel: OpenClawChatViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var sessionToClear: OpenClawChatSessionEntry?

    var body: some View {
        NavigationStack {
            List {
                ForEach(self.viewModel.sessions) { session in
                    Button {
                        self.viewModel.switchSession(to: session.key)
                        self.dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.displayName ?? session.key)
                                    .font(.system(.body, design: .monospaced))
                                    .lineLimit(1)
                                if let updatedAt = session.updatedAt, updatedAt > 0 {
                                    Text(Date(timeIntervalSince1970: updatedAt / 1000).formatted(
                                        date: .abbreviated,
                                        time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            if session.key == self.viewModel.sessionKey {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                                    .font(.caption.weight(.semibold))
                            }
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            self.sessionToClear = session
                        } label: {
                            Label("Clear", systemImage: "eraser.line.dashed")
                        }
                        .tint(.orange)
                    }
                }
            }
            .confirmationDialog(
                "Clear conversation?",
                isPresented: Binding(
                    get: { self.sessionToClear != nil },
                    set: { if !$0 { self.sessionToClear = nil } }),
                titleVisibility: .visible)
            {
                if let session = self.sessionToClear {
                    Button("Clear \"\(session.displayName ?? session.key)\"", role: .destructive) {
                        self.viewModel.clearSession(session.key)
                        self.sessionToClear = nil
                    }
                }
            } message: {
                Text("This will clear all messages in this session. The session itself will remain.")
            }
            .navigationTitle("Sessions")
            .toolbar {
                #if os(macOS)
                ToolbarItem(placement: .automatic) {
                    Button {
                        self.viewModel.refreshSessions(limit: 200)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        self.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                #else
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        self.viewModel.refreshSessions(limit: 200)
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        self.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                #endif
            }
            .onAppear {
                self.viewModel.refreshSessions(limit: 200)
            }
        }
    }
}
