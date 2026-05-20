@preconcurrency import ActivityKit
import Foundation
import os

/// Minimal Live Activity lifecycle focused on connection health + stale cleanup.
@MainActor
final class LiveActivityManager {
    static let shared = LiveActivityManager()

    private let logger = Logger(subsystem: "ai.openclaw.ios", category: "LiveActivity")
    private let connectingStaleSeconds: TimeInterval = 120
    private let hydrationStaleSeconds: TimeInterval = 300
    private var currentActivity: Activity<OpenClawActivityAttributes>?
    private var activityStartDate: Date = .now

    /// Tracks the last known non-working connection state so `handleWorking(nil)`
    /// restores the correct state rather than blindly resetting to idle.
    private enum ConnectionState { case idle, connecting, disconnected }
    private var lastConnectionState: ConnectionState = .idle

    private init() {
        self.hydrateCurrentAndPruneDuplicates()
    }

    var isActive: Bool {
        guard let activity = self.currentActivity else { return false }
        guard activity.activityState == .active else {
            self.currentActivity = nil
            return false
        }
        return true
    }

    func startActivity(agentName: String, sessionKey: String) {
        self.showConnecting(agentName: agentName, sessionKey: sessionKey)
    }

    func showConnecting(statusText: String = "Connecting...", agentName: String, sessionKey: String) {
        self.hydrateCurrentAndPruneDuplicates()

        if let current = self.currentActivity {
            if current.attributes.agentName == agentName,
               current.attributes.sessionKey == sessionKey
            {
                self.handleConnecting(statusText: statusText)
                return
            }

            Task {
                await current.end(
                    ActivityContent(state: self.disconnectedState(), staleDate: nil),
                    dismissalPolicy: .immediate)
            }
            self.currentActivity = nil
        }

        self.startFreshActivity(
            agentName: agentName,
            sessionKey: sessionKey,
            initialState: self.connectingState(statusText: statusText),
            nextConnectionState: .connecting,
            staleDate: Date().addingTimeInterval(self.connectingStaleSeconds))
    }

    func showAttention(statusText: String, agentName: String, sessionKey: String) {
        self.hydrateCurrentAndPruneDuplicates()

        if self.currentActivity == nil {
            self.startFreshActivity(
                agentName: agentName,
                sessionKey: sessionKey,
                initialState: self.attentionState(statusText: statusText),
                nextConnectionState: self.lastConnectionState,
                staleDate: nil)
            return
        }

        self.updateCurrent(state: self.attentionState(statusText: statusText), staleDate: nil)
    }

    func refreshIdentity(agentName: String, sessionKey: String) {
        self.hydrateCurrentAndPruneDuplicates()

        guard let current = self.currentActivity else {
            self.startActivity(agentName: agentName, sessionKey: sessionKey)
            return
        }
        guard current.attributes.agentName != agentName || current.attributes.sessionKey != sessionKey else {
            return
        }

        let state = current.content.state
        Task {
            await current.end(
                ActivityContent(state: self.disconnectedState(), staleDate: nil),
                dismissalPolicy: .immediate)
        }
        self.currentActivity = nil

        self.startFreshActivity(
            agentName: agentName,
            sessionKey: sessionKey,
            initialState: state,
            nextConnectionState: self.lastConnectionState,
            staleDate: nil)
    }

    func handleConnecting(statusText: String = "Connecting...") {
        self.lastConnectionState = .connecting
        self.updateCurrent(
            state: self.connectingState(statusText: statusText),
            staleDate: Date().addingTimeInterval(self.connectingStaleSeconds))
    }

    func handleReconnect() {
        self.lastConnectionState = .idle
        self.updateCurrent(state: self.idleState(), staleDate: nil)
    }

    func handleDisconnect() {
        self.lastConnectionState = .disconnected
        self.updateCurrent(state: self.disconnectedState(), staleDate: nil)
    }

    func endActivity(reason: String) {
        guard let activity = self.currentActivity else { return }
        self.currentActivity = nil
        self.logger.info("ending live activity reason=\(reason, privacy: .public)")
        Task {
            await activity.end(
                ActivityContent(state: self.disconnectedState(), staleDate: nil),
                dismissalPolicy: .immediate)
        }
    }

    /// Call when the agent begins processing a task.
    /// - Parameter task: Short human-readable description (e.g. "Building iOS app...").
    ///   Pass `nil` to complete the task and restore the previous connection state.
    func handleWorking(task: String?) {
        if let task {
            self.updateCurrent(state: self.workingState(task: task), staleDate: nil)
            self.logger.info("live activity working task=\(task, privacy: .private)")
        } else {
            let restored: OpenClawActivityAttributes.ContentState = switch self.lastConnectionState {
            case .idle: self.idleState()
            case .connecting: self.connectingState()
            case .disconnected: self.disconnectedState()
            }
            self.updateCurrent(state: restored, staleDate: nil)
            self.logger
                .info("live activity restored state=\(String(describing: self.lastConnectionState), privacy: .public)")
        }
    }

    // MARK: - Private helpers

    private func hydrateCurrentAndPruneDuplicates() {
        let active = Activity<OpenClawActivityAttributes>.activities
        guard !active.isEmpty else {
            self.currentActivity = nil
            return
        }

        let now = Date()
        let candidates = active.filter { activity in
            let state = activity.content.state
            guard activity.activityState == .active else { return false }
            guard !state.isIdle, !state.isDisconnected else { return false }
            return now.timeIntervalSince(state.startedAt) < self.hydrationStaleSeconds
        }

        guard !candidates.isEmpty else {
            self.currentActivity = nil
            for activity in active {
                self.end(activity: activity)
            }
            return
        }

        let keeper = candidates.max { lhs, rhs in
            lhs.content.state.startedAt < rhs.content.state.startedAt
        } ?? candidates[0]

        self.currentActivity = keeper
        self.activityStartDate = keeper.content.state.startedAt

        let state = keeper.content.state
        if state.isDisconnected {
            self.lastConnectionState = .disconnected
        } else if state.isConnecting {
            self.lastConnectionState = .connecting
        } else {
            self.lastConnectionState = .idle
        }

        let stale = active.filter { $0.id != keeper.id }
        for activity in stale {
            self.end(activity: activity)
        }
    }

    private func startFreshActivity(
        agentName: String,
        sessionKey: String,
        initialState: OpenClawActivityAttributes.ContentState,
        nextConnectionState: ConnectionState,
        staleDate: Date?)
    {
        let authInfo = ActivityAuthorizationInfo()
        guard authInfo.areActivitiesEnabled else {
            self.logger.info("Live Activities disabled; skipping start")
            return
        }

        self.activityStartDate = .now
        let normalizedInitialState = OpenClawActivityAttributes.ContentState(
            statusText: initialState.statusText,
            isIdle: initialState.isIdle,
            isDisconnected: initialState.isDisconnected,
            isConnecting: initialState.isConnecting,
            isWorking: initialState.isWorking,
            taskDescription: initialState.taskDescription,
            startedAt: self.activityStartDate)
        let attributes = OpenClawActivityAttributes(agentName: agentName, sessionKey: sessionKey)

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(state: normalizedInitialState, staleDate: staleDate),
                pushType: nil)
            self.currentActivity = activity
            self.lastConnectionState = nextConnectionState
            self.logger.info("started live activity id=\(activity.id, privacy: .public)")
        } catch {
            self.logger.error("failed to start live activity: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func updateCurrent(state: OpenClawActivityAttributes.ContentState, staleDate: Date?) {
        guard let activity = self.currentActivity, activity.activityState == .active else {
            self.currentActivity = nil
            return
        }
        Task {
            await activity.update(ActivityContent(state: state, staleDate: staleDate))
        }
    }

    private func end(activity: Activity<OpenClawActivityAttributes>) {
        Task {
            await activity.end(
                ActivityContent(state: self.disconnectedState(), staleDate: nil),
                dismissalPolicy: .immediate)
        }
    }

    private func connectingState(statusText: String = "Connecting...") -> OpenClawActivityAttributes.ContentState {
        OpenClawActivityAttributes.ContentState(
            statusText: statusText,
            isIdle: false,
            isDisconnected: false,
            isConnecting: true,
            isWorking: false,
            taskDescription: nil,
            startedAt: self.activityStartDate)
    }

    private func attentionState(statusText: String) -> OpenClawActivityAttributes.ContentState {
        OpenClawActivityAttributes.ContentState(
            statusText: statusText,
            isIdle: false,
            isDisconnected: false,
            isConnecting: false,
            isWorking: false,
            taskDescription: nil,
            startedAt: self.activityStartDate)
    }

    private func idleState() -> OpenClawActivityAttributes.ContentState {
        OpenClawActivityAttributes.ContentState(
            statusText: "Connected",
            isIdle: true,
            isDisconnected: false,
            isConnecting: false,
            isWorking: false,
            taskDescription: nil,
            startedAt: self.activityStartDate)
    }

    private func disconnectedState() -> OpenClawActivityAttributes.ContentState {
        OpenClawActivityAttributes.ContentState(
            statusText: "Disconnected",
            isIdle: false,
            isDisconnected: true,
            isConnecting: false,
            isWorking: false,
            taskDescription: nil,
            startedAt: self.activityStartDate)
    }

    private func workingState(task: String) -> OpenClawActivityAttributes.ContentState {
        let startedAt: Date = if let current = self.currentActivity,
                                 current.content.state.isWorking,
                                 current.content.state.taskDescription == task
        {
            current.content.state.startedAt
        } else {
            .now
        }

        return OpenClawActivityAttributes.ContentState(
            statusText: task,
            isIdle: false,
            isDisconnected: false,
            isConnecting: false,
            isWorking: true,
            taskDescription: task,
            startedAt: startedAt)
    }
}
