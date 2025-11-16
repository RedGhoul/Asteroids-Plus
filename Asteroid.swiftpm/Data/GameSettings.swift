//
//  GameSettings.swift
//  Asteroid
//
//  Created for mobile adaptation
//

import Foundation

enum ControlScheme: String, CaseIterable {
    case touchToPoint = "Touch to Point"
    case virtualJoystick = "Virtual Joystick"
}

class GameSettings: ObservableObject {
    static let shared = GameSettings()

    @Published var controlScheme: ControlScheme {
        didSet {
            UserDefaults.standard.set(controlScheme.rawValue, forKey: "controlScheme")
        }
    }

    @Published var hapticFeedbackEnabled: Bool {
        didSet {
            UserDefaults.standard.set(hapticFeedbackEnabled, forKey: "hapticFeedback")
        }
    }

    @Published var soundVolume: Float {
        didSet {
            UserDefaults.standard.set(soundVolume, forKey: "soundVolume")
        }
    }

    private init() {
        let scheme = UserDefaults.standard.string(forKey: "controlScheme") ?? ControlScheme.touchToPoint.rawValue
        self.controlScheme = ControlScheme(rawValue: scheme) ?? .touchToPoint
        self.hapticFeedbackEnabled = UserDefaults.standard.bool(forKey: "hapticFeedback")
        self.soundVolume = UserDefaults.standard.float(forKey: "soundVolume")

        // Set defaults if first launch
        if UserDefaults.standard.object(forKey: "hapticFeedback") == nil {
            self.hapticFeedbackEnabled = true
            UserDefaults.standard.set(true, forKey: "hapticFeedback")
        }
        if UserDefaults.standard.object(forKey: "soundVolume") == nil {
            self.soundVolume = 1.0
            UserDefaults.standard.set(1.0, forKey: "soundVolume")
        }
    }
}
