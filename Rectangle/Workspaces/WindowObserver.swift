//
//  WindowObserver.swift
//  Rectangle
//
//  Pro Feature: Passive window observation via AXObserver.
//  Detects window creation and destruction, registers with WorkspaceManager,
//  and applies WindowRules.
//

import Cocoa
import ApplicationServices

class WindowObserver {

    static let shared = WindowObserver()

    /// Per-PID AXObserver handles (retained to prevent deallocation)
    private var axObservers: [pid_t: AXObserver] = [:]
    private var workspaceLaunchObserver: NSObjectProtocol?
    private var workspaceTerminateObserver: NSObjectProtocol?

    // MARK: - Lifecycle

    func startObserving() {
        // Observe running apps at startup
        for app in NSWorkspace.shared.runningApplications where app.activationPolicy == .regular {
            addObserver(for: app)
        }

        // Observe future app launches
        workspaceLaunchObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            self?.addObserver(for: app)
        }

        // Observe app terminations — clean up AXObserver reference
        workspaceTerminateObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            self?.axObservers.removeValue(forKey: app.processIdentifier)
        }
    }

    // MARK: - AXObserver setup

    private func addObserver(for app: NSRunningApplication) {
        let pid = app.processIdentifier
        guard axObservers[pid] == nil else { return }

        var observer: AXObserver?
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()

        let result = AXObserverCreate(pid, { _, element, notification, userInfo in
            guard let userInfo = userInfo else { return }
            let obs = Unmanaged<WindowObserver>.fromOpaque(userInfo).takeUnretainedValue()
            let notif = notification as String
            if notif == kAXWindowCreatedNotification as String {
                obs.onWindowCreated(element: element)
            } else if notif == kAXUIElementDestroyedNotification as String {
                obs.onWindowDestroyed(element: element)
            }
        }, &observer)

        guard result == .success, let observer = observer else { return }

        let appElement = AXUIElementCreateApplication(pid)
        AXObserverAddNotification(observer, appElement, kAXWindowCreatedNotification as CFString, selfPtr)

        // Register destruction for existing windows of this app
        if let windows = existingWindowElements(for: appElement) {
            for window in windows {
                AXObserverAddNotification(observer, window, kAXUIElementDestroyedNotification as CFString, selfPtr)
                onWindowCreated(element: window, isExisting: true)
            }
        }

        let runLoopSource = AXObserverGetRunLoopSource(observer)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)
        axObservers[pid] = observer
    }

    // MARK: - Event handlers

    private func onWindowCreated(element: AXUIElement, isExisting: Bool = false) {
        guard let windowId = windowId(from: element) else { return }

        // Register with workspace manager
        WorkspaceManager.shared.registerWindow(windowId: windowId)

        // Add destruction observer for this window
        if let pid = pid(from: element), let observer = axObservers[pid] {
            let selfPtr = Unmanaged.passUnretained(self).toOpaque()
            AXObserverAddNotification(observer, element, kAXUIElementDestroyedNotification as CFString, selfPtr)
        }

        // Apply window rules
        if !isExisting {
            if let pid = pid(from: element),
               let app = NSRunningApplication(processIdentifier: pid) {
                WindowRulesManager.apply(windowId: windowId, element: element, app: app)
            }
        }
    }

    private func onWindowDestroyed(element: AXUIElement) {
        guard let windowId = windowId(from: element) else { return }
        WorkspaceManager.shared.removeWindow(windowId: windowId)
    }

    // MARK: - Helpers

    private func windowId(from element: AXUIElement) -> CGWindowID? {
        var windowId: CGWindowID = 0
        guard _AXUIElementGetWindow(element, &windowId) == .success else { return nil }
        return windowId == 0 ? nil : windowId
    }

    private func pid(from element: AXUIElement) -> pid_t? {
        var pid: pid_t = 0
        guard AXUIElementGetPid(element, &pid) == .success else { return nil }
        return pid
    }

    private func existingWindowElements(for appElement: AXUIElement) -> [AXUIElement]? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &value) == .success,
              let windows = value as? [AXUIElement] else { return nil }
        return windows
    }
}
