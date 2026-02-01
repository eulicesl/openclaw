# Moltbot iOS Security Documentation

This document outlines the security architecture and implementation of the Moltbot iOS app.

## Security Architecture

### 1. Device Pairing & Authentication

#### Device Identity
- Each iOS device generates a unique `instanceId` (UUID) stored securely in Keychain
- Device identity persists across app reinstalls when using iCloud Keychain
- Keychain service: `bot.molt.node`
- Accessibility: `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`

#### Pairing Flow
1. **Initial Connection**: Device connects to gateway and requests pairing
2. **Code Display**: Gateway displays an 8-character pairing code
3. **User Approval**: User enters code in iOS app or approves on gateway
4. **Token Generation**: Gateway generates a unique device auth token
5. **Secure Storage**: Token stored in iOS Keychain with strict accessibility

#### Token Management
- Tokens stored per instance ID in Keychain
- Service: `bot.molt.gateway`
- Account: `gateway-token.{instanceId}`
- Supports token rotation without re-pairing
- Tokens can be revoked from gateway dashboard

### 2. TLS/SSL Security

#### Certificate Pinning (TOFU - Trust On First Use)
- First connection to a gateway pins its TLS certificate fingerprint
- Future connections verify against pinned fingerprint
- Prevents man-in-the-middle (MITM) attacks
- SHA-256 fingerprints stored in shared UserDefaults

#### Implementation Details
```swift
// TLS params for gateway connection
public struct GatewayTLSParams {
    let required: Bool              // Enforce TLS
    let expectedFingerprint: String? // SHA-256 hash
    let allowTOFU: Bool             // Trust on first use
    let storeKey: String?           // Storage identifier
}
```

#### Certificate Verification Process
1. Gateway advertises TLS support via Bonjour (`gatewayTlsSha256`)
2. iOS establishes TLS connection
3. Certificate fingerprint extracted from trust chain
4. Compared against stored fingerprint (if exists)
5. TOFU: If no stored fingerprint, automatically pin on first connection
6. Mismatch: Connection rejected, user notified

### 3. Network Security

#### Bonjour Discovery (mDNS)
- Service type: `_moltbot-gw._tcp`
- Local network only (no internet exposure)
- TXT records include:
  - `gatewayPort`: WebSocket port
  - `gatewayTls`: TLS enabled flag
  - `gatewayTlsSha256`: Certificate fingerprint
  - `stableID`: Gateway unique identifier

#### Connection Security
- WebSocket over TLS (wss://) when gateway supports it
- Fallback to ws:// for local unencrypted (gateway config)
- Password-based authentication supported as fallback
- Tailscale integration for remote access (documented separately)

### 4. Data Protection

#### Keychain Storage
All sensitive data stored in iOS Keychain:
- Device instance ID
- Gateway auth tokens
- Gateway passwords
- Gateway stable IDs (preferred, last discovered)

#### Keychain Accessibility
- `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`
- Data available after first device unlock
- Not backed up to iCloud by default
- Cannot be accessed without device passcode

#### Local Storage
- UserDefaults for non-sensitive preferences
- SharedDefaults (`bot.molt.shared`) for TLS fingerprints
- No plaintext passwords or tokens in UserDefaults

### 5. Permissions & Privacy

#### Required Permissions
- **Microphone**: Voice Wake and Talk Mode
- **Speech Recognition**: On-device wake word detection
- **Camera**: Photo/video capture on request
- **Location**: Optional, for location sharing
- **Local Network**: Bonjour gateway discovery

#### Usage Descriptions (Info.plist)
All permissions include clear, user-friendly descriptions explaining:
- Why the permission is needed
- What data is collected
- How the data is used
- User control options

#### Privacy Manifest (PrivacyInfo.xcprivacy)
Declares:
- NSPrivacyTracking: false (no third-party tracking)
- NSPrivacyTrackingDomains: [] (no tracking domains)
- NSPrivacyCollectedDataTypes: Microphone, camera, location (with purposes)
- NSPrivacyAccessedAPITypes: User defaults, file timestamp (with reasons)

### 6. Security Audit Logging

#### Audit Events
The app logs security-relevant events:
- Gateway connections and disconnections
- TLS certificate verification (success/failure)
- Authentication attempts
- Permission requests
- Configuration changes
- Data access events

#### Event Storage
- Events stored in UserDefaults (JSON)
- Maximum 1000 events retained
- User can view and clear audit log
- Events include: timestamp, type, severity, details

#### Severity Levels
- **Info**: Normal operations
- **Warning**: Potential issues
- **Error**: Failed operations
- **Critical**: Security violations

### 7. App Transport Security (ATS)

#### Configuration
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoadsInWebContent</key>
    <true/>
</dict>
```

#### Justification
- Required for A2UI canvas rendering (user's gateway content)
- Gateway URLs are user-configured and verified via TLS pinning
- Web content sandboxed within WKWebView
- No arbitrary loads in native code

### 8. Code Security

#### Swift Concurrency
- Uses Swift 6.0 strict concurrency checking
- All async operations properly isolated
- No data races in security-critical code

#### Memory Safety
- No unsafe pointer operations in security code
- All Keychain operations use safe CFTypeRef handling
- Proper error handling for all security operations

#### Input Validation
- Pairing codes validated (8 chars, alphanumeric, uppercase)
- Gateway URLs validated before connection
- Certificate fingerprints normalized and validated

### 9. Vulnerability Reporting

#### Responsible Disclosure
- Security issues: [[email protected]]
- Include: iOS version, app version, reproduction steps
- Do not post publicly until fixed
- Coordinated disclosure timeline: 90 days

#### Security Updates
- Critical fixes released immediately
- Non-critical fixes in regular updates
- Users notified via App Store update notes

### 10. Compliance

#### App Store Requirements
- [x] Privacy Manifest included
- [x] Usage descriptions for all permissions
- [x] No tracking without consent
- [x] Data minimization
- [x] User control over data
- [x] Secure credential storage
- [x] TLS for network communication

#### Best Practices
- [x] Keychain for sensitive data
- [x] Certificate pinning
- [x] Input validation
- [x] Error handling
- [x] Audit logging
- [x] Secure defaults
- [x] User education (onboarding)

## Security Checklist for Developers

### Before Release
- [ ] All tokens/passwords in Keychain
- [ ] TLS pinning enabled
- [ ] Privacy manifest up to date
- [ ] Security audit log functional
- [ ] Permissions properly scoped
- [ ] No hardcoded secrets
- [ ] Error messages don't leak sensitive info
- [ ] Device pairing flow tested
- [ ] Certificate verification tested
- [ ] ATS exceptions justified

### Code Review Focus
- [ ] Keychain operations use proper accessibility
- [ ] TLS verification logic correct
- [ ] No plaintext storage of secrets
- [ ] Proper error propagation
- [ ] Input validation complete
- [ ] Audit logging comprehensive

### Testing
- [ ] MITM attack blocked by pinning
- [ ] Invalid certificates rejected
- [ ] Pairing code validation works
- [ ] Token rotation handled
- [ ] Gateway unreachable scenarios
- [ ] Network switching (WiFi/cellular)
- [ ] Background/foreground transitions

## Known Limitations

1. **TOFU Risk**: First connection trusts the certificate (no prior verification)
   - Mitigation: Gateway advertises fingerprint via Bonjour
   - Mitigation: User must approve pairing

2. **Local Network Only**: Bonjour discovery limited to local network
   - Mitigation: Manual gateway configuration supported
   - Mitigation: Tailscale for remote access

3. **Keychain Backup**: Device tokens backed up if iCloud Keychain enabled
   - Mitigation: Tokens revocable from gateway
   - Mitigation: Per-device instance IDs

## Future Enhancements

- [ ] Mutual TLS (client certificates)
- [ ] Hardware security module integration
- [ ] Biometric authentication for sensitive operations
- [ ] Certificate transparency monitoring
- [ ] Advanced threat detection
- [ ] Security posture dashboard

---

**Last Updated**: 2026-01-31  
**Security Contact**: [[email protected]]  
**Version**: 2026.1.27-beta.1
