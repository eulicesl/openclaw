# Mission Control -- Design Document

## 1. Architecture Overview

Mission Control integrates into the existing iOS app as a **sheet-based surface**
presented from `RootCanvas`, following the established Chat and Settings patterns.
It introduces three new layers:

```
RootCanvas (overlay button + badge)
  |
  +-- MissionControlSheet (NavigationStack root)
  |     |-- FleetView (gateway/session list + detail)
  |     |-- ApprovalsInboxView (approval list + detail + actions)
  |     +-- AlertsFeedView (alert list + filters + acknowledge)
  |
  +-- MissionControlModel (@Observable state)
  |
  +-- MissionControlTransport (GatewayNodeSession RPC adapter)
```

### Why a Sheet, Not a Tab

The OpenClaw iOS app uses a canvas-first layout (`RootCanvas` renders a full-
screen `ScreenTab` with floating overlay buttons). There is no persistent tab bar
in the primary UI path (`OpenClawApp` loads `RootCanvas`, not `RootTabs`).

Adding Mission Control as a sheet is consistent with Chat and Settings, avoids
disrupting the canvas-first experience, and follows Apple HIG guidance that sheets
are appropriate for focused tasks and secondary workflows that don't need to be
visible at all times.

The overlay button with a badge provides persistent glanceability -- the operator
sees the alert/approval count without leaving the canvas.

---

## 2. Navigation Architecture

### 2.1 Entry Point

`RootCanvas.swift` changes:

```swift
// PresentedSheet enum -- add case
private enum PresentedSheet: Identifiable {
    case settings
    case chat
    case quickSetup
    case missionControl  // NEW

    var id: Int {
        switch self {
        case .settings: 0
        case .chat: 1
        case .quickSetup: 2
        case .missionControl: 3
        }
    }
}
```

The overlay button lives in `CanvasContent`'s trailing VStack, guarded by an
`@AppStorage` toggle:

```swift
@AppStorage("missionControl.enabled") private var mcEnabled: Bool = false

// In CanvasContent body, inside the VStack of OverlayButtons:
if mcEnabled {
    ZStack(alignment: .topTrailing) {
        OverlayButton(
            systemImage: "square.grid.2x2.fill",
            brighten: brightenButtons
        ) {
            openMissionControl()
        }
        .accessibilityLabel("Mission Control")

        if mcModel.badgeCount > 0 {
            BadgeView(count: mcModel.badgeCount)
        }
    }
}
```

### 2.2 Sheet Presentation

```swift
// In RootCanvas .sheet(item:) switch:
case .missionControl:
    MissionControlSheet()
        .environment(mcModel)
        .environment(appModel)
```

### 2.3 Internal Navigation

`MissionControlSheet` uses a single `NavigationStack` with programmatic or
link-based push:

```
MissionControlSheet (List, grouped)
  +-- Section "Fleet"
  |     +-- NavigationLink -> GatewayDetailView
  |           +-- NavigationLink -> SessionDetailView
  |                 +-- Session actions (inline)
  +-- Section "Approvals"
  |     +-- NavigationLink -> ApprovalDetailView
  +-- Section "Alerts"
        +-- (inline list with swipe actions)
```

All detail views use `.navigationBarTitleDisplayMode(.inline)`.

### 2.4 Deep Link Navigation

Deep links set `presentedSheet = .missionControl` and store a pending
`MissionControlDeepLink` value that the sheet reads on appear:

```swift
enum MissionControlDeepLink: Equatable {
    case approval(id: String)
    case alert(id: String)
    case session(gatewayId: String, sessionKey: String)
}
```

The sheet's `NavigationStack` uses a `path` binding to programmatically push
to the target view when a deep link is active.

---

## 3. State Model

### 3.1 MissionControlModel

```swift
@MainActor
@Observable
final class MissionControlModel {
    // --- State ---
    var gateways: [MCGateway] = []
    var sessions: [MCSession] = []
    var approvals: [MCApproval] = []
    var alerts: [MCAlert] = []

    var isLoading: Bool = false
    var loadError: String?

    // --- Computed ---
    var pendingApprovalCount: Int { approvals.filter { !$0.isResolved }.count }
    var unresolvedAlertCount: Int { alerts.filter { !$0.isAcknowledged }.count }
    var badgeCount: Int { pendingApprovalCount + unresolvedAlertCount }

    // --- Transport ---
    @ObservationIgnored private var transport: MissionControlTransport?
    @ObservationIgnored private let logger = Logger(
        subsystem: "ai.openclaw.ios", category: "MissionControl"
    )

    func configure(gateway: GatewayNodeSession) {
        self.transport = MissionControlTransport(gateway: gateway)
    }

    // --- Data Loading ---
    func loadAll() async { ... }
    func loadFleet() async { ... }
    func loadApprovals() async { ... }
    func loadAlerts() async { ... }

    // --- Mutations ---
    func respondToApproval(id: String, approved: Bool, note: String?) async throws { ... }
    func acknowledgeAlert(id: String) async throws { ... }

    // --- Test Accessors ---
    func _test_setGateways(_ gateways: [MCGateway]) { self.gateways = gateways }
    func _test_setApprovals(_ approvals: [MCApproval]) { self.approvals = approvals }
}
```

### 3.2 Domain Types

All types live in `MissionControlTypes.swift`:

```swift
struct MCGateway: Identifiable, Codable, Sendable {
    let id: String          // stableID
    let name: String
    let status: MCStatus
    let agentCount: Int
    let uptimeMs: Int?
    let version: String?
}

struct MCSession: Identifiable, Codable, Sendable {
    let id: String          // composite: gatewayId + sessionKey
    let gatewayId: String
    let sessionKey: String
    let agentName: String?
    let status: MCSessionStatus
    let model: String?
    let totalTokens: Int?
    let updatedAt: Double?
}

struct MCApproval: Identifiable, Codable, Sendable {
    let id: String
    let type: MCApprovalType
    let requesterContext: String
    let gatewayId: String
    let sessionKey: String?
    let createdAt: Double
    var isResolved: Bool
    var resolution: MCApprovalResolution?
}

struct MCAlert: Identifiable, Codable, Sendable {
    let id: String
    let severity: MCAlertSeverity
    let title: String
    let source: String      // gateway name or agent id
    let gatewayId: String
    let sessionKey: String?
    let createdAt: Double
    var isAcknowledged: Bool
}

enum MCStatus: String, Codable, Sendable {
    case online, offline, error, connecting
}

enum MCSessionStatus: String, Codable, Sendable {
    case idle, running, errored, completed
}

enum MCApprovalType: String, Codable, Sendable {
    case pairing, toolUse, fileAccess, other
}

enum MCApprovalResolution: String, Codable, Sendable {
    case approved, denied
}

enum MCAlertSeverity: String, Codable, Sendable, CaseIterable {
    case critical, warning, info
}
```

### 3.3 Ownership

`RootCanvas` owns the `MissionControlModel` instance as `@State`:

```swift
@State private var mcModel = MissionControlModel()
```

When the gateway connects (detected via `appModel.gatewayServerName` change),
`RootCanvas` calls `mcModel.configure(gateway: appModel.operatorSession)`.

---

## 4. Transport Layer

### 4.1 MissionControlTransport

Follows `IOSGatewayChatTransport` exactly:

```swift
struct MissionControlTransport: Sendable {
    private static let logger = Logger(
        subsystem: "ai.openclaw.ios", category: "mc.transport"
    )
    private let gateway: GatewayNodeSession

    init(gateway: GatewayNodeSession) {
        self.gateway = gateway
    }

    func listFleet() async throws -> [MCGateway] {
        let res = try await gateway.request(
            method: "mc.fleet.list", paramsJSON: nil, timeoutSeconds: 15
        )
        return try JSONDecoder().decode(MCFleetListResponse.self, from: res).gateways
    }

    func listSessions(gatewayId: String?) async throws -> [MCSession] {
        struct Params: Codable { var gatewayId: String? }
        let data = try JSONEncoder().encode(Params(gatewayId: gatewayId))
        let json = String(data: data, encoding: .utf8)
        let res = try await gateway.request(
            method: "mc.sessions.list", paramsJSON: json, timeoutSeconds: 15
        )
        return try JSONDecoder().decode(MCSessionsListResponse.self, from: res).sessions
    }

    func listApprovals() async throws -> [MCApproval] {
        let res = try await gateway.request(
            method: "mc.approvals.list", paramsJSON: nil, timeoutSeconds: 15
        )
        return try JSONDecoder().decode(MCApprovalsListResponse.self, from: res).approvals
    }

    func respondToApproval(
        id: String, approved: Bool, note: String?
    ) async throws {
        struct Params: Codable {
            var id: String; var approved: Bool; var note: String?
        }
        let data = try JSONEncoder().encode(
            Params(id: id, approved: approved, note: note)
        )
        let json = String(data: data, encoding: .utf8)
        _ = try await gateway.request(
            method: "mc.approvals.respond", paramsJSON: json, timeoutSeconds: 10
        )
    }

    func listAlerts() async throws -> [MCAlert] {
        let res = try await gateway.request(
            method: "mc.alerts.list", paramsJSON: nil, timeoutSeconds: 15
        )
        return try JSONDecoder().decode(MCAlertsListResponse.self, from: res).alerts
    }

    func acknowledgeAlert(id: String) async throws {
        struct Params: Codable { var id: String }
        let data = try JSONEncoder().encode(Params(id: id))
        let json = String(data: data, encoding: .utf8)
        _ = try await gateway.request(
            method: "mc.alerts.acknowledge", paramsJSON: json, timeoutSeconds: 10
        )
    }

    func restartSession(
        gatewayId: String, sessionKey: String
    ) async throws {
        struct Params: Codable { var gatewayId: String; var sessionKey: String }
        let data = try JSONEncoder().encode(
            Params(gatewayId: gatewayId, sessionKey: sessionKey)
        )
        let json = String(data: data, encoding: .utf8)
        _ = try await gateway.request(
            method: "session.restart", paramsJSON: json, timeoutSeconds: 10
        )
    }
}
```

### 4.2 Response Wrappers

```swift
struct MCFleetListResponse: Codable, Sendable { let gateways: [MCGateway] }
struct MCSessionsListResponse: Codable, Sendable { let sessions: [MCSession] }
struct MCApprovalsListResponse: Codable, Sendable { let approvals: [MCApproval] }
struct MCAlertsListResponse: Codable, Sendable { let alerts: [MCAlert] }
```

### 4.3 Capability Detection

When the gateway returns a "method not found" error (e.g., older gateway that
doesn't support Mission Control RPCs), the transport catches the error and the
model sets a `gatewaySupported: Bool` flag. Views check this flag and show
`ContentUnavailableView` with an upgrade prompt.

```swift
func loadAll() async {
    isLoading = true
    loadError = nil
    do {
        async let fleet = transport?.listFleet() ?? []
        async let approvalsList = transport?.listApprovals() ?? []
        async let alertsList = transport?.listAlerts() ?? []
        gateways = try await fleet
        approvals = try await approvalsList
        alerts = try await alertsList
    } catch {
        if isMethodNotFoundError(error) {
            gatewaySupported = false
        } else {
            loadError = error.localizedDescription
        }
    }
    isLoading = false
}
```

---

## 5. View Design

### 5.1 Design Language

All Mission Control views follow the established OpenClaw iOS design system:

| Element | Pattern | Reference |
|---------|---------|-----------|
| Glass material | `.ultraThinMaterial` fill with white gradient overlay + border | `StatusGlassCard`, `OverlayButton` |
| Corner radius | `14pt continuous` for cards, `12pt` for buttons | `RootCanvas` |
| Shadows | `black.opacity(0.25-0.35), radius: 12, y: 6` | `StatusGlassCard` |
| Status colors | Green/yellow/red/gray matching `StatusPill.GatewayState` | `StatusPill` |
| Accent color | `appModel.seamColor` (user-customizable) | `CanvasContent` |
| Typography | SF Pro via system styles; `.headline`, `.subheadline`, `.footnote`, `.caption2` | All views |
| Animations | `.spring(response: 0.25, dampingFraction: 0.85)` for state, `.easeOut` for dismiss | `RootCanvas` |
| Reduce motion | Check `accessibilityReduceMotion`, use `.none` animation when true | `RootTabs` |
| Button style | `.borderedProminent` primary, `.bordered` secondary, `.controlSize(.large)` | `OnboardingWizardView` |
| Confirmation | `.confirmationDialog(titleVisibility: .visible)` with destructive roles | `GatewayActionsDialog` |
| Debug text | `.system(size: 12, design: .monospaced)` in `.thinMaterial` box | `SettingsTab` |

### 5.2 Apple HIG Compliance

| Guideline | Implementation |
|-----------|---------------|
| Touch targets >= 44x44pt | All buttons use `.padding(10)` minimum on 16pt icons = 36pt + hit area |
| Dynamic Type | Use system font styles (`.headline`, `.body`, etc.), never hardcoded sizes except debug |
| VoiceOver | `.accessibilityLabel` on all interactive elements, `.accessibilityHint` on status indicators |
| Color contrast >= 4.5:1 | Use `.primary`/`.secondary` foreground styles that adapt to color scheme |
| Reduce motion | Gate all animations behind `@Environment(\.accessibilityReduceMotion)` |
| Safe areas | Use `.safeAreaPadding()` for overlay positioning |
| Sheet dismiss | `xmark` button in `.topBarTrailing` (consistent with Chat/Settings) |
| Pull to refresh | `.refreshable {}` on scrollable lists |
| Swipe actions | `.swipeActions(edge:)` for approve/deny/acknowledge |
| Destructive actions | Red-tinted with `.destructive` role in confirmation dialogs |
| Empty states | `ContentUnavailableView` with SF Symbol + description |

### 5.3 MissionControlSheet Layout

```
+-------------------------------------------+
| [x]              Mission Control           |
+-------------------------------------------+
|                                           |
| FLEET (3)                                 |
| +---------------------------------------+ |
| | [=] gateway-mac    [*] Online    2 ags | |
| | [=] gateway-pi     [*] Online    1 ag  | |
| | [=] gateway-cloud  [!] Error     0 ags | |
| +---------------------------------------+ |
|                                           |
| APPROVALS (1)                             |
| +---------------------------------------+ |
| | [!] Pairing request from iPhone       > | |
| |     gateway-mac - 2m ago               | |
| +---------------------------------------+ |
|                                           |
| ALERTS (2)                                |
| +---------------------------------------+ |
| | [!!] Session failed: agent-deploy       | |
| |      gateway-cloud - 5m ago            | |
| | [!]  High token usage: main            | |
| |      gateway-mac - 12m ago             | |
| +---------------------------------------+ |
|                                           |
+-------------------------------------------+
```

### 5.4 Status Chips

Inline status indicators reuse `StatusPill` color vocabulary:

```swift
struct MCStatusChip: View {
    let status: MCStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(status.rawValue.capitalized)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
    }

    private var color: Color {
        switch status {
        case .online: .green
        case .connecting: .yellow
        case .error: .red
        case .offline: .gray
        }
    }
}
```

### 5.5 Badge View

Overlay badge on the Mission Control button:

```swift
struct BadgeView: View {
    let count: Int

    var body: some View {
        Text(count > 99 ? "99+" : "\(count)")
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 1)
            .background(Color.red, in: Capsule())
            .offset(x: 6, y: -6)
            .accessibilityLabel("\(count) unresolved items")
    }
}
```

### 5.6 Optimistic Updates (Approvals)

```swift
func respondToApproval(id: String, approved: Bool, note: String?) async throws {
    // 1. Snapshot for rollback
    let snapshot = approvals

    // 2. Optimistic update
    if let idx = approvals.firstIndex(where: { $0.id == id }) {
        approvals[idx].isResolved = true
        approvals[idx].resolution = approved ? .approved : .denied
    }

    // 3. RPC call
    do {
        try await transport?.respondToApproval(
            id: id, approved: approved, note: note
        )
    } catch {
        // 4. Rollback on failure
        approvals = snapshot
        throw error
    }
}
```

---

## 6. Push Notification Routing

### 6.1 Payload Format

```json
{
  "openclaw.type": "mc.approval_needed",
  "openclaw.mc.itemId": "approval-abc123",
  "openclaw.mc.gatewayId": "gw-stable-id",
  "aps": {
    "alert": { "title": "Approval Needed", "body": "Pairing request from iPhone" },
    "sound": "default",
    "interruption-level": "time-sensitive"
  }
}
```

### 6.2 Routing in OpenClawAppDelegate

Extend the existing `userNotificationCenter(_:didReceive:)` method:

```swift
// In OpenClawAppDelegate:
private static func isMissionControlNotification(
    _ userInfo: [AnyHashable: Any]
) -> Bool {
    guard let type = userInfo["openclaw.type"] as? String else { return false }
    return type.hasPrefix("mc.")
}

private static func parseMissionControlDeepLink(
    from userInfo: [AnyHashable: Any]
) -> MissionControlDeepLink? {
    guard let type = userInfo["openclaw.type"] as? String,
          let itemId = userInfo["openclaw.mc.itemId"] as? String
    else { return nil }

    switch type {
    case "mc.approval_needed":
        return .approval(id: itemId)
    case "mc.alert_triggered":
        return .alert(id: itemId)
    case "mc.session_failed":
        let gatewayId = userInfo["openclaw.mc.gatewayId"] as? String ?? ""
        return .session(gatewayId: gatewayId, sessionKey: itemId)
    default:
        return nil
    }
}
```

### 6.3 Navigation Handoff

`NodeAppModel` receives the deep link and stores it. `RootCanvas` observes
the change and sets `presentedSheet = .missionControl`. The sheet reads the
pending deep link on appear and pushes to the target view via its
`NavigationStack` path.

---

## 7. Testing Strategy

### 7.1 Render Smoke Tests

Add to `SwiftUIRenderSmokeTests.swift`:

```swift
@Test @MainActor func missionControlSheetBuildsAViewHierarchy() {
    let appModel = NodeAppModel()
    let mcModel = MissionControlModel()

    let root = MissionControlSheet()
        .environment(mcModel)
        .environment(appModel)

    _ = Self.host(root)
}

@Test @MainActor func fleetViewBuildsAViewHierarchy() {
    let mcModel = MissionControlModel()
    mcModel._test_setGateways([
        MCGateway(id: "gw1", name: "Test", status: .online,
                  agentCount: 1, uptimeMs: 60000, version: "1.0")
    ])

    let root = NavigationStack { FleetView() }
        .environment(mcModel)

    _ = Self.host(root)
}
```

### 7.2 Model Unit Tests

```swift
@Suite(.serialized) struct MissionControlModelTests {
    @Test @MainActor func badgeCountReflectsUnresolvedItems() {
        let model = MissionControlModel()
        model._test_setApprovals([
            MCApproval(id: "a1", type: .pairing, requesterContext: "iPhone",
                       gatewayId: "gw1", sessionKey: nil,
                       createdAt: Date().timeIntervalSince1970,
                       isResolved: false, resolution: nil)
        ])
        model._test_setAlerts([
            MCAlert(id: "al1", severity: .critical, title: "Fail",
                    source: "gw1", gatewayId: "gw1", sessionKey: nil,
                    createdAt: Date().timeIntervalSince1970,
                    isAcknowledged: false)
        ])
        #expect(model.badgeCount == 2)
    }

    @Test @MainActor func respondToApprovalRollsBackOnFailure() async {
        let model = MissionControlModel()
        model._test_setApprovals([
            MCApproval(id: "a1", type: .pairing, requesterContext: "iPhone",
                       gatewayId: "gw1", sessionKey: nil,
                       createdAt: Date().timeIntervalSince1970,
                       isResolved: false, resolution: nil)
        ])
        // No transport configured -> will throw
        do {
            try await model.respondToApproval(id: "a1", approved: true, note: nil)
            Issue.record("Expected to throw without transport")
        } catch {
            #expect(model.approvals.first?.isResolved == false)
        }
    }
}
```

### 7.3 Transport Unit Tests

```swift
@Suite struct MissionControlTransportTests {
    @Test func requestsFailWhenGatewayNotConnected() async {
        let gateway = GatewayNodeSession()
        let transport = MissionControlTransport(gateway: gateway)

        do {
            _ = try await transport.listFleet()
            Issue.record("Expected to throw when gateway not connected")
        } catch {}
    }
}
```

### 7.4 Deep Link Tests

```swift
@Suite struct MissionControlDeepLinkTests {
    @Test func parsesApprovalPayload() {
        let userInfo: [AnyHashable: Any] = [
            "openclaw.type": "mc.approval_needed",
            "openclaw.mc.itemId": "approval-123"
        ]
        let link = MissionControlDeepLink.parse(from: userInfo)
        #expect(link == .approval(id: "approval-123"))
    }

    @Test func returnsNilForUnknownType() {
        let userInfo: [AnyHashable: Any] = [
            "openclaw.type": "mc.unknown",
            "openclaw.mc.itemId": "x"
        ]
        let link = MissionControlDeepLink.parse(from: userInfo)
        #expect(link == nil)
    }
}
```

---

## 8. Incremental Delivery Plan

Each phase is a single PR with one logical change:

| Phase | PR Scope | Files | Tests |
|-------|----------|-------|-------|
| 1 | Overlay button + empty sheet scaffold | `RootCanvas.swift`, `MissionControlSheet.swift` | Render smoke |
| 2 | Model + types (no transport) | `MissionControlModel.swift`, `MissionControlTypes.swift` | Model unit tests |
| 3 | Transport layer (read APIs) | `MissionControlTransport.swift` | Transport unit tests |
| 4 | Fleet view + session detail | `FleetView.swift`, `SessionDetailView.swift`, `MissionControlSheet.swift` | Render smoke |
| 5 | Alerts feed + acknowledge | `AlertsFeedView.swift`, `MissionControlModel.swift`, `MissionControlTransport.swift` | Model + render |
| 6 | Approvals inbox + actions | `ApprovalsInboxView.swift`, `MissionControlModel.swift`, `MissionControlTransport.swift` | Model + render |
| 7 | Session actions | `SessionDetailView.swift`, `MissionControlTransport.swift` | Model unit tests |
| 8 | Push + deep links | `OpenClawApp.swift`, `MissionControlDeepLink.swift`, `NodeAppModel.swift` | Deep link unit tests |

---

## 9. Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Gateway doesn't implement MC RPCs yet | All data views show empty/unsupported | Capability detection (FR-7.5) + graceful `ContentUnavailableView` |
| `NodeAppModel.swift` bloat (already 2700 LOC) | Maintainability | Limit changes to < 30 lines; all logic in `MissionControlModel` |
| Multi-gateway awareness doesn't exist in iOS | Fleet view data incomplete | Use single-gateway data from existing `agents.list` + `sessions.list` as fallback |
| Push notification payload format not defined server-side | Deep links don't work | Parse defensively; log unknown payloads; fall through to default handling |
| Optimistic updates cause stale state | User sees incorrect data | Always re-fetch after mutation; rollback on error |

---

## 10. Existing Code Reuse

| Existing Code | Reuse In |
|---------------|----------|
| `IOSGatewayChatTransport` pattern | `MissionControlTransport` (same struct + RPC pattern) |
| `IOSGatewayChatTransport.abortRun()` | Session abort action (call same `chat.abort` RPC) |
| `IOSGatewayChatTransport.sendMessage()` | Operator message action (call same `chat.send` RPC) |
| `StatusPill.GatewayState` colors | `MCStatusChip` color mapping |
| `OverlayButton` | Mission Control button on canvas |
| `GatewayTrustPromptAlert` / `DeepLinkAgentPromptAlert` | Confirmation dialog patterns |
| `WatchPromptNotificationBridge` | Push payload key naming pattern |
| `SwiftUIRenderSmokeTests.host()` | All new view smoke tests |
| `withUserDefaults()` | Model tests with persisted state |
| `_test_` method pattern | `MissionControlModel` test accessors |
| `GatewayActionsDialog` `.confirmationDialog` | Destructive action confirmations |
