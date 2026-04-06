import AppKit

// main.swift is guaranteed to run on the main thread.
// MainActor.assumeIsolated lets us call @MainActor APIs safely here.
MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
