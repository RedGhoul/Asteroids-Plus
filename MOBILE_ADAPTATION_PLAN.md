# Mobile Adaptation Implementation Plan for Asteroids-Plus

## Overview
This iOS SpriteKit game is already touch-based but needs enhancements for optimal phone usability across different device sizes, orientations, and user preferences.

---

## Phase 1: Safe Area & Responsive Layout

### Step 1.1: Add Safe Area Support
**File:** `Asteroid.swiftpm/Base/ContentView.swift`

**Current Issue:** UI currently uses `.ignoresSafeArea()` which causes HUD elements to be obscured by notches/home indicators.

**Implementation:**
1. Remove `.ignoresSafeArea()` modifier
2. Add `GeometryReader` to capture safe area insets
3. Pass safe area insets to the scene via `userData` or custom scene property
4. Update scene initialization to accept safe area values

**Code Changes:**
```swift
// In ContentView.swift
struct ContentView: View {
    @State private var safeAreaInsets: EdgeInsets = .init()

    var body: some View {
        GeometryReader { geometry in
            SpriteView(scene: scene(for: geometry))
                .onAppear {
                    safeAreaInsets = geometry.safeAreaInsets
                }
        }
    }

    func scene(for geometry: GeometryProxy) -> SKScene {
        let scene = MainMenuScene()
        scene.size = geometry.size
        scene.scaleMode = .aspectFill
        // Pass safe area info
        scene.userData = NSMutableDictionary()
        scene.userData?["safeAreaTop"] = geometry.safeAreaInsets.top
        scene.userData?["safeAreaBottom"] = geometry.safeAreaInsets.bottom
        scene.userData?["safeAreaLeading"] = geometry.safeAreaInsets.leading
        scene.userData?["safeAreaTrailing"] = geometry.safeAreaInsets.trailing
        return scene
    }
}
```

---

### Step 1.2: Create Responsive HUD Layout System
**File:** `Asteroid.swiftpm/Data/Constants.swift`

**Current Issue:** Fixed `kHUDMargin = 50.0` doesn't adapt to different screen sizes.

**Implementation:**
1. Create `HUDLayout` struct to calculate dynamic positions
2. Add method to compute margins based on screen size and safe areas
3. Export calculated positions for score, lives, asteroid count

**Code Changes:**
```swift
// Add to Constants.swift
struct HUDLayout {
    let scorePosition: CGPoint
    let livesPosition: CGPoint
    let asteroidCountPosition: CGPoint
    let safeMargin: CGFloat

    init(screenSize: CGSize, safeAreaInsets: UIEdgeInsets) {
        // Dynamic margin: 5% of screen width, minimum 20, maximum 50
        self.safeMargin = max(20, min(50, screenSize.width * 0.05))

        let topMargin = safeAreaInsets.top + safeMargin
        let leadingMargin = safeAreaInsets.left + safeMargin
        let trailingMargin = screenSize.width - safeAreaInsets.right - safeMargin

        // Positions relative to scene center (0,0)
        let halfWidth = screenSize.width / 2
        let halfHeight = screenSize.height / 2

        // Top-left for score
        self.scorePosition = CGPoint(
            x: -halfWidth + leadingMargin,
            y: halfHeight - topMargin
        )

        // Below score for lives
        self.livesPosition = CGPoint(
            x: -halfWidth + leadingMargin,
            y: halfHeight - topMargin - 40
        )

        // Top-right for asteroid count
        self.asteroidCountPosition = CGPoint(
            x: halfWidth - trailingMargin,
            y: halfHeight - topMargin
        )
    }
}
```

---

### Step 1.3: Update GameScene to Use Responsive Layout
**File:** `Asteroid.swiftpm/Scene/GameScene.swift`

**Implementation:**
1. Add `hudLayout` property to GameScene
2. Initialize HUD layout in `didMove(to view:)`
3. Update HUD positioning in `setupScoreHud()` and `setupAsteroidCountHud()`

**Code Changes:**
```swift
// Add property
private var hudLayout: HUDLayout?

// In didMove(to view:)
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

    // ... rest of setup
}

// Update setupScoreHud()
private func setupScoreHud() {
    guard let layout = hudLayout else { return }

    scoreLabel.position = layout.scorePosition
    // ... rest of setup
}

// Update setupAsteroidCountHud() similarly
```

---

### Step 1.4: Apply Same Updates to MainMenuScene
**File:** `Asteroid.swiftpm/Scene/MainMenuScene.swift`

**Implementation:**
1. Add HUD layout support for menu buttons/text
2. Position title and "Tap to Start" text with safe areas considered

---

## Phase 2: Enhanced Touch Controls

### Step 2.1: Add Visual Touch Indicator
**File:** `Asteroid.swiftpm/Scene/GameScene.swift`

**Current Issue:** No visual feedback showing where user is touching.

**Implementation:**
1. Create `touchIndicator` SKShapeNode (semi-transparent circle)
2. Show indicator at touch location during `touchesMoved`
3. Hide indicator on `touchesEnded`

**Code Changes:**
```swift
// Add property
private var touchIndicator: SKShapeNode?

// In didMove(to view:)
setupTouchIndicator()

private func setupTouchIndicator() {
    touchIndicator = SKShapeNode(circleOfRadius: 30)
    touchIndicator?.fillColor = .clear
    touchIndicator?.strokeColor = UIColor.white.withAlphaComponent(0.5)
    touchIndicator?.lineWidth = 3
    touchIndicator?.isHidden = true
    touchIndicator?.zPosition = 1000
    addChild(touchIndicator!)
}

// In touchesBegan
touchIndicator?.position = point
touchIndicator?.isHidden = false

// In touchesMoved
touchIndicator?.position = point

// In touchesEnded
touchIndicator?.isHidden = true
```

---

### Step 2.2: Add Alternative Control Scheme - Virtual Joystick (Optional)
**New File:** `Asteroid.swiftpm/Helper/VirtualJoystick.swift`

**Purpose:** Provide an alternative control option for users who prefer joystick-style controls.

**Implementation:**
1. Create `VirtualJoystick` class extending `SKNode`
2. Add base (outer circle) and thumb (inner circle) nodes
3. Track touch distance and angle from center
4. Return normalized direction vector

**Code Changes:**
```swift
import SpriteKit

class VirtualJoystick: SKNode {
    private let baseRadius: CGFloat = 60
    private let thumbRadius: CGFloat = 30
    private let maxDistance: CGFloat = 50

    private var baseNode: SKShapeNode!
    private var thumbNode: SKShapeNode!
    private var isTracking = false

    var direction: CGVector = .zero

    override init() {
        super.init()
        setupNodes()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    private func setupNodes() {
        // Base circle
        baseNode = SKShapeNode(circleOfRadius: baseRadius)
        baseNode.fillColor = UIColor.white.withAlphaComponent(0.2)
        baseNode.strokeColor = UIColor.white.withAlphaComponent(0.5)
        baseNode.lineWidth = 2
        baseNode.zPosition = 100
        addChild(baseNode)

        // Thumb circle
        thumbNode = SKShapeNode(circleOfRadius: thumbRadius)
        thumbNode.fillColor = UIColor.white.withAlphaComponent(0.6)
        thumbNode.strokeColor = .white
        thumbNode.lineWidth = 2
        thumbNode.zPosition = 101
        addChild(thumbNode)

        isHidden = true
    }

    func touchBegan(at location: CGPoint) {
        position = location
        isHidden = false
        isTracking = true
        thumbNode.position = .zero
        direction = .zero
    }

    func touchMoved(to location: CGPoint) {
        guard isTracking else { return }

        let delta = CGPoint(x: location.x - position.x, y: location.y - position.y)
        let distance = sqrt(delta.x * delta.x + delta.y * delta.y)

        if distance <= maxDistance {
            thumbNode.position = delta
            direction = CGVector(dx: delta.x / maxDistance, dy: delta.y / maxDistance)
        } else {
            let angle = atan2(delta.y, delta.x)
            thumbNode.position = CGPoint(
                x: cos(angle) * maxDistance,
                y: sin(angle) * maxDistance
            )
            direction = CGVector(dx: cos(angle), dy: sin(angle))
        }
    }

    func touchEnded() {
        isHidden = true
        isTracking = false
        thumbNode.position = .zero
        direction = .zero
    }
}
```

---

### Step 2.3: Add Settings for Control Scheme Selection
**New File:** `Asteroid.swiftpm/Data/GameSettings.swift`

**Implementation:**
1. Create `GameSettings` class using `UserDefaults`
2. Add control scheme preference (Touch-to-Point vs Virtual Joystick)
3. Add haptic feedback toggle
4. Add sound/music volume controls

**Code Changes:**
```swift
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
        }
        if UserDefaults.standard.object(forKey: "soundVolume") == nil {
            self.soundVolume = 1.0
        }
    }
}
```

---

## Phase 3: Haptic Feedback

### Step 3.1: Create Haptic Feedback Manager
**New File:** `Asteroid.swiftpm/Helper/HapticManager.swift`

**Implementation:**
1. Create `HapticManager` singleton
2. Add methods for different feedback types (light, medium, heavy, success, error)
3. Check settings before triggering feedback

**Code Changes:**
```swift
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
        case .medium:
            mediumImpact.impactOccurred()
        case .heavy:
            heavyImpact.impactOccurred()
        case .rigid:
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        case .soft:
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        @unknown default:
            mediumImpact.impactOccurred()
        }
    }

    func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        guard GameSettings.shared.hapticFeedbackEnabled else { return }
        notificationFeedback.notificationOccurred(type)
    }

    func selection() {
        guard GameSettings.shared.hapticFeedbackEnabled else { return }
        selectionFeedback.selectionChanged()
    }
}
```

---

### Step 3.2: Add Haptic Feedback to Game Events
**File:** `Asteroid.swiftpm/Scene/GameScene.swift`

**Implementation:**
1. Add haptics when shooting bullets (`touchesEnded`)
2. Add haptics when asteroid is destroyed (`didBegin` contact)
3. Add haptics when ship is hit (heavy impact)
4. Add haptics when collecting power-ups (success notification)
5. Add haptics when game over (error notification)

**Code Changes:**
```swift
// In touchesEnded (when firing)
HapticManager.shared.impact(.light)

// In didBegin (when asteroid destroyed)
if contact.bodyA.categoryBitMask == PhysicsCategory.Bullet
   || contact.bodyB.categoryBitMask == PhysicsCategory.Bullet {
    // Asteroid hit by bullet
    HapticManager.shared.impact(.light)
}

// In didBegin (when ship hit)
if (contact.bodyA.categoryBitMask == PhysicsCategory.Ship
    && contact.bodyB.categoryBitMask == PhysicsCategory.Asteroid)
   || (contact.bodyA.categoryBitMask == PhysicsCategory.Asteroid
    && contact.bodyB.categoryBitMask == PhysicsCategory.Ship) {
    // Ship hit
    HapticManager.shared.impact(.heavy)
}

// In collectItem (when collecting power-up)
HapticManager.shared.notification(.success)

// In gameOver()
HapticManager.shared.notification(.error)
```

---

## Phase 4: Portrait Mode Support (Optional)

### Step 4.1: Update Info.plist for Portrait Orientation
**File:** `Asteroid.swiftpm/Package.swift` or app configuration

**Current Issue:** App is landscape-only.

**Implementation:**
1. Add portrait orientations to supported interface orientations
2. Keep landscape as preferred default

---

### Step 4.2: Create Adaptive Layout System
**New File:** `Asteroid.swiftpm/Helper/OrientationManager.swift`

**Implementation:**
1. Detect current orientation
2. Provide layout presets for portrait vs landscape
3. Reposition HUD elements when orientation changes

**Code Changes:**
```swift
import UIKit

enum DeviceOrientation {
    case portrait
    case landscape
}

class OrientationManager {
    static func currentOrientation(for size: CGSize) -> DeviceOrientation {
        return size.width > size.height ? .landscape : .portrait
    }

    static func hudLayout(for size: CGSize, safeAreaInsets: UIEdgeInsets) -> HUDLayout {
        let orientation = currentOrientation(for: size)

        switch orientation {
        case .portrait:
            return portraitLayout(size: size, safeAreaInsets: safeAreaInsets)
        case .landscape:
            return landscapeLayout(size: size, safeAreaInsets: safeAreaInsets)
        }
    }

    private static func portraitLayout(size: CGSize, safeAreaInsets: UIEdgeInsets) -> HUDLayout {
        // Portrait: More vertical space, less horizontal
        // Move controls to bottom, HUD to top
        return HUDLayout(screenSize: size, safeAreaInsets: safeAreaInsets)
    }

    private static func landscapeLayout(size: CGSize, safeAreaInsets: UIEdgeInsets) -> HUDLayout {
        // Landscape: Current layout works well
        return HUDLayout(screenSize: size, safeAreaInsets: safeAreaInsets)
    }
}
```

---

### Step 4.3: Update GameScene to Handle Orientation Changes
**File:** `Asteroid.swiftpm/Scene/GameScene.swift`

**Implementation:**
1. Override `didChangeSize` to detect orientation changes
2. Recalculate HUD layout when size changes
3. Reposition all HUD elements

**Code Changes:**
```swift
override func didChangeSize(_ oldSize: CGSize) {
    super.didChangeSize(oldSize)

    guard let view = view else { return }

    // Recalculate layout
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

    hudLayout = OrientationManager.hudLayout(for: size, safeAreaInsets: safeInsets)

    // Update HUD positions
    scoreLabel.position = hudLayout!.scorePosition
    livesLabel.position = hudLayout!.livesPosition
    asteroidCountLabel.position = hudLayout!.asteroidCountPosition
}
```

---

## Phase 5: Screen Size Optimization

### Step 5.1: Test and Adjust for Different iPhone Sizes
**Testing Target Devices:**
- iPhone SE (3rd gen) - 4.7" - 1334x750
- iPhone 13/14 - 6.1" - 2532x1170
- iPhone 14 Pro Max - 6.7" - 2796x1290
- iPhone 13 mini - 5.4" - 2340x1080

**Implementation:**
1. Test HUD visibility on smallest device (SE)
2. Test touch target sizes (minimum 44x44 points)
3. Adjust font sizes for readability
4. Ensure game objects scale proportionally

---

### Step 5.2: Add Dynamic Font Scaling
**File:** `Asteroid.swiftpm/Scene/GameScene.swift`

**Implementation:**
1. Calculate base font size from screen dimensions
2. Scale all label fonts proportionally

**Code Changes:**
```swift
private func baseFontSize() -> CGFloat {
    let screenWidth = size.width
    // Scale: 60pt at 375pt width (iPhone SE/13 mini), up to 80pt at 430pt (Pro Max)
    return max(60, min(80, screenWidth / 375 * 60))
}

// In setupScoreHud()
scoreLabel.fontSize = baseFontSize()

// Apply to all labels
```

---

### Step 5.3: Add Dynamic Spacing
**File:** `Asteroid.swiftpm/Data/Constants.swift`

**Implementation:**
1. Make spacing between HUD elements proportional to screen size
2. Adjust popup sizes based on screen dimensions

**Code Changes:**
```swift
struct HUDLayout {
    let scorePosition: CGPoint
    let livesPosition: CGPoint
    let asteroidCountPosition: CGPoint
    let safeMargin: CGFloat
    let verticalSpacing: CGFloat // NEW
    let fontSize: CGFloat // NEW

    init(screenSize: CGSize, safeAreaInsets: UIEdgeInsets) {
        // ... existing code ...

        // Dynamic spacing
        self.verticalSpacing = max(30, screenSize.height * 0.04)
        self.fontSize = max(60, min(80, screenSize.width / 375 * 60))

        // Update lives position to use dynamic spacing
        self.livesPosition = CGPoint(
            x: -halfWidth + leadingMargin,
            y: halfHeight - topMargin - verticalSpacing
        )
    }
}
```

---

## Phase 6: Enhanced UI/UX

### Step 6.1: Add Settings Menu Scene
**New File:** `Asteroid.swiftpm/Scene/SettingsScene.swift`

**Implementation:**
1. Create new SKScene for settings
2. Add toggle buttons for haptic feedback
3. Add control scheme selector
4. Add volume sliders
5. Add back button to return to main menu

**Code Changes:**
```swift
import SpriteKit

class SettingsScene: SKScene {
    private var titleLabel: SKLabelNode!
    private var backButton: SKLabelNode!
    private var controlSchemeLabel: SKLabelNode!
    private var hapticToggleLabel: SKLabelNode!

    override func didMove(to view: SKView) {
        backgroundColor = .black
        setupUI()
    }

    private func setupUI() {
        // Title
        titleLabel = SKLabelNode(text: "SETTINGS")
        titleLabel.fontSize = 80
        titleLabel.fontName = "AvenirNext-Bold"
        titleLabel.position = CGPoint(x: size.width/2, y: size.height * 0.8)
        addChild(titleLabel)

        // Control Scheme
        controlSchemeLabel = SKLabelNode(text: "Control: \(GameSettings.shared.controlScheme.rawValue)")
        controlSchemeLabel.fontSize = 40
        controlSchemeLabel.position = CGPoint(x: size.width/2, y: size.height * 0.6)
        controlSchemeLabel.name = "controlScheme"
        addChild(controlSchemeLabel)

        // Haptic Toggle
        let hapticStatus = GameSettings.shared.hapticFeedbackEnabled ? "ON" : "OFF"
        hapticToggleLabel = SKLabelNode(text: "Haptics: \(hapticStatus)")
        hapticToggleLabel.fontSize = 40
        hapticToggleLabel.position = CGPoint(x: size.width/2, y: size.height * 0.5)
        hapticToggleLabel.name = "hapticToggle"
        addChild(hapticToggleLabel)

        // Back Button
        backButton = SKLabelNode(text: "BACK")
        backButton.fontSize = 50
        backButton.position = CGPoint(x: size.width/2, y: size.height * 0.2)
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
            let menuScene = MainMenuScene()
            menuScene.size = size
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
            controlSchemeLabel.text = "Control: \(GameSettings.shared.controlScheme.rawValue)"
        }
    }

    private func toggleHaptic() {
        GameSettings.shared.hapticFeedbackEnabled.toggle()
        HapticManager.shared.selection()
        let status = GameSettings.shared.hapticFeedbackEnabled ? "ON" : "OFF"
        hapticToggleLabel.text = "Haptics: \(status)"
    }
}
```

---

### Step 6.2: Add Settings Button to Main Menu
**File:** `Asteroid.swiftpm/Scene/MainMenuScene.swift`

**Implementation:**
1. Add settings button/icon to main menu
2. Add touch handler to navigate to settings scene

**Code Changes:**
```swift
// In didMove(to view:)
private var settingsButton: SKLabelNode!

private func setupSettingsButton() {
    settingsButton = SKLabelNode(text: "⚙️ SETTINGS")
    settingsButton.fontSize = 40
    settingsButton.position = CGPoint(x: size.width/2, y: size.height * 0.3)
    settingsButton.name = "settings"
    addChild(settingsButton)
}

// Call in didMove
setupSettingsButton()

// In touchesEnded
if tappedNode.name == "settings" {
    HapticManager.shared.selection()
    let transition = SKTransition.fade(withDuration: 0.5)
    let settingsScene = SettingsScene()
    settingsScene.size = size
    view?.presentScene(settingsScene, transition: transition)
}
```

---

### Step 6.3: Add Pause Button During Gameplay
**File:** `Asteroid.swiftpm/Scene/GameScene.swift`

**Implementation:**
1. Add pause button (top-center or corner)
2. Pause game physics and actions when tapped
3. Show pause menu overlay with Resume/Quit options

**Code Changes:**
```swift
private var pauseButton: SKLabelNode!
private var isPaused = false
private var pauseOverlay: SKShapeNode?

private func setupPauseButton() {
    pauseButton = SKLabelNode(text: "⏸")
    pauseButton.fontSize = 40
    pauseButton.position = CGPoint(x: 0, y: hudLayout!.scorePosition.y)
    pauseButton.zPosition = 100
    pauseButton.name = "pauseButton"
    addChild(pauseButton)
}

private func showPauseMenu() {
    isPaused = true
    physicsWorld.speed = 0

    // Semi-transparent overlay
    pauseOverlay = SKShapeNode(rectOf: size)
    pauseOverlay!.fillColor = UIColor.black.withAlphaComponent(0.7)
    pauseOverlay!.strokeColor = .clear
    pauseOverlay!.zPosition = 200
    addChild(pauseOverlay!)

    // Resume button
    let resumeLabel = SKLabelNode(text: "RESUME")
    resumeLabel.fontSize = 60
    resumeLabel.position = CGPoint(x: 0, y: 50)
    resumeLabel.name = "resume"
    resumeLabel.zPosition = 201
    pauseOverlay!.addChild(resumeLabel)

    // Quit button
    let quitLabel = SKLabelNode(text: "MAIN MENU")
    quitLabel.fontSize = 60
    quitLabel.position = CGPoint(x: 0, y: -50)
    quitLabel.name = "quit"
    quitLabel.zPosition = 201
    pauseOverlay!.addChild(quitLabel)
}

private func hidePauseMenu() {
    isPaused = false
    physicsWorld.speed = 1
    pauseOverlay?.removeFromParent()
    pauseOverlay = nil
}

// Update touchesEnded to handle pause menu
override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else { return }
    let point = touch.location(in: self)
    let tappedNode = atPoint(point)

    if tappedNode.name == "pauseButton" {
        showPauseMenu()
        HapticManager.shared.selection()
        return
    }

    if isPaused {
        if tappedNode.name == "resume" {
            hidePauseMenu()
            HapticManager.shared.selection()
        } else if tappedNode.name == "quit" {
            HapticManager.shared.selection()
            let transition = SKTransition.fade(withDuration: 0.5)
            let menuScene = MainMenuScene()
            menuScene.size = size
            view?.presentScene(menuScene, transition: transition)
        }
        return
    }

    // ... existing game controls ...
}
```

---

## Phase 7: Performance Optimization

### Step 7.1: Add FPS Counter (Debug Mode)
**File:** `Asteroid.swiftpm/Scene/GameScene.swift`

**Implementation:**
1. Add FPS label in debug builds
2. Show memory usage and node count

**Code Changes:**
```swift
#if DEBUG
private var fpsLabel: SKLabelNode!

private func setupDebugHUD() {
    fpsLabel = SKLabelNode(text: "FPS: 60")
    fpsLabel.fontSize = 20
    fpsLabel.position = CGPoint(x: 0, y: -size.height/2 + 30)
    fpsLabel.zPosition = 1000
    addChild(fpsLabel)
}

override func update(_ currentTime: TimeInterval) {
    super.update(currentTime)

    #if DEBUG
    if let view = view {
        fpsLabel.text = "FPS: \(Int(1.0 / (currentTime - lastUpdateTime)))"
    }
    #endif

    // ... existing update logic ...
}
#endif
```

---

### Step 7.2: Optimize Particle Systems
**File:** `Asteroid.swiftpm/Helper/Animation.swift`

**Implementation:**
1. Limit maximum particles per explosion
2. Use object pooling for frequently created particles
3. Remove particles sooner on slower devices

**Code Changes:**
```swift
// In explosionAnimation function
func explosionAnimation(pos: CGPoint, size: CGFloat, scene: SKScene) {
    // Limit particles on smaller devices
    let particleCount = UIDevice.current.userInterfaceIdiom == .phone ? 20 : 30

    for _ in 0..<particleCount {
        let particle = SKShapeNode(circleOfRadius: size * 0.1)
        // ... existing particle setup ...

        // Shorter lifetime
        let lifetime = SKAction.sequence([
            SKAction.wait(forDuration: 0.5), // Reduced from potentially longer
            SKAction.removeFromParent()
        ])
        particle.run(lifetime)
    }
}
```

---

### Step 7.3: Implement Object Pooling for Bullets
**New File:** `Asteroid.swiftpm/Helper/ObjectPool.swift`

**Implementation:**
1. Create generic object pool class
2. Reuse bullet nodes instead of creating/destroying
3. Reset and return to pool when off-screen

**Code Changes:**
```swift
import SpriteKit

class ObjectPool<T: SKNode> {
    private var pool: [T] = []
    private let createObject: () -> T
    private let resetObject: (T) -> Void

    init(initialCapacity: Int = 20,
         createObject: @escaping () -> T,
         resetObject: @escaping (T) -> Void) {
        self.createObject = createObject
        self.resetObject = resetObject

        // Pre-populate pool
        for _ in 0..<initialCapacity {
            pool.append(createObject())
        }
    }

    func get() -> T {
        if pool.isEmpty {
            return createObject()
        }
        return pool.removeLast()
    }

    func returnToPool(_ object: T) {
        resetObject(object)
        pool.append(object)
    }
}

// Usage in GameScene:
private lazy var bulletPool = ObjectPool<BulletNode>(
    createObject: { BulletNode() },
    resetObject: { bullet in
        bullet.removeFromParent()
        bullet.removeAllActions()
        bullet.physicsBody?.velocity = .zero
    }
)
```

---

## Phase 8: Accessibility

### Step 8.1: Add VoiceOver Support
**File:** `Asteroid.swiftpm/Scene/GameScene.swift`

**Implementation:**
1. Add accessibility labels to UI elements
2. Announce score changes
3. Announce wave start/game over

**Code Changes:**
```swift
// In setupScoreHud()
scoreLabel.isAccessibilityElement = true
scoreLabel.accessibilityLabel = "Score: \(score)"

// When score updates
func updateScore(by points: Int) {
    score += points
    scoreLabel.text = "SCORE: \(score)"
    scoreLabel.accessibilityLabel = "Score: \(score)"

    // Announce significant milestones
    if score % 1000 == 0 {
        UIAccessibility.post(notification: .announcement, argument: "Score \(score)")
    }
}
```

---

### Step 8.2: Add Larger Touch Targets Option
**File:** `Asteroid.swiftpm/Data/GameSettings.swift`

**Implementation:**
1. Add "Large Touch Targets" setting
2. Increase button/control sizes when enabled
3. Minimum 44x44 points (Apple HIG)

---

### Step 8.3: Add High Contrast Mode
**File:** `Asteroid.swiftpm/Data/GameSettings.swift` + `Constants.swift`

**Implementation:**
1. Add high contrast color scheme option
2. Use brighter colors with better contrast ratios
3. Add thicker outlines to game objects

**Code Changes:**
```swift
// In GameSettings
@Published var highContrastMode: Bool {
    didSet {
        UserDefaults.standard.set(highContrastMode, forKey: "highContrast")
    }
}

// In Constants.swift
struct ColorScheme {
    let ship: UIColor
    let asteroid: UIColor
    let bullet: UIColor
    let background: UIColor

    static var standard: ColorScheme {
        ColorScheme(
            ship: .white,
            asteroid: .white,
            bullet: .white,
            background: .black
        )
    }

    static var highContrast: ColorScheme {
        ColorScheme(
            ship: .yellow,
            asteroid: UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0),
            bullet: .cyan,
            background: .black
        )
    }
}
```

---

## Phase 9: Testing & Refinement

### Step 9.1: Create Test Checklist
**New File:** `Asteroid.swiftpm/MOBILE_TEST_CHECKLIST.md`

**Content:**
```markdown
# Mobile Testing Checklist

## Device Testing
- [ ] iPhone SE (smallest screen)
- [ ] iPhone 13/14 (standard size)
- [ ] iPhone 14 Pro/Pro Max (largest screen)
- [ ] iPad (if supporting tablets)

## Orientation Testing
- [ ] Landscape left
- [ ] Landscape right
- [ ] Portrait (if supported)
- [ ] Rotation during gameplay

## Safe Area Testing
- [ ] iPhone with notch (12+)
- [ ] iPhone without notch (SE)
- [ ] Dynamic Island (14 Pro+)
- [ ] Home indicator visibility

## Control Testing
- [ ] Touch-to-point control accuracy
- [ ] Virtual joystick (if implemented)
- [ ] Touch indicator visibility
- [ ] Multi-touch rejection (ensure single touch only)
- [ ] Rapid tap handling

## Haptic Testing
- [ ] Shooting feels responsive
- [ ] Asteroid destruction feedback
- [ ] Ship collision impact
- [ ] Power-up collection
- [ ] Settings toggle
- [ ] Disable option works

## UI/UX Testing
- [ ] All text readable on smallest device
- [ ] Buttons have 44x44pt minimum touch target
- [ ] HUD doesn't overlap with safe areas
- [ ] Pause menu accessible and functional
- [ ] Settings save and persist
- [ ] High contrast mode works

## Performance Testing
- [ ] Maintains 60 FPS during heavy gameplay
- [ ] No memory leaks (play for 10+ minutes)
- [ ] Particle effects don't cause lag
- [ ] App doesn't overheat device

## Accessibility Testing
- [ ] VoiceOver announces UI elements
- [ ] Score milestones announced
- [ ] High contrast mode improves visibility
- [ ] Larger touch targets option works
```

---

### Step 9.2: Add Analytics/Telemetry (Optional)
**New File:** `Asteroid.swiftpm/Helper/Analytics.swift`

**Implementation:**
1. Track session duration
2. Track high scores
3. Track control scheme usage
4. Track crashes/errors

---

### Step 9.3: Beta Testing Feedback Integration
**Process:**
1. Distribute via TestFlight
2. Collect feedback on controls, visibility, performance
3. Iterate on pain points
4. A/B test control schemes

---

## Implementation Order Summary

### Must-Have (MVP):
1. **Phase 1:** Safe Area & Responsive Layout ✅ Critical
2. **Phase 2.1:** Touch Indicator ✅ High priority
3. **Phase 3:** Haptic Feedback ✅ High priority
4. **Phase 5:** Screen Size Optimization ✅ Critical
6. **Phase 6.3:** Pause Button ✅ High priority

### Should-Have (Enhanced Experience):
5. **Phase 2.2-2.3:** Alternative Controls (Joystick) 🔶 Medium priority
7. **Phase 6.1-6.2:** Settings Menu 🔶 Medium priority
8. **Phase 7:** Performance Optimization 🔶 Medium priority

### Nice-to-Have (Polish):
9. **Phase 4:** Portrait Mode Support 🔵 Low priority
10. **Phase 8:** Accessibility Features 🔵 Low priority

---

## Estimated Implementation Time

| Phase | Estimated Time | Complexity |
|-------|----------------|------------|
| Phase 1 | 2-3 hours | Medium |
| Phase 2.1 | 30 minutes | Low |
| Phase 2.2-2.3 | 2-3 hours | High |
| Phase 3 | 1-2 hours | Medium |
| Phase 4 | 3-4 hours | High |
| Phase 5 | 2-3 hours | Medium |
| Phase 6 | 3-4 hours | Medium |
| Phase 7 | 2-3 hours | Medium |
| Phase 8 | 3-4 hours | Medium |
| Phase 9 | Ongoing | Variable |

**Total Estimated Time (MVP):** 8-12 hours
**Total Estimated Time (Full):** 20-30 hours

---

## Success Metrics

After implementation, the mobile experience should achieve:

✅ HUD elements visible on all iPhone sizes
✅ No UI overlap with notches/home indicators
✅ Responsive controls with visual/haptic feedback
✅ Consistent 60 FPS on iPhone 12+
✅ Settings persist between sessions
✅ Accessible to users with accessibility needs
✅ 4.5+ star rating from beta testers

---

## Notes for AI Implementation

- Each phase is independent and can be implemented separately
- Test after each phase before moving to next
- Commit changes after each major step
- Use descriptive commit messages (e.g., "Add safe area support to HUD layout")
- Run app on simulator after each phase to verify
- If a step fails, document the error and attempt fixes before proceeding
- Prioritize phases marked as "Critical" and "High priority"
- All file paths are relative to `/home/user/Asteroids-Plus/Asteroid.swiftpm/`

---

**END OF IMPLEMENTATION PLAN**
