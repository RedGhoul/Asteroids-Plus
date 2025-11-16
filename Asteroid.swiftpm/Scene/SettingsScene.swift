//
//  SettingsScene.swift
//  Asteroid
//
//  Created for mobile adaptation
//

import SpriteKit

class SettingsScene: SKScene {
    private var titleLabel: SKLabelNode!
    private var backButton: SKLabelNode!
    private var controlSchemeLabel: SKLabelNode!
    private var hapticToggleLabel: SKLabelNode!
    private var hudLayout: HUDLayout?

    override func didMove(to view: SKView) {
        // Extract safe area insets from userData
        let topInset = userData?["safeAreaTop"] as? CGFloat ?? 0
        let bottomInset = userData?["safeAreaBottom"] as? CGFloat ?? 0
        let leadingInset = userData?["safeAreaLeading"] as? CGFloat ?? 0
        let trailingInset = userData?["safeAreaTrailing"] as? CGFloat ?? 0

        let safeInsets = UIEdgeInsets(
            top: topInset,
            left: leadingInset,
            bottom: bottomInset,
            right: trailingInset
        )

        hudLayout = HUDLayout(screenSize: size, safeAreaInsets: safeInsets)

        backgroundColor = .black
        setupUI()
    }

    private func setupUI() {
        guard let layout = hudLayout else { return }

        // Title
        titleLabel = SKLabelNode(text: "SETTINGS")
        titleLabel.fontSize = layout.fontSize * 1.2
        titleLabel.fontName = kMenuFontName
        titleLabel.position = CGPoint(x: frame.midX, y: frame.height * 0.75)
        addChild(titleLabel)

        // Control Scheme
        let controlText = "Controls: \(GameSettings.shared.controlScheme.rawValue)"
        controlSchemeLabel = SKLabelNode(text: controlText)
        controlSchemeLabel.fontSize = layout.fontSize * 0.5
        controlSchemeLabel.fontName = kRetroFontName
        controlSchemeLabel.position = CGPoint(x: frame.midX, y: frame.height * 0.55)
        controlSchemeLabel.name = "controlScheme"
        addChild(controlSchemeLabel)

        // Control scheme hint
        let controlHint = SKLabelNode(text: "(Tap to change)")
        controlHint.fontSize = layout.fontSize * 0.25
        controlHint.fontName = kRetroFontName
        controlHint.fontColor = UIColor.white.withAlphaComponent(0.6)
        controlHint.position = CGPoint(x: frame.midX, y: frame.height * 0.48)
        addChild(controlHint)

        // Haptic Toggle
        let hapticStatus = GameSettings.shared.hapticFeedbackEnabled ? "ON" : "OFF"
        hapticToggleLabel = SKLabelNode(text: "Haptics: \(hapticStatus)")
        hapticToggleLabel.fontSize = layout.fontSize * 0.5
        hapticToggleLabel.fontName = kRetroFontName
        hapticToggleLabel.position = CGPoint(x: frame.midX, y: frame.height * 0.35)
        hapticToggleLabel.name = "hapticToggle"
        addChild(hapticToggleLabel)

        // Haptic hint
        let hapticHint = SKLabelNode(text: "(Tap to toggle)")
        hapticHint.fontSize = layout.fontSize * 0.25
        hapticHint.fontName = kRetroFontName
        hapticHint.fontColor = UIColor.white.withAlphaComponent(0.6)
        hapticHint.position = CGPoint(x: frame.midX, y: frame.height * 0.28)
        addChild(hapticHint)

        // Back Button
        backButton = SKLabelNode(text: "< BACK TO MENU")
        backButton.fontSize = layout.fontSize * 0.5
        backButton.fontName = kRetroFontName
        backButton.position = CGPoint(x: frame.midX, y: frame.height * 0.15)
        backButton.name = "back"
        addChild(backButton)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNode = atPoint(location)

        if tappedNode.name == "back" {
            HapticManager.shared.selection()
            let transition = SKTransition.fade(withDuration: 0.5)
            let menuScene = MainMenuScene(size: size)
            menuScene.userData = self.userData
            view?.presentScene(menuScene, transition: transition)
        } else if tappedNode.name == "controlScheme" {
            toggleControlScheme()
        } else if tappedNode.name == "hapticToggle" {
            toggleHaptic()
        }
    }

    private func toggleControlScheme() {
        HapticManager.shared.selection()
        let schemes = ControlScheme.allCases
        if let currentIndex = schemes.firstIndex(of: GameSettings.shared.controlScheme) {
            let nextIndex = (currentIndex + 1) % schemes.count
            GameSettings.shared.controlScheme = schemes[nextIndex]
            controlSchemeLabel.text = "Controls: \(GameSettings.shared.controlScheme.rawValue)"
        }
    }

    private func toggleHaptic() {
        GameSettings.shared.hapticFeedbackEnabled.toggle()
        HapticManager.shared.selection()
        let status = GameSettings.shared.hapticFeedbackEnabled ? "ON" : "OFF"
        hapticToggleLabel.text = "Haptics: \(status)"
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)

        guard let view = view else { return }

        // Recalculate layout when size changes
        let topInset = userData?["safeAreaTop"] as? CGFloat ?? 0
        let bottomInset = userData?["safeAreaBottom"] as? CGFloat ?? 0
        let leadingInset = userData?["safeAreaLeading"] as? CGFloat ?? 0
        let trailingInset = userData?["safeAreaTrailing"] as? CGFloat ?? 0

        let safeInsets = UIEdgeInsets(
            top: topInset,
            left: leadingInset,
            bottom: bottomInset,
            right: trailingInset
        )

        hudLayout = HUDLayout(screenSize: size, safeAreaInsets: safeInsets)

        // Update all UI element positions (simplified - in production, reposition all elements)
        titleLabel.fontSize = hudLayout?.fontSize ?? 60
    }
}
