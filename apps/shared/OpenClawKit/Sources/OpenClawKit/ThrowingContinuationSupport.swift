import Foundation
import os

/// Lock-free flag that ensures a closure fires at most once.
/// Thread-safe via `os_unfair_lock`; `@unchecked Sendable` because the
/// lock + flag pair is internally synchronised.
public final class OnceFlag: @unchecked Sendable {
    private var _fired = false
    private var _lock = os_unfair_lock()

    public init() {}

    /// Returns `true` exactly once; every subsequent call returns `false`.
    public func tryAcquire() -> Bool {
        os_unfair_lock_lock(&_lock)
        defer { os_unfair_lock_unlock(&_lock) }
        if _fired { return false }
        _fired = true
        return true
    }
}

public enum ThrowingContinuationSupport {
    public static func resumeVoid(_ continuation: CheckedContinuation<Void, Error>, error: Error?) {
        if let error {
            continuation.resume(throwing: error)
        } else {
            continuation.resume(returning: ())
        }
    }
}
