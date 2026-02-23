//
//  WindowRule.swift
//  Rectangle
//
//  Pro Feature: Automatic window rules — assign windows to workspaces or positions
//  when they are created.
//

import Foundation

// MARK: - WindowRuleAction

enum WindowRuleAction: Codable {
    /// Assign the window to a named workspace
    case assignToWorkspace(String)
    /// Move the window to a screen by index (0 = primary)
    case moveToScreen(Int)
    /// Apply a layout action (e.g. leftHalf, maximize)
    case applyPosition(WindowAction)

    // MARK: Codable

    private enum CodingKeys: String, CodingKey {
        case type, workspaceId, screenIndex, windowAction
    }
    private enum ActionType: String, Codable {
        case workspace, screen, position
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let type = try c.decode(ActionType.self, forKey: .type)
        switch type {
        case .workspace:
            self = .assignToWorkspace(try c.decode(String.self, forKey: .workspaceId))
        case .screen:
            self = .moveToScreen(try c.decode(Int.self, forKey: .screenIndex))
        case .position:
            self = .applyPosition(try c.decode(WindowAction.self, forKey: .windowAction))
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .assignToWorkspace(let id):
            try c.encode(ActionType.workspace, forKey: .type)
            try c.encode(id, forKey: .workspaceId)
        case .moveToScreen(let idx):
            try c.encode(ActionType.screen, forKey: .type)
            try c.encode(idx, forKey: .screenIndex)
        case .applyPosition(let action):
            try c.encode(ActionType.position, forKey: .type)
            try c.encode(action, forKey: .windowAction)
        }
    }

    /// Human-readable description for the UI
    var displayDescription: String {
        switch self {
        case .assignToWorkspace(let id):
            let name = WorkspaceManager.shared.workspace(withId: id)?.name ?? id
            return "Workspace \(name)"
        case .moveToScreen(let idx):
            return "Screen \(idx + 1)"
        case .applyPosition(let action):
            return action.displayName ?? action.name
        }
    }
}

// MARK: - WindowRule

struct WindowRule: Codable, Identifiable {
    let id: UUID
    /// Bundle ID to match (e.g. "com.apple.Safari"). Empty string = match all.
    var appBundleId: String
    /// Optional substring to match against the window title. nil = match any title.
    var windowTitleContains: String?
    /// The action to apply when the rule matches
    var action: WindowRuleAction

    init(id: UUID = UUID(), appBundleId: String, windowTitleContains: String? = nil, action: WindowRuleAction) {
        self.id = id
        self.appBundleId = appBundleId
        self.windowTitleContains = windowTitleContains
        self.action = action
    }
}
