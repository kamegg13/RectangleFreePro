//
//  CustomSnapCalculation.swift
//  Rectangle
//
//  Pro Feature: Custom snap target calculation
//

import Foundation
import CoreGraphics

/// Rect normalisé : valeurs en 0.0-1.0 relatives à l'écran
struct NormalizedRect: Codable, Equatable {
    var x: Float      // minX / screenWidth
    var y: Float      // minY / screenHeight
    var width: Float
    var height: Float

    func toScreen(_ screen: CGRect) -> CGRect {
        CGRect(
            x: screen.minX + screen.width * CGFloat(x),
            y: screen.minY + screen.height * CGFloat(y),
            width: screen.width * CGFloat(width),
            height: screen.height * CGFloat(height)
        )
    }

    func contains(point: CGPoint, screen: CGRect) -> Bool {
        toScreen(screen).contains(point)
    }
}

struct CustomSnapTarget: Codable {
    let id: UUID
    var name: String
    /// Zone de déclenchement : si le curseur est dans cette zone, le snap s'active
    var triggerZone: NormalizedRect
    /// Frame résultante après snap
    var targetFrame: NormalizedRect

    init(id: UUID = UUID(), name: String, triggerZone: NormalizedRect, targetFrame: NormalizedRect) {
        self.id = id
        self.name = name
        self.triggerZone = triggerZone
        self.targetFrame = targetFrame
    }
}

final class CustomSnapCalculation: WindowCalculation {

    private let index: Int

    init(index: Int) {
        self.index = index
    }

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        let targets = Defaults.customSnapTargets.typedValue ?? []
        guard index < targets.count else {
            return RectResult(.null)
        }
        let target = targets[index]
        let visibleFrame = params.visibleFrameOfScreen
        let rect = target.targetFrame.toScreen(visibleFrame)
        return RectResult(rect)
    }
}
