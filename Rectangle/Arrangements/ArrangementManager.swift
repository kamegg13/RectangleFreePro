//
//  ArrangementManager.swift
//  Rectangle
//
//  Pro Feature: Save and restore window arrangements
//

import Cocoa

struct WindowArrangement: Codable {
    /// Bundle ID de l'application
    let bundleId: String
    /// Frame normalisée : valeurs 0.0-1.0 relatives à l'écran
    let normalizedFrame: NormalizedRect
    /// Index de l'écran (basé sur l'ordre dans NSScreen.screens)
    let screenIndex: Int
}

struct Arrangement: Codable {
    let name: String
    let date: Date
    let windows: [WindowArrangement]
}

class ArrangementManager {

    // MARK: - Paths

    private static var supportDir: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("Rectangle/arrangements", isDirectory: true)
    }

    private static func arrangementURL(name: String) -> URL {
        supportDir.appendingPathComponent("\(name).json")
    }

    // MARK: - Save

    static func save(name: String) throws {
        let windows = AccessibilityElement.getAllWindowElements()
        var arrangements: [WindowArrangement] = []

        let runningApps = NSWorkspace.shared.runningApplications
        for w in windows {
            guard let pid = w.pid,
                  let app = runningApps.first(where: { $0.processIdentifier == pid }),
                  let bundleId = app.bundleIdentifier,
                  !bundleId.isEmpty else { continue }
            let frame = w.frame
            let screenIdx = screenIndex(for: frame) ?? 0
            let screenFrame = NSScreen.screens[screenIdx].frame
            let sfW = screenFrame.width > 0 ? screenFrame.width : 1
            let sfH = screenFrame.height > 0 ? screenFrame.height : 1
            let normalized = NormalizedRect(
                x: Float((frame.minX - screenFrame.minX) / sfW),
                y: Float((frame.minY - screenFrame.minY) / sfH),
                width: Float(frame.width / sfW),
                height: Float(frame.height / sfH)
            )
            arrangements.append(WindowArrangement(bundleId: bundleId, normalizedFrame: normalized, screenIndex: screenIdx))
        }

        let arrangement = Arrangement(name: name, date: Date(), windows: arrangements)

        try FileManager.default.createDirectory(at: supportDir, withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(arrangement)
        try data.write(to: arrangementURL(name: name))
    }

    // MARK: - Restore

    static func restore(name: String) throws {
        let data = try Data(contentsOf: arrangementURL(name: name))
        let arrangement = try JSONDecoder().decode(Arrangement.self, from: data)
        let screens = NSScreen.screens
        let runningApps = NSWorkspace.shared.runningApplications

        for wa in arrangement.windows {
            guard let app = runningApps.first(where: { $0.bundleIdentifier == wa.bundleId }),
                  wa.screenIndex < screens.count
            else { continue }

            let screen = screens[wa.screenIndex]
            let targetFrame = wa.normalizedFrame.toScreen(screen.frame)

            // Trouver les fenêtres de cette app
            let appWindows = AccessibilityElement.getAllWindowElements().filter { $0.pid == app.processIdentifier }
            for w in appWindows {
                w.setFrame(targetFrame)
                break // on ne restaure que la première fenêtre par app
            }
        }
    }

    // MARK: - Delete

    static func delete(name: String) throws {
        try FileManager.default.removeItem(at: arrangementURL(name: name))
    }

    // MARK: - List

    static func list() -> [String] {
        guard let files = try? FileManager.default.contentsOfDirectory(at: supportDir, includingPropertiesForKeys: nil) else { return [] }
        return files
            .filter { $0.pathExtension == "json" }
            .map { $0.deletingPathExtension().lastPathComponent }
            .sorted()
    }

    // MARK: - Helpers

    private static func screenIndex(for frame: CGRect) -> Int? {
        let midpoint = CGPoint(x: frame.midX, y: frame.midY)
        for (idx, screen) in NSScreen.screens.enumerated() {
            if screen.frame.contains(midpoint) {
                return idx
            }
        }
        return 0
    }
}
