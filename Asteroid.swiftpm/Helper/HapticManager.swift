//
//  HapticManager.swift
//  Asteroid
//
//  Created for mobile adaptation
//

import UIKit

class HapticManager {
    static let shared = HapticManager()

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationFeedback = UINotificationFeedbackGenerator()
    private let selectionFeedback = UISelectionFeedbackGenerator()

    private init() {
        // Prepare generators
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
    }

    func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard GameSettings.shared.hapticFeedbackEnabled else { return }

        switch style {
        case .light:
            lightImpact.impactOccurred()
            lightImpact.prepare()
        case .medium:
            mediumImpact.impactOccurred()
            mediumImpact.prepare()
        case .heavy:
            heavyImpact.impactOccurred()
            heavyImpact.prepare()
        case .rigid:
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        case .soft:
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        @unknown default:
            mediumImpact.impactOccurred()
            mediumImpact.prepare()
        }
    }

    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard GameSettings.shared.hapticFeedbackEnabled else { return }
        notificationFeedback.notificationOccurred(type)
        notificationFeedback.prepare()
    }

    func selection() {
        guard GameSettings.shared.hapticFeedbackEnabled else { return }
        selectionFeedback.selectionChanged()
        selectionFeedback.prepare()
    }
}
