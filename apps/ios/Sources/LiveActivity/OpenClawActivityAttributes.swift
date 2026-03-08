import ActivityKit
import Foundation

/// Shared schema used by iOS app + Live Activity widget extension.
struct OpenClawActivityAttributes: ActivityAttributes {
    var agentName: String
    var sessionKey: String

    struct ContentState: Codable, Hashable {
        var statusText: String
        var isIdle: Bool
        var isDisconnected: Bool
        var isConnecting: Bool
        /// `true` when the agent is actively processing a task.
        var isWorking: Bool
        /// Short description of the current task (e.g. "Building iOS app…", "Searching…").
        /// Non-nil only when `isWorking` is `true`.
        var taskDescription: String?
        var startedAt: Date
    }
}

#if DEBUG
extension OpenClawActivityAttributes {
    static let preview = OpenClawActivityAttributes(agentName: "J.A.R.V.I.S.", sessionKey: "main")
}

extension OpenClawActivityAttributes.ContentState {
    static let connecting = OpenClawActivityAttributes.ContentState(
        statusText: "Connecting...",
        isIdle: false,
        isDisconnected: false,
        isConnecting: true,
        isWorking: false,
        taskDescription: nil,
        startedAt: .now)

    static let idle = OpenClawActivityAttributes.ContentState(
        statusText: "Connected",
        isIdle: true,
        isDisconnected: false,
        isConnecting: false,
        isWorking: false,
        taskDescription: nil,
        startedAt: .now)

    static let disconnected = OpenClawActivityAttributes.ContentState(
        statusText: "Disconnected",
        isIdle: false,
        isDisconnected: true,
        isConnecting: false,
        isWorking: false,
        taskDescription: nil,
        startedAt: .now)

    static func working(task: String) -> OpenClawActivityAttributes.ContentState {
        OpenClawActivityAttributes.ContentState(
            statusText: task,
            isIdle: false,
            isDisconnected: false,
            isConnecting: false,
            isWorking: true,
            taskDescription: task,
            startedAt: .now)
    }
}
#endif
