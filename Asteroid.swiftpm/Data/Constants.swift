//
//  Constants.swift
//  Asteroid
//
//  Created by Daegeon Choi on 2022/04/11.
//

import SpriteKit

// Physics Category
let kShipCategory: UInt32 = 0x1 << 0
let kAsteroidCategory: UInt32 = 0x1 << 1
let kBulletCategory: UInt32 = 0x1 << 2

// Common
let kLineWidth: CGFloat = 2.0

// Ship
let kShipScale: CGFloat = 3.5
let kShipName: String = "ship"
let kShipLoadedColor: SKColor = .white
let kShipUnloadedColor: SKColor = .black

// Asteroid
let kAsteroidName: String = "asteroid"
let kDefaultMoveDuration: CFTimeInterval = 15.0
let kAsteroidMoveAction: String = "asteroidMove"
let kAsteroidSpeedConstant: CFTimeInterval = 0.9

// Bullet
let kBulletName: String = "bullet"
let kBulletRadius: CGFloat = 2.5

// Item
let kLifeItemName: String = "LifeItem"
let kGunItemName: String = "GunItem"

// HUD
let kHUDMargin: CGFloat = 50.0

let kScoreLabelName: String = "scoreLabel"
let kLifeLabelName: String = "lifeLabel"
let kRetroFontName: String = "Courier"
let kMenuFontName: String = "Avenir"
let kAsteroidLeftTitleName: String = "asteroidLeftTitle"
let kAsteroidLeftNumberName: String = "asteroidLeftNumber"

let kPopupBGName: String = "popupBG"
let kPopupTitleName: String = "popupTitle"
let kPopupWaveName: String = "popupWave"
let kPopupScoreName: String = "popupScore"

// Animation
let kExplosionDuration: CFTimeInterval = 0.5
let kExplosionLength: CGFloat = 10.0

// MARK: - HUD Layout System
struct HUDLayout {
    let scorePosition: CGPoint
    let livesPosition: CGPoint
    let asteroidCountPosition: CGPoint
    let safeMargin: CGFloat
    let verticalSpacing: CGFloat
    let fontSize: CGFloat

    init(screenSize: CGSize, safeAreaInsets: UIEdgeInsets) {
        // Dynamic margin: 5% of screen width, minimum 20, maximum 50
        self.safeMargin = max(20, min(50, screenSize.width * 0.05))

        let topMargin = safeAreaInsets.top + safeMargin
        let leadingMargin = safeAreaInsets.left + safeMargin
        let trailingMargin = screenSize.width - safeAreaInsets.right - safeMargin

        // Positions relative to scene center (0,0)
        let halfWidth = screenSize.width / 2
        let halfHeight = screenSize.height / 2

        // Dynamic spacing and font size
        self.verticalSpacing = max(30, screenSize.height * 0.04)
        self.fontSize = max(60, min(80, screenSize.width / 375 * 60))

        // Top-left for score
        self.scorePosition = CGPoint(
            x: -halfWidth + leadingMargin,
            y: halfHeight - topMargin
        )

        // Below score for lives
        self.livesPosition = CGPoint(
            x: -halfWidth + leadingMargin,
            y: halfHeight - topMargin - verticalSpacing
        )

        // Top-right for asteroid count
        self.asteroidCountPosition = CGPoint(
            x: halfWidth - trailingMargin,
            y: halfHeight - topMargin
        )
    }
}
