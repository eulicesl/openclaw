# Moltbot iOS Security Quick Reference

Quick answers to common security questions for developers, reviewers, and users.

## For App Store Reviewers

### Q: Does this app track users?
**A**: No. NSPrivacyTracking is set to `false` in PrivacyInfo.xcprivacy. No analytics, no advertising IDs, no cross-app tracking.

### Q: Why does it need local network access?
**A**: For Bonjour (mDNS) discovery of the user's personal gateway on their local network. No internet traffic for discovery.

### Q: How are credentials stored?
**A**: All tokens and passwords stored in iOS Keychain with `AfterFirstUnlockThisDeviceOnly` accessibility. No plaintext storage.

### Q: Why the ATS exception for web content?
**A**: Required for WKWebView to load user's gateway content (A2UI canvas). Gateway connections use TLS certificate pinning for security.

### Q: Can users control their data?
**A**: Yes. Privacy settings allow users to:
- View all permissions
- Clear audit logs
- Manage paired devices
- View/delete TLS certificates
- Revoke access at any time

### Q: Is network traffic encrypted?
**A**: Yes. WebSocket connections use TLS (wss://). Certificate pinning prevents MITM attacks.

---

## For Developers

### Storing Credentials
```swift
// ✅ DO: Use Keychain
KeychainStore.saveString(token, service: "bot.molt.gateway", 
                        account: "authToken")

// ❌ DON'T: Use UserDefaults
UserDefaults.standard.set(token, forKey: "token")
```

### Logging
```swift
// ✅ DO: Redact sensitive data
logger.info("User \(userId.prefix(4))*** logged in")

// ❌ DON'T: Log credentials
logger.info("Login: \(username) / \(password)")
```

### Network Requests
```swift
// ✅ DO: Use TLS certificate pinning
let session = GatewayTLSPinningSession(params: tlsParams)

// ❌ DON'T: Disable certificate validation
session.sessionConfiguration.tlsMinimumSupportedProtocolVersion = .TLSv10
```

### Error Messages
```swift
// ✅ DO: Generic user-facing errors
throw AuthError.authenticationFailed

// ❌ DON'T: Expose internal details
throw NSError(domain: "", code: 0, userInfo: [
    NSLocalizedDescriptionKey: "DB query failed: \(sqlError)"
])
```

---

## For Users

### Is my data private?
**Yes**. Your data never leaves your device except to connect to YOUR gateway (which you control). No third-party servers, no tracking, no analytics.

### Where are my passwords stored?
In your iPhone's secure Keychain, protected by your device passcode. Even if someone gets your phone, they can't access Moltbot credentials without unlocking it.

### Can someone intercept my gateway connection?
No. Moltbot uses TLS encryption and certificate pinning. The first time you connect, the gateway's certificate is "pinned." If someone tries to intercept later, the connection will fail.

### What permissions does Moltbot need?

| Permission | Why | Required? |
|------------|-----|-----------|
| Microphone | Voice Wake ("Hey Claude") | Yes (for voice features) |
| Speech Recognition | On-device wake word detection | Yes (for voice features) |
| Camera | Take photos when you ask | No (optional) |
| Location | Share your location when requested | No (optional) |
| Local Network | Find your gateway automatically | No (can enter manually) |

### Can I delete my data?
Yes. Settings > Privacy & Security > Clear All Data. This deletes:
- Security audit logs
- Cached data
- App preferences

Your Keychain credentials can be deleted by removing the gateway pairing or uninstalling the app.

---

## Security Features at a Glance

### Authentication
- ✅ Device pairing with 8-character codes
- ✅ Token-based authentication
- ✅ Password fallback option
- ✅ Per-device unique IDs
- ✅ Secure token storage (Keychain)

### Encryption
- ✅ TLS 1.2+ for all network traffic
- ✅ Certificate pinning (TOFU)
- ✅ Keychain encryption for credentials
- ✅ No plaintext password storage

### Privacy
- ✅ No tracking
- ✅ No analytics without consent
- ✅ No third-party SDKs
- ✅ Data stays on your gateway
- ✅ User control over all permissions

### Compliance
- ✅ Privacy manifest included
- ✅ App Store guidelines compliant
- ✅ GDPR-friendly (no data collection)
- ✅ CCPA-friendly (no data sale)
- ✅ Accessibility support

---

## Common Security Scenarios

### Scenario: User connects to gateway for first time
1. App discovers gateway via Bonjour
2. User taps "Connect"
3. Gateway shows pairing code
4. User enters code in app
5. Gateway generates device token
6. App stores token in Keychain
7. TLS certificate automatically pinned

**Security**: Token in Keychain, certificate pinned, device paired.

### Scenario: Someone tries to MITM attack
1. Attacker intercepts connection
2. Attacker's certificate fingerprint differs from pinned
3. TLS verification fails
4. Connection rejected
5. Security audit event logged

**Security**: Attack blocked, user can see in audit log.

### Scenario: User gets new phone
1. Restore from backup (iCloud/iTunes)
2. Keychain restored (if iCloud Keychain enabled)
3. Instance ID restored
4. Gateway recognizes device
5. Connection succeeds

**Security**: Same device identity, no re-pairing needed.

---

## Security Contacts

| Issue | Contact |
|-------|---------|
| Security vulnerability | [[email protected]] |
| Privacy question | [[email protected]] |
| General support | [[email protected]] |
| Documentation | [https://docs.openclaw.ai/](https://docs.openclaw.ai/) |

---

## File Locations

| Component | File Path |
|-----------|-----------|
| Keychain Storage | `/apps/ios/Sources/Gateway/KeychainStore.swift` |
| TLS Pinning | `/apps/shared/MoltbotKit/Sources/MoltbotKit/GatewayTLSPinning.swift` |
| Device Pairing UI | `/apps/ios/Sources/Settings/DevicePairingView.swift` |
| Privacy Manifest | `/apps/ios/Sources/PrivacyInfo.xcprivacy` |
| Security Audit | `/apps/ios/Sources/Settings/SecurityAuditView.swift` |
| Settings Store | `/apps/ios/Sources/Gateway/GatewaySettingsStore.swift` |

---

**Last Updated**: 2026-01-31  
**App Version**: 2026.1.27-beta.1  
**iOS Minimum**: 18.0
