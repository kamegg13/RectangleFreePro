//
//  WorkspaceManagerTests.swift
//  RectangleTests
//
//  Tests du WorkspaceManager : données, navigation, persistance
//

import XCTest
@testable import Rectangle

class WorkspaceManagerTests: XCTestCase {

    override func setUp() {
        // Reset defaults before each test
        Defaults.workspaces.typedValue = nil
        Defaults.activeWorkspaceId.value = nil
        Defaults.workspaceAssignments.typedValue = nil
    }

    override func tearDown() {
        Defaults.workspaces.typedValue = nil
        Defaults.activeWorkspaceId.value = nil
        Defaults.workspaceAssignments.typedValue = nil
    }

    // MARK: - Default workspaces

    func testDefaultWorkspacesCreated() {
        let defaults = WorkspaceManager.makeDefault()
        XCTAssertEqual(defaults.count, 9)
        XCTAssertEqual(defaults[0].id, "1")
        XCTAssertEqual(defaults[0].name, "1")
        XCTAssertEqual(defaults[8].id, "9")
    }

    func testInitializeCreatesDefaultsIfNone() {
        let wm = WorkspaceManager()
        wm.initialize()
        XCTAssertEqual(wm.workspaceCount, 9)
        XCTAssertEqual(wm.activeWorkspaceId, "1")
    }

    // MARK: - WindowAction raw values

    func testSwitchWorkspaceRawValues() {
        XCTAssertEqual(WindowAction.switchWorkspace1.rawValue, 108)
        XCTAssertEqual(WindowAction.switchWorkspace9.rawValue, 116)
    }

    func testMoveWindowToWorkspaceRawValues() {
        XCTAssertEqual(WindowAction.moveWindowToWorkspace1.rawValue, 117)
        XCTAssertEqual(WindowAction.moveWindowToWorkspace9.rawValue, 125)
    }

    func testSwitchWorkspaceActionsHaveDisplayNames() {
        XCTAssertNotNil(WindowAction.switchWorkspace1.displayName)
        XCTAssertNotNil(WindowAction.switchWorkspace9.displayName)
        XCTAssertNotNil(WindowAction.moveWindowToWorkspace1.displayName)
    }

    func testSwitchWorkspaceActionsHaveNames() {
        XCTAssertEqual(WindowAction.switchWorkspace1.name, "switchWorkspace1")
        XCTAssertEqual(WindowAction.moveWindowToWorkspace3.name, "moveWindowToWorkspace3")
    }

    // MARK: - WorkspaceConfig Codable

    func testWorkspaceConfigCodable() throws {
        let ws = WorkspaceConfig(id: "web", name: "Web")
        let data = try JSONEncoder().encode(ws)
        let decoded = try JSONDecoder().decode(WorkspaceConfig.self, from: data)
        XCTAssertEqual(decoded.id, "web")
        XCTAssertEqual(decoded.name, "Web")
    }

    // MARK: - Rename workspace

    func testRenameWorkspace() {
        let wm = WorkspaceManager()
        wm.initialize()
        wm.renameWorkspace(id: "1", to: "Browser")
        XCTAssertEqual(wm.workspace(withId: "1")?.name, "Browser")
    }

    // MARK: - Window registration

    func testRegisterWindowInActiveWorkspace() {
        let wm = WorkspaceManager()
        wm.initialize()
        wm.registerWindow(windowId: 1001)
        let ids = wm.windowIds(for: "1")
        XCTAssertTrue(ids.contains(1001))
    }

    func testRegisterWindowNotDuplicated() {
        let wm = WorkspaceManager()
        wm.initialize()
        wm.registerWindow(windowId: 1001)
        wm.registerWindow(windowId: 1001)  // second call should be ignored
        XCTAssertEqual(wm.windowIds(for: "1").filter { $0 == 1001 }.count, 1)
    }

    func testRemoveWindow() {
        let wm = WorkspaceManager()
        wm.initialize()
        wm.registerWindow(windowId: 2000)
        wm.removeWindow(windowId: 2000)
        XCTAssertFalse(wm.windowIds(for: "1").contains(2000))
    }

    // MARK: - Move window between workspaces

    func testMoveWindowToOtherWorkspace() {
        let wm = WorkspaceManager()
        wm.initialize()
        wm.registerWindow(windowId: 3000)
        XCTAssertTrue(wm.windowIds(for: "1").contains(3000))
        wm.moveWindow(windowId: 3000, to: "2")
        XCTAssertFalse(wm.windowIds(for: "1").contains(3000))
        XCTAssertTrue(wm.windowIds(for: "2").contains(3000))
    }

    func testWorkspaceIdContaining() {
        let wm = WorkspaceManager()
        wm.initialize()
        wm.registerWindow(windowId: 4000)
        XCTAssertEqual(wm.workspaceId(containing: 4000), "1")
    }

    // MARK: - Workspace gapsApplicable

    func testSwitchWorkspaceGapsNone() {
        XCTAssertEqual(WindowAction.switchWorkspace1.gapsApplicable, .none)
        XCTAssertEqual(WindowAction.moveWindowToWorkspace5.gapsApplicable, .none)
    }

    // MARK: - Notification names

    func testWorkspaceNotificationNamesExist() {
        let switched = Notification.Name.workspaceSwitched
        let renamed = Notification.Name.workspaceRenamed
        XCTAssertNotNil(switched)
        XCTAssertNotNil(renamed)
    }
}
