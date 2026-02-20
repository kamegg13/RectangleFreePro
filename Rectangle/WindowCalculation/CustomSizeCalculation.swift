//
//  CustomSizeCalculation.swift
//  Rectangle
//
//  Pro Feature: generalization of SpecifiedCalculation with configurable position
//

import Foundation

final class CustomSizeCalculation: WindowCalculation {

    private let index: Int

    init(index: Int) {
        self.index = index
    }

    override func calculateRect(_ params: RectCalculationParameters) -> RectResult {
        let sizes = Defaults.customSizes.typedValue ?? []
        guard index < sizes.count else {
            return RectResult(.null)
        }
        let spec = sizes[index]

        let visibleFrame = params.visibleFrameOfScreen
        var rect = visibleFrame

        // Calculer la taille
        rect.size.width = spec.width <= 1
            ? visibleFrame.width * CGFloat(spec.width)
            : min(visibleFrame.width, CGFloat(spec.width))
        rect.size.height = spec.height <= 1
            ? visibleFrame.height * CGFloat(spec.height)
            : min(visibleFrame.height, CGFloat(spec.height))

        // Calculer la position selon centerX / centerY
        let availableX = visibleFrame.width - rect.width
        let availableY = visibleFrame.height - rect.height
        rect.origin.x = round(visibleFrame.minX + availableX * CGFloat(spec.centerX))
        rect.origin.y = round(visibleFrame.minY + availableY * CGFloat(spec.centerY))

        return RectResult(rect)
    }
}
