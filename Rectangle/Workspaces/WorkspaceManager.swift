//
//  WorkspaceManager.swift
//  Rectangle
//
//  Pro Feature: Named Workspaces — software-based like AeroSpace.
//  Inactive windows are moved off-screen (x = -10000) and restored when switching back.
//

import Cocoa

// MARK: - Data model

struct WorkspaceConfig: Codable {
    let id: String       // Unique identifier ("1"…"9" or custom)
    var name: String     // Display name shown in the status indicator

    init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

// MARK: - WorkspaceManager

class WorkspaceManager {

    static let shared = WorkspaceManager()

    /// X coordinate used to hide off-screen windows (far left, never visible)
    static let offScreenX: CGFloat = -10000

    /// The list of defined workspaces
    private(set) var workspaces: [WorkspaceConfig] = []
    /// The currently active workspace ID
    private(set) var activeWorkspaceId: String = "1"

    /// Mapping: workspaceId → [windowId]
    private var windowAssignments: [String: [CGWindowID]] = [:]
    /// Saved on-screen frames for windows currently hidden off-screen
    private var savedFrames: [CGWindowID: CGRect] = [:]

    // MARK: - Initialization

    func initialize() {
        workspaces = Defaults.workspaces.typedValue ?? WorkspaceManager.makeDefault()
        activeWorkspaceId = Defaults.activeWorkspaceId.value ?? "1"
        windowAssignments = Defaults.workspaceAssignments.typedValue ?? [:]
        if !workspaces.contains(where: { $0.id == activeWorkspaceId }) {
            activeWorkspaceId = workspaces.first?.id ?? "1"
        }
    }

    static func makeDefault() -> [WorkspaceConfig] {
        (1...9).map { WorkspaceConfig(id: "\($0)", name: "\($0)") }
    }

    // MARK: - Switch

    /// Switch the active workspace. Hides current-workspace windows, shows target-workspace windows.
    func switchTo(workspaceId: String) {
        guard workspaceId != activeWorkspaceId else { return }

        // Hide windows of current workspace
        for wid in windowIds(for: activeWorkspaceId) {
            hideWindow(windowId: wid)
        }

        // Show windows of target workspace
        for wid in windowIds(for: workspaceId) {
            showWindow(windowId: wid)
        }

        activeWorkspaceId = workspaceId
        Defaults.activeWorkspaceId.value = workspaceId
        Notification.Name.workspaceSwitched.post(object: workspaceId)
    }

    // MARK: - Window registration

    /// Register a newly detected window in the currently active workspace (if not already tracked).
    func registerWindow(windowId: CGWindowID) {
        let alreadyTracked = windowAssignments.values.contains { $0.contains(windowId) }
        guard !alreadyTracked else { return }
        windowAssignments[activeWorkspaceId, default: []].append(windowId)
        saveAssignments()
    }

    /// Move a tracked window to a different workspace.
    func moveWindow(windowId: CGWindowID, to workspaceId: String) {
        for key in windowAssignments.keys {
            windowAssignments[key]?.removeAll { $0 == windowId }
        }
        windowAssignments[workspaceId, default: []].append(windowId)
        saveAssignments()
        if workspaceId != activeWorkspaceId {
            hideWindow(windowId: windowId)
        }
    }

    /// Remove a destroyed window from all workspaces.
    func removeWindow(windowId: CGWindowID) {
        for key in windowAssignments.keys {
            windowAssignments[key]?.removeAll { $0 == windowId }
        }
        savedFrames.removeValue(forKey: windowId)
        saveAssignments()
    }

    // MARK: - Workspace CRUD

    var workspaceCount: Int { workspaces.count }

    func workspace(withId id: String) -> WorkspaceConfig? {
        workspaces.first { $0.id == id }
    }

    func workspace(at index: Int) -> WorkspaceConfig? {
        guard index >= 0, index < workspaces.count else { return nil }
        return workspaces[index]
    }

    func renameWorkspace(id: String, to name: String) {
        guard let idx = workspaces.firstIndex(where: { $0.id == id }) else { return }
        workspaces[idx].name = name
        saveWorkspaces()
        Notification.Name.workspaceRenamed.post(object: id)
    }

    // MARK: - Query

    func windowIds(for workspaceId: String) -> [CGWindowID] {
        windowAssignments[workspaceId] ?? []
    }

    func workspaceId(containing windowId: CGWindowID) -> String? {
        windowAssignments.first { $0.value.contains(windowId) }?.key
    }

    // MARK: - Private helpers

    private func hideWindow(windowId: CGWindowID) {
        guard let element = AccessibilityElement.getWindowElement(windowId) else { return }
        let current = element.frame
        guard current.minX > WorkspaceManager.offScreenX + 500 else { return }  // already hidden
        savedFrames[windowId] = current
        element.setFrame(
            CGRect(x: WorkspaceManager.offScreenX, y: current.minY,
                   width: current.width, height: current.height),
            adjustSizeFirst: false
        )
    }

    private func showWindow(windowId: CGWindowID) {
        guard let element = AccessibilityElement.getWindowElement(windowId) else { return }
        guard let saved = savedFrames[windowId] else { return }
        element.setFrame(saved)
        savedFrames.removeValue(forKey: windowId)
    }

    private func saveWorkspaces() {
        Defaults.workspaces.typedValue = workspaces
    }

    private func saveAssignments() {
        Defaults.workspaceAssignments.typedValue = windowAssignments
    }
}
