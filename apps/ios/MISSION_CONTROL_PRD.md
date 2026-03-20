# Mission Control PRD

## Product Overview

Mission Control is an operator dashboard for the OpenClaw iOS app that gives users
real-time visibility and control over their gateway fleet, agent sessions, pending
approvals, and system alerts -- all from a single, glanceable surface.

The feature ships behind an `@AppStorage("missionControl.enabled")` toggle so it
can be enabled incrementally. When enabled, a new overlay button appears on the
main canvas (`RootCanvas`). Tapping it presents a full-height sheet containing the
Mission Control dashboard.

---

## Problem Statement

Today the iOS app is a single-gateway, single-session client. Operators who run
multiple gateways or agents have no way to:

- See which gateways/agents are online, idle, or errored
- Review and act on pending approvals (pairing, tool use, etc.)
- Monitor alerts (session failures, health degradation, security events)
- Send operator messages or abort/restart sessions remotely

They must SSH into each machine or use the CLI. Mission Control brings these
capabilities to the phone.

---

## User Personas

| Persona | Description |
|---------|-------------|
| **Solo operator** | Runs 1-2 gateways at home/office. Wants quick status checks and approval handling from the couch. |
| **Fleet operator** | Runs 3+ gateways across machines. Needs at-a-glance fleet health and drill-down into individual sessions. |
| **On-call engineer** | Receives push notifications for failures/approvals and needs to act within seconds. |

---

## Feature Requirements

### FR-1: Entry Point (overlay button + sheet)

| ID | Requirement |
|----|-------------|
| FR-1.1 | Add a Mission Control overlay button to `CanvasContent` in `RootCanvas.swift`, positioned in the existing button VStack (between Talk Mode and Settings). |
| FR-1.2 | Guard the button behind `@AppStorage("missionControl.enabled")` (default `false`). |
| FR-1.3 | Tapping the button sets `presentedSheet = .missionControl`. |
| FR-1.4 | Add `case missionControl` to the `PresentedSheet` enum with a unique `id`. |
| FR-1.5 | The sheet presents `MissionControlSheet()` inside `NavigationStack` with an `xmark` dismiss button in `.topBarTrailing`, matching the Chat/Settings sheet pattern. |
| FR-1.6 | When unresolved alerts or pending approvals exist, show a small numeric badge on the overlay button (red circle, white text, top-trailing offset). |

### FR-2: Dashboard (MissionControlSheet)

| ID | Requirement |
|----|-------------|
| FR-2.1 | The sheet root is a `List` with grouped style containing three sections: Fleet, Approvals, Alerts. |
| FR-2.2 | Each section header shows a count badge (e.g., "Fleet (3)", "Approvals (1)"). |
| FR-2.3 | Pull-to-refresh via `.refreshable {}` triggers a full reload from the transport layer. |
| FR-2.4 | Empty state per section uses `ContentUnavailableView` with contextual message and SF Symbol. |
| FR-2.5 | Error state shows an inline banner with retry button (not a blocking alert). |
| FR-2.6 | Navigation title: "Mission Control", display mode `.large` at root, `.inline` on push. |

### FR-3: Fleet View

| ID | Requirement |
|----|-------------|
| FR-3.1 | List all connected gateways. Each row shows: gateway name, status chip (online/offline/error), agent count, uptime. |
| FR-3.2 | Tapping a gateway row pushes `GatewayDetailView` showing connected agents/sessions. |
| FR-3.3 | Each session row shows: session key, agent name, status (idle/running/errored), model, token usage summary. |
| FR-3.4 | Tapping a session row pushes `SessionDetailView` with: summary card, recent transcript preview (last 5 messages), action buttons. |
| FR-3.5 | Status chips use the existing `StatusPill.GatewayState` color vocabulary: green (connected), yellow (connecting), red (error), gray (offline). |

### FR-4: Approvals Inbox

| ID | Requirement |
|----|-------------|
| FR-4.1 | List pending approvals sorted by urgency (oldest first, with time-sensitive items promoted). |
| FR-4.2 | Each approval row shows: type (pairing/tool-use/file-access), requester context, timestamp, urgency indicator. |
| FR-4.3 | Tapping a row pushes `ApprovalDetailView` with full context and Approve/Deny buttons. |
| FR-4.4 | Approve/Deny requires a confirmation dialog (`.confirmationDialog`) before executing. |
| FR-4.5 | Optional note field on deny action. |
| FR-4.6 | Optimistic update: remove from list immediately, rollback with error banner on RPC failure. |
| FR-4.7 | Swipe actions: leading swipe = approve (green), trailing swipe = deny (red). |

### FR-5: Alerts Feed

| ID | Requirement |
|----|-------------|
| FR-5.1 | List alerts sorted newest-first with severity indicator (critical/warning/info). |
| FR-5.2 | Filter bar at top: segmented picker for All / Critical / Warning / Info. |
| FR-5.3 | Each alert row shows: severity icon, title, source (gateway/agent), timestamp, acknowledged status. |
| FR-5.4 | Swipe-to-acknowledge on unresolved alerts. |
| FR-5.5 | Bulk acknowledge via toolbar button ("Mark All Read"). |
| FR-5.6 | Acknowledged alerts move to a collapsible "Resolved" section. |

### FR-6: Session Actions

| ID | Requirement |
|----|-------------|
| FR-6.1 | From `SessionDetailView`, expose three actions: Send Message, Abort Run, Restart Session. |
| FR-6.2 | Send Message: text field + send button. Reuse the `chat.send` RPC method from `IOSGatewayChatTransport`. |
| FR-6.3 | Abort Run: confirmation dialog ("This will stop the current run. Continue?"). Reuse the `chat.abort` RPC method. |
| FR-6.4 | Restart Session: confirmation dialog with destructive role. New RPC method `session.restart`. |
| FR-6.5 | All actions show inline success/failure feedback (checkmark toast or error banner). |
| FR-6.6 | Retry button on failure. |

### FR-7: Transport Layer

| ID | Requirement |
|----|-------------|
| FR-7.1 | Create `MissionControlTransport` struct conforming to `Sendable`, wrapping `GatewayNodeSession`. |
| FR-7.2 | Follow `IOSGatewayChatTransport` pattern: `JSONEncoder` params, `gateway.request()`, `JSONDecoder` response. |
| FR-7.3 | RPC methods: `mc.fleet.list`, `mc.sessions.list`, `mc.approvals.list`, `mc.approvals.respond`, `mc.alerts.list`, `mc.alerts.acknowledge`, `session.restart`. |
| FR-7.4 | All methods include timeout (15s for reads, 10s for writes). |
| FR-7.5 | Graceful degradation: if gateway returns "method not found" or capability-missing error, surface `ContentUnavailableView` ("Mission Control is not supported by this gateway. Update to the latest version."). |
| FR-7.6 | Strong-typed response models with `Codable` + `Sendable` conformance. |

### FR-8: State Model

| ID | Requirement |
|----|-------------|
| FR-8.1 | Create `@MainActor @Observable final class MissionControlModel`. |
| FR-8.2 | State buckets: `gateways: [MCGateway]`, `sessions: [MCSession]`, `approvals: [MCApproval]`, `alerts: [MCAlert]`, `isLoading: Bool`, `loadError: String?`. |
| FR-8.3 | Inject via `.environment()` on the Mission Control sheet. |
| FR-8.4 | Create and own the model instance in `RootCanvas` (following `NodeAppModel` ownership pattern). |
| FR-8.5 | Model holds a reference to `GatewayNodeSession` (the operator session) for RPC calls. |
| FR-8.6 | Counts for badge: `var unresolvedAlertCount: Int`, `var pendingApprovalCount: Int`. |

### FR-9: Push Notifications + Deep Links

| ID | Requirement |
|----|-------------|
| FR-9.1 | Define new notification payload types with `openclaw.type` key: `mc.approval_needed`, `mc.alert_triggered`, `mc.session_failed`. |
| FR-9.2 | Extend `OpenClawAppDelegate.userNotificationCenter(_:didReceive:)` to parse Mission Control payloads. |
| FR-9.3 | On notification tap: open the app, set `presentedSheet = .missionControl`, navigate to the relevant item. |
| FR-9.4 | Define `MissionControlDeepLink` enum with associated values for target routing. |
| FR-9.5 | Unknown/malformed payloads log diagnostics and fall through to default handling. |
| FR-9.6 | Extend `NodeAppModel.handleDeepLink(url:)` to support `openclaw://mission-control/approvals/<id>` and `openclaw://mission-control/alerts/<id>` URL schemes. |

---

## Non-Functional Requirements

| ID | Requirement |
|----|-------------|
| NFR-1 | All views must render without crash (verified by `SwiftUIRenderSmokeTests` pattern). |
| NFR-2 | All models and transport code must have unit tests using Swift Testing (`@Suite`, `@Test`, `#expect`). |
| NFR-3 | Files must stay under ~500 LOC per CLAUDE.md guidelines. |
| NFR-4 | Use `@Observable` + `@MainActor` (never `ObservableObject`). |
| NFR-5 | Respect `accessibilityReduceMotion` for all animations. |
| NFR-6 | All interactive elements must have accessibility labels. |
| NFR-7 | Touch targets minimum 44x44pt per Apple HIG. |
| NFR-8 | Support Dynamic Type for all text. |
| NFR-9 | `NodeAppModel.swift` changes limited to minimal wiring (badge counts, deep link routing). |
| NFR-10 | No new dependencies added to the iOS app or shared packages. |

---

## File Inventory

### New Files

| File | Purpose |
|------|---------|
| `apps/ios/Sources/MissionControl/MissionControlSheet.swift` | Root dashboard view with Fleet/Approvals/Alerts sections |
| `apps/ios/Sources/MissionControl/FleetView.swift` | Gateway list + gateway detail |
| `apps/ios/Sources/MissionControl/SessionDetailView.swift` | Session detail + actions |
| `apps/ios/Sources/MissionControl/ApprovalsInboxView.swift` | Approvals list + detail + approve/deny |
| `apps/ios/Sources/MissionControl/AlertsFeedView.swift` | Alerts list + filters + acknowledge |
| `apps/ios/Sources/MissionControl/MissionControlDeepLink.swift` | Deep link routing enum + parser |
| `apps/ios/Sources/Model/MissionControlModel.swift` | Observable state model |
| `apps/ios/Sources/Model/MissionControlTypes.swift` | MCGateway, MCSession, MCApproval, MCAlert types |
| `apps/ios/Sources/Services/MissionControlTransport.swift` | Gateway RPC adapter |
| `apps/ios/Tests/MissionControlModelTests.swift` | State transition + error tests |
| `apps/ios/Tests/MissionControlTransportTests.swift` | RPC encode/decode + error mapping tests |
| `apps/ios/Tests/MissionControlDeepLinkTests.swift` | Payload parse + route mapping tests |

### Modified Files

| File | Change |
|------|--------|
| `apps/ios/Sources/RootCanvas.swift` | Add `.missionControl` to `PresentedSheet`, overlay button, sheet case, model creation |
| `apps/ios/Sources/OpenClawApp.swift` | Extend push notification routing for MC payloads |
| `apps/ios/Sources/Model/NodeAppModel.swift` | Add deep link routing for `openclaw://mission-control/*` (minimal) |
| `apps/ios/Tests/SwiftUIRenderSmokeTests.swift` | Add render smoke test for `MissionControlSheet` |

---

## Implementation Order

| Phase | Task | Dependencies |
|-------|------|-------------|
| 1 | Entry point: overlay button + sheet scaffold on `RootCanvas` | None |
| 2 | `MissionControlModel` + types | None |
| 3 | `MissionControlTransport` (read APIs) | Phase 2 types |
| 4 | Fleet view + session detail (read-only) | Phases 1-3 |
| 5 | Alerts feed + acknowledge | Phases 1-3 |
| 6 | Approvals inbox + action flow | Phases 1-3 |
| 7 | Session actions (message/abort/restart) | Phase 4 |
| 8 | Push notifications + deep links | Phases 1-6 |

---

## Gateway Prerequisites

The following RPC methods must exist on the gateway for Mission Control to
function beyond the scaffold phase. Until they ship, the iOS client must
gracefully show "not supported" states (FR-7.5).

| RPC Method | Direction | Purpose |
|------------|-----------|---------|
| `mc.fleet.list` | Read | List gateways + connected agents |
| `mc.sessions.list` | Read | List sessions with status/usage |
| `mc.approvals.list` | Read | List pending approvals |
| `mc.approvals.respond` | Write | Approve or deny an approval |
| `mc.alerts.list` | Read | List alerts with severity/status |
| `mc.alerts.acknowledge` | Write | Acknowledge an alert |
| `session.restart` | Write | Restart a session |

Existing RPC methods reused without changes:
- `chat.send` (send operator message to session)
- `chat.abort` (abort a running session)
- `sessions.list` (fallback session listing)
- `agents.list` (agent enumeration)

---

## Success Metrics

| Metric | Target |
|--------|--------|
| App compiles with Mission Control enabled | Pass |
| All existing tests continue to pass | Pass |
| Render smoke tests for all new views | Pass |
| Unit test coverage for model + transport | 70%+ lines |
| No new `@ts-nocheck` or lint suppressions | Zero |
| `NodeAppModel.swift` LOC delta | < 30 lines |
