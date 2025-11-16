//
//  MainMenuScene.swift
//  Asteroid+
//
//  Created by Daegeon Choi on 2022/04/13.
//

import SpriteKit

class MainMenuScene: SKScene {

    var systemTime: CFTimeInterval = 1.0
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

        configure()
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        self.systemTime = currentTime
        
        processAsteroidOutScreen()
    }
    
    private func configure() {
        
        self.backgroundColor = .black
        
        configureHUD()
        
        spawnRandomAsteroid()
        spawnRandomAsteroid()
        spawnRandomAsteroid()
        spawnRandomAsteroid()
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let tappedNode = atPoint(location)

        // Check if settings button was tapped
        if tappedNode.name == "settingsButton" {
            HapticManager.shared.selection()
            let transition = SKTransition.fade(withDuration: 0.5)
            let settingsScene = SettingsScene(size: size)
            settingsScene.userData = self.userData
            view?.presentScene(settingsScene, transition: transition)
            return
        }

        // Otherwise start game
        HapticManager.shared.selection()
        let gameScene = GameScene(size: self.size)
        // Pass safe area insets to GameScene
        gameScene.userData = self.userData

        self.view?.presentScene(gameScene, transition: .fade(withDuration: 1.0))
    }
}



//MARK: HUD
extension MainMenuScene {
    
    private func configureHUD() {
        guard let layout = hudLayout else { return }

        // Title label with responsive font size
        let titleLabel = SKLabelNode()
        titleLabel.fontName = "Avenir"
        titleLabel.text = "Asteroids+"
        titleLabel.horizontalAlignmentMode = .left
        titleLabel.verticalAlignmentMode = .bottom
        titleLabel.fontSize = layout.fontSize * 1.5  // Larger for title
        titleLabel.fontColor = .black
        titleLabel.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        titleLabel.zPosition = 10
        self.addChild(titleLabel)

        let titleBG = SKShapeNode(rect: CGRect(x: titleLabel.position.x-25, y: titleLabel.position.y-25, width: titleLabel.frame.width+50, height: titleLabel.frame.height+50))
        titleBG.fillColor = .white
        titleBG.zPosition = 9
        self.addChild(titleBG)

        // Touch anywhere label with responsive font size and safe positioning
        let touchAnywhereLabel = SKLabelNode()
        touchAnywhereLabel.fontName = kRetroFontName
        touchAnywhereLabel.fontColor = .white
        touchAnywhereLabel.fontSize = layout.fontSize * 0.3
        touchAnywhereLabel.text = "> Tap Anywhere to Start <"
        touchAnywhereLabel.position = CGPoint(x: titleBG.frame.midX, y: titleBG.frame.minY - titleBG.frame.height)
        self.addChild(touchAnywhereLabel)

        // Settings button
        let settingsButton = SKLabelNode()
        settingsButton.fontName = kRetroFontName
        settingsButton.fontColor = .white
        settingsButton.fontSize = layout.fontSize * 0.25
        settingsButton.text = "⚙ SETTINGS"
        settingsButton.name = "settingsButton"
        settingsButton.position = CGPoint(x: titleBG.frame.midX, y: touchAnywhereLabel.position.y - layout.verticalSpacing * 1.5)
        self.addChild(settingsButton)
    }
}

//MARK: Asteroid Event
extension MainMenuScene {
    
    private func processAsteroidOutScreen() {
        
        let screenSize = self.frame.size

        enumerateChildNodes(withName: kAsteroidName) { node, _ in
            
            guard let asteroid = node as? AsteroidNode else { return }
            
            let margin: CGFloat = 10.0
            let originalPosition = asteroid.position
            
            // right
            if asteroid.position.x >= screenSize.width + asteroid.frame.width {
                asteroid.position = CGPoint(x: -asteroid.frame.width + margin, y: asteroid.position.y)
              
            // left
            } else if asteroid.position.x <= -asteroid.frame.width-margin {
                asteroid.position = CGPoint(x: screenSize.width + asteroid.frame.width - margin, y: asteroid.position.y)
            }
            
            // top
            if asteroid.position.y >= screenSize.height + asteroid.frame.height {
                asteroid.position = CGPoint(x: asteroid.position.x, y: -asteroid.frame.width + margin)
                
            // bottom
            } else if asteroid.position.y <= -asteroid.frame.height-margin {
                asteroid.position = CGPoint(x: asteroid.position.x, y: screenSize.height + asteroid.frame.height - margin)
            }

            if originalPosition != asteroid.position {
                asteroid.removeAllActions()
                asteroid.run(SKAction.move(to: asteroid.movingVector.normalized() * CGPoint(x: 2000, y: 2000) + asteroid.position, duration: kDefaultMoveDuration))
            }
        }
    }
    
    private func spawnRandomAsteroid() {
        let target = AsteroidNode(scaleType: .Big, position: randomPoint())
        target.position = randomSpawnPoint()
        self.addChild(target)

        let destinationVector = randomPoint()
        target.movingVector = destinationVector.normalized()
        target.run(SKAction.move(to: destinationVector * CGPoint(x: 2000, y: 2000), duration: kDefaultMoveDuration))
    }
    
    private func randomPoint() -> CGPoint {
        
        let marginX: Float = 50.0
        let marginY: Float = 50.0
        
        let randomX = Float.random(in: -marginX...(Float(self.frame.maxX) + marginX))
        let randomY = Float.random(in: -marginY...(Float(self.frame.maxY) + marginY))
        
        return CGPoint(x: CGFloat(randomX), y: CGFloat(randomY))
    }
    
    private func randomSpawnPoint() -> CGPoint {
        
        let retryLimit = 5
        
        let center = childNode(withName: kShipName)?.position ?? CGPoint(x: self.frame.midX, y: self.frame.midY)
        
        let xRange = (center.x - 100)...(center.x + 100)
        let yRange = (center.y - 100)...(center.y + 100)
        
        
        
        var result = CGPoint(x: self.frame.width + 100, y: self.frame.height + 100)
        
        for _ in 0...retryLimit {
            
            result = randomPoint()
            
            if !xRange.contains(result.x) && !yRange.contains(result.y) {
                return result
            }
        }
        
        return result
    }
}

