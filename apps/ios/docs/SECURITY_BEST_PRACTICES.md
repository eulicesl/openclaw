# Security Best Practices for Moltbot iOS Development

This document provides security guidelines for developers working on the Moltbot iOS app.

## Table of Contents
1. [Secure Coding](#secure-coding)
2. [Credential Management](#credential-management)
3. [Network Security](#network-security)
4. [Data Protection](#data-protection)
5. [User Privacy](#user-privacy)
6. [Common Vulnerabilities](#common-vulnerabilities)

## Secure Coding

### Swift Concurrency
```swift
// ✅ GOOD: Proper actor isolation
@MainActor
class SecurityManager {
    private var authToken: String?
    
    func updateToken(_ token: String) {
        self.authToken = token
    }
}

// ❌ BAD: Unsynchronized access
class SecurityManager {
    var authToken: String? // Data race!
}
```

### Optional Handling
```swift
// ✅ GOOD: Safe unwrapping
guard let token = loadToken() else {
    throw AuthError.tokenNotFound
}

// ❌ BAD: Force unwrapping
let token = loadToken()! // Crash risk!
```

### Error Handling
```swift
// ✅ GOOD: Specific, non-revealing errors
public enum GatewayError: LocalizedError {
    case connectionFailed
    case authenticationFailed
    case timeout
    
    public var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Unable to connect to gateway"
        case .authenticationFailed:
            return "Authentication failed"
        case .timeout:
            return "Connection timed out"
        }
    }
}

// ❌ BAD: Revealing internal details
throw NSError(domain: "com.app", code: -1, 
    userInfo: [NSLocalizedDescriptionKey: "SQL error: \(sqlError)"])
```

## Credential Management

### Keychain Storage
```swift
// ✅ GOOD: Keychain for sensitive data
enum KeychainStore {
    static func saveToken(_ token: String) -> Bool {
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "authToken",
            kSecValueData as String: data,
            kSecAttrAccessible as String: 
                kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }
}

// ❌ BAD: UserDefaults for secrets
UserDefaults.standard.set(token, forKey: "authToken")
```

### Token Validation
```swift
// ✅ GOOD: Validate before using
func validateToken(_ token: String) -> Bool {
    // Check format, length, expiry
    guard token.count >= 32,
          !token.contains(where: { $0.isWhitespace }),
          isValidBase64(token) else {
        return false
    }
    return true
}

// ❌ BAD: Blindly trust input
let token = userInput // No validation!
```

## Network Security

### TLS Certificate Pinning
```swift
// ✅ GOOD: Verify certificate fingerprint
func urlSession(
    _ session: URLSession,
    didReceive challenge: URLAuthenticationChallenge,
    completionHandler: @escaping (URLSession.AuthChallengeDisposition, 
                                   URLCredential?) -> Void
) {
    guard let trust = challenge.protectionSpace.serverTrust,
          let fingerprint = certificateFingerprint(trust) else {
        completionHandler(.cancelAuthenticationChallenge, nil)
        return
    }
    
    if fingerprint == expectedFingerprint {
        completionHandler(.useCredential, URLCredential(trust: trust))
    } else {
        // Log security event
        SecurityAuditLogger.shared.log(.tlsVerification, 
            details: "Certificate mismatch", severity: .critical)
        completionHandler(.cancelAuthenticationChallenge, nil)
    }
}

// ❌ BAD: Accept any certificate
completionHandler(.useCredential, URLCredential(trust: trust))
```

### URL Validation
```swift
// ✅ GOOD: Validate gateway URLs
func validateGatewayURL(_ urlString: String) -> URL? {
    guard let url = URL(string: urlString),
          let scheme = url.scheme,
          ["ws", "wss"].contains(scheme),
          let host = url.host,
          !host.isEmpty else {
        return nil
    }
    return url
}

// ❌ BAD: Trust user input
let url = URL(string: userInput)! // Unsafe!
```

### Request Authentication
```swift
// ✅ GOOD: Include auth token in headers
func makeAuthenticatedRequest(token: String) async throws -> Data {
    var request = URLRequest(url: gatewayURL)
    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    let (data, _) = try await URLSession.shared.data(for: request)
    return data
}

// ❌ BAD: Token in query parameter
let url = URL(string: "wss://gateway?token=\(token)")! // Logged in URLs!
```

## Data Protection

### Sensitive Data Handling
```swift
// ✅ GOOD: Redact in logs
func logAuthAttempt(username: String, success: Bool) {
    let redacted = String(username.prefix(2)) + "***"
    logger.info("Auth attempt: \(redacted) - \(success)")
}

// ❌ BAD: Log full credentials
logger.info("Login: \(username) with \(password)") // Never!
```

### Memory Security
```swift
// ✅ GOOD: Clear sensitive data when done
var password: String? = getPassword()
defer {
    password = nil
}
// Use password...

// ❌ BAD: Leave in memory
let password = getPassword()
// Password lingers in memory
```

### File Protection
```swift
// ✅ GOOD: Encrypt sensitive files
func saveEncryptedData(_ data: Data) throws {
    let encrypted = try encrypt(data)
    var attributes = [FileAttributeKey: Any]()
    attributes[.protectionKey] = FileProtectionType.complete
    try encrypted.write(to: url, options: .completeFileProtection)
}

// ❌ BAD: Plain text files
data.write(to: url) // No encryption!
```

## User Privacy

### Permission Requests
```swift
// ✅ GOOD: Request permissions when needed
func startVoiceWake() {
    AVAudioSession.sharedInstance().requestRecordPermission { granted in
        if granted {
            // Start voice wake
        } else {
            // Show explanation
        }
    }
}

// ❌ BAD: Request all permissions on launch
func application(_ application: UIApplication, 
                didFinishLaunchingWithOptions...) {
    requestMicrophone()
    requestCamera()
    requestLocation() // Too aggressive!
}
```

### Privacy Labels
```swift
// ✅ GOOD: Document in PrivacyInfo.xcprivacy
/*
<key>NSPrivacyCollectedDataTypes</key>
<array>
    <dict>
        <key>NSPrivacyCollectedDataType</key>
        <string>NSPrivacyCollectedDataTypeAudioData</string>
        <key>NSPrivacyCollectedDataTypeLinked</key>
        <false/>
        <key>NSPrivacyCollectedDataTypePurposes</key>
        <array>
            <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
        </array>
    </dict>
</array>
*/
```

### Tracking Prevention
```swift
// ✅ GOOD: No tracking
// Don't use IDFA, analytics without consent

// ❌ BAD: Undisclosed tracking
import AppTrackingTransparency
ATTrackingManager.requestTrackingAuthorization() // Need clear purpose!
```

## Common Vulnerabilities

### 1. Injection Attacks
```swift
// ✅ GOOD: Parameterized queries (if using SQL)
let query = "SELECT * FROM users WHERE id = ?"
db.execute(query, parameters: [userId])

// ❌ BAD: String interpolation
let query = "SELECT * FROM users WHERE id = '\(userId)'" // SQL injection!
```

### 2. XSS in WebViews
```swift
// ✅ GOOD: Sanitize user content
func loadUserContent(_ html: String) {
    let sanitized = sanitizeHTML(html)
    webView.loadHTMLString(sanitized, baseURL: nil)
}

// ❌ BAD: Trust user HTML
webView.loadHTMLString(userHTML, baseURL: nil) // XSS risk!
```

### 3. Path Traversal
```swift
// ✅ GOOD: Validate file paths
func loadFile(_ filename: String) throws -> Data {
    let sanitized = filename.components(separatedBy: "/").last ?? ""
    guard !sanitized.isEmpty,
          !sanitized.hasPrefix(".") else {
        throw FileError.invalidPath
    }
    let url = documentsDir.appendingPathComponent(sanitized)
    return try Data(contentsOf: url)
}

// ❌ BAD: Trust user paths
let url = URL(fileURLWithPath: userPath) // ../../../etc/passwd
```

### 4. Race Conditions
```swift
// ✅ GOOD: Thread-safe access
actor SecureCache {
    private var tokens: [String: String] = [:]
    
    func getToken(for key: String) -> String? {
        return tokens[key]
    }
    
    func setToken(_ token: String, for key: String) {
        tokens[key] = token
    }
}

// ❌ BAD: Unsynchronized dictionary
var tokens: [String: String] = [:] // Race condition!
```

### 5. Timing Attacks
```swift
// ✅ GOOD: Constant-time comparison
func compareTokens(_ a: String, _ b: String) -> Bool {
    guard a.count == b.count else { return false }
    var result = 0
    for (c1, c2) in zip(a, b) {
        result |= Int(c1.asciiValue! ^ c2.asciiValue!)
    }
    return result == 0
}

// ❌ BAD: Early return
func compareTokens(_ a: String, _ b: String) -> Bool {
    return a == b // Timing leak!
}
```

## Security Checklist for Code Reviews

### Authentication & Authorization
- [ ] Credentials never in source code
- [ ] All sensitive data in Keychain
- [ ] Token validation before use
- [ ] Failed auth logged
- [ ] Rate limiting implemented

### Network
- [ ] TLS certificate pinning
- [ ] Invalid certs rejected  
- [ ] Auth in headers (not query params)
- [ ] Timeout configured
- [ ] Retry with backoff

### Input Validation
- [ ] All user input validated
- [ ] Length limits enforced
- [ ] Special chars escaped
- [ ] Type checking performed
- [ ] Range validation

### Error Handling
- [ ] No sensitive info in errors
- [ ] All errors caught
- [ ] User-friendly messages
- [ ] Detailed logs (redacted)
- [ ] No crashes on bad input

### Privacy
- [ ] Permissions justified
- [ ] PII redacted from logs
- [ ] No undisclosed tracking
- [ ] User control implemented
- [ ] Privacy manifest updated

## Resources

- [Apple Security Guide](https://support.apple.com/guide/security/welcome/web)
- [OWASP Mobile Top 10](https://owasp.org/www-project-mobile-top-10/)
- [Swift Security Best Practices](https://swift.org/documentation/security/)
- [iOS App Security Best Practices](https://developer.apple.com/documentation/security)

## Contact

Security questions: [[email protected]]  
Security incidents: [[email protected]]

---

**Last Updated**: 2026-01-31  
**Version**: 1.0
