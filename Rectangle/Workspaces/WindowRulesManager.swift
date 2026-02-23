//
//  WindowRulesManager.swift
//  Rectangle
//
//  Pro Feature: Apply window rules (on-window-detected) when a new window appears.
//

import Cocoa
import ApplicationServices

class WindowRulesManager {

    /// Evaluate all rules against a newly-created window and apply the first matching one.
    static func apply(windowId: CGWindowID, element: AXUIElement, app: NSRunningApplication) {
        guard let rules = Defaults.windowRules.typedValue, !rules.isEmpty else { return }
        let bundleId = app.bundleIdentifier ?? ""

        for rule in rules {
            guard rule.appBundleId.isEmpty || rule.appBundleId == bundleId else { continue }

            if let titleFilter = rule.windowTitleContains, !titleFilter.isEmpty {
                // Check window title
                var titleValue: CFTypeRef?
                AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &titleValue)
                let title = titleValue as? String ?? ""
                guard title.contains(titleFilter) else { continue }
            }

            // Rule matched — apply action on next run loop to let the window settle
            DispatchQueue.main.async {
                applyAction(rule.action, windowId: windowId, app: app)
            }
            return  // apply only the first matching rule
        }
    }

    // MARK: - Apply action

    private static func applyAction(_ action: WindowRuleAction, windowId: CGWindowID, app: NSRunningApplication) {
        switch action {

        case .assignToWorkspace(let workspaceId):
            WorkspaceManager.shared.moveWindow(windowId: windowId, to: workspaceId)

        case .moveToScreen(let screenIndex):
            guard screenIndex < NSScreen.screens.count else { return }
            guard let element = AccessibilityElement.getWindowElement(windowId) else { return }
            let targetScreen = NSScreen.screens[screenIndex]
            let currentFrame = element.frame
            // Translate to target screen, preserving size
            let newOrigin = CGPoint(x: targetScreen.visibleFrame.minX, y: targetScreen.visibleFrame.minY)
            element.setFrame(CGRect(origin: newOrigin, size: currentFrame.size))

        case .applyPosition(let windowAction):
            guard let element = AccessibilityElement.getWindowElement(windowId) else { return }
            let params = ExecutionParameters(windowAction, windowElement: element)
            AppDelegate.windowManager.execute(params)
        }
    }
}
