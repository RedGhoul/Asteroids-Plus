# CLAUDE.md - AI Assistant Guide for Asteroids-Plus

## Project Overview

**Asteroids-Plus** is an endless arcade-style game built with Swift and SpriteKit for iOS/iPadOS. It's a Swift Playground application that was accepted for WWDC22 Student Challenge. The game features classic asteroid-shooting mechanics with modern enhancements including waves, power-ups, and mobile-optimized controls.

### Key Information
- **Language**: Swift 5.5+
- **Minimum Target**: iOS 15.2, iPadOS 15.2
- **Framework**: SpriteKit for game logic, SwiftUI for app structure
- **Platform**: Swift Playground (.swiftpm package)
- **Supported Devices**: iPad and iPhone
- **Orientation**: Landscape (left and right)

---

## Repository Structure

```
Asteroids-Plus/
├── Asteroid.swiftpm/              # Main Swift Playground package
│   ├── Base/                      # App foundation
│   │   ├── MyApp.swift           # App entry point (@main)
│   │   └── ContentView.swift     # Root SwiftUI view, SpriteKit integration
│   │
│   ├── Scene/                     # SpriteKit scenes
│   │   ├── GameScene.swift       # Main gameplay scene
│   │   ├── MainMenuScene.swift   # Menu/start screen
│   │   └── GameScenePopup.swift  # In-game popups (wave start, game over)
│   │
│   ├── Data/                      # Models and constants
│   │   ├── Constants.swift       # Game constants, physics categories, HUD layout
│   │   ├── AsteroidType.swift    # Asteroid shapes, sizes, and scoring
│   │   └── Shapes.swift          # Game object nodes (Ship, Asteroid, Bullet, Items)
│   │
│   ├── Helper/                    # Utilities and extensions
│   │   ├── Extenstions.swift     # CGPoint operators, Int string formatting
│   │   ├── Animation.swift       # Explosion effects
│   │   └── HapticManager.swift   # Haptic feedback (mobile adaptation)
│   │
│   ├── Assets.xcassets/           # Image assets
│   │   ├── AppIcon.appiconset/
│   │   ├── BulletItem.imageset/
│   │   └── LifeItem.imageset/
│   │
│   ├── Sound/                     # Audio files (.wav)
│   │   ├── Fire.wav
│   │   ├── AsteroidHit.wav
│   │   ├── ShipHit.wav
│   │   ├── WaveStart.wav
│   │   ├── LifeUp.wav
│   │   └── BulletUp.wav
│   │
│   └── Package.swift              # Swift Package Manager configuration
│
├── README.md                      # User-facing documentation
├── MOBILE_ADAPTATION_PLAN.md      # Detailed mobile enhancement plan
├── LICENSE
└── .gitignore
```

---

## Architecture & Design Patterns

### App Structure

1. **SwiftUI + SpriteKit Hybrid**
   - `MyApp.swift`: SwiftUI app entry point using `@main`
   - `ContentView.swift`: SwiftUI view containing `SpriteView` wrapper
   - SpriteKit scenes handle all game logic and rendering

2. **Scene-Based Architecture**
   - `MainMenuScene`: Entry point, shows title and "Tap to Start"
   - `GameScene`: Main gameplay, handles physics, collisions, scoring
   - `GameScenePopup`: Overlay popups for wave transitions and game over

3. **Safe Area Aware Layout**
   - Safe area insets passed from SwiftUI `GeometryReader` to scenes via `userData`
   - `HUDLayout` struct calculates responsive positions for different screen sizes
   - Dynamic font sizing and margins based on device dimensions

### Physics System

**Collision Categories** (defined in `Constants.swift`):
```swift
kShipCategory:     0x1 << 0  // Player ship
kAsteroidCategory: 0x1 << 1  // Asteroids and power-up items
kBulletCategory:   0x1 << 2  // Player bullets
```

**Contact Detection**:
- Ship contacts with asteroids (collision damage)
- Bullets contact with asteroids (destruction)
- Ship contacts with power-up items (collection)

### Data Models

**AsteroidType** (Enum):
- `.A`, `.B`, `.C`: Three random shape variations
- Each type has unique `points: [CGPoint]` for vector rendering

**AsteroidSize** (Enum):
- `.Big` (scale 15.0, score 120)
- `.Middle` (scale 10.0, score 110)
- `.Small` (scale 5.0, score 100)

**AsteroidSplitType** (Enum):
- Controls split direction when asteroid is hit
- `.DiagonalDown`, `.Horizontal`, `.DiagonalUp`

### Game Objects (Shapes.swift)

**Node Types**:
1. `ShipNode` - Player ship (triangle shape, vector graphics)
2. `AsteroidNode` - Asteroids (procedural shapes, vector graphics)
3. `getBulletNode()` - Bullet projectiles (circles)
4. `getLifeItemNode()` - Life power-up (SF Symbol sprite)
5. `getBulletItemNode()` - Fire rate power-up (SF Symbol sprite)

All game objects use **vector graphics** (SKShapeNode) except power-ups (SKSpriteNode with SF Symbols).

---

## Coding Conventions

### Naming Conventions

1. **Constants**: Use `k` prefix
   ```swift
   kShipCategory, kBulletName, kHUDMargin, kExplosionDuration
   ```

2. **Node Names**: String constants for scene graph queries
   ```swift
   kShipName = "ship"
   kAsteroidName = "asteroid"
   kScoreLabelName = "scoreLabel"
   ```

3. **Font Names**:
   ```swift
   kRetroFontName = "Courier"  // Game HUD
   kMenuFontName = "Avenir"    // Menu screens
   ```

4. **Classes**: PascalCase with descriptive suffixes
   ```swift
   ShipNode, AsteroidNode, GameScene, HapticManager
   ```

### Code Organization Patterns

1. **Extensions for Related Functionality**
   - `CGPoint` operators in `Extenstions.swift`
   - `Int.lifeString` for HUD formatting
   - `GameScene` animations in `Animation.swift`

2. **Factory Functions**
   - Global functions for creating nodes: `getBulletNode()`, `getLifeItemNode()`
   - Initialization in custom classes: `ShipNode(scale:position:)`

3. **Singletons for Managers**
   ```swift
   HapticManager.shared.impact(.light)
   ```

### Physics Body Setup Pattern

All game objects follow this pattern:
```swift
self.physicsBody = SKPhysicsBody(...)
self.physicsBody!.affectedByGravity = false
self.physicsBody!.categoryBitMask = <category>
self.physicsBody!.contactTestBitMask = <contacts> // Optional
```

### Scene Lifecycle Pattern

Standard SpriteKit scene setup:
```swift
override func didMove(to view: SKView) {
    // 1. Extract safe area insets from userData
    // 2. Create HUDLayout
    // 3. Configure scene (physics, background)
    // 4. Setup game objects
    // 5. Start game loop
}

override func didChangeSize(_ oldSize: CGSize) {
    // Recalculate HUDLayout
    // Update all UI element positions
}
```

---

## Key Systems & Features

### 1. Wave System
- Waves increase in difficulty (more asteroids, faster movement)
- Speed formula: `speedConstant = 1 / (kAsteroidSpeedConstant ^ wave)`
- New wave triggers when all asteroids destroyed
- Wave start popup with sound effect

### 2. Scoring System
- Asteroid destruction: 100-120 points (varies by size)
- Score displayed in top-left HUD
- High score tracking (referenced in README)

### 3. Life System
- Player starts with 3 lives
- Lose 1 life on asteroid collision
- Game over at 0 lives
- Display: Triangle symbols (∆) in HUD

### 4. Power-Up System
- **Life Power-Up**: +1 life (heart SF Symbol)
- **Fire Rate Power-Up**: Reduces `timePerFire` cooldown
- Spawn chances:
  - 100% on wave completion
  - Low random chance on asteroid destruction

### 5. Touch Controls
- **Tap-to-Move**: Ship moves toward touch location
- **Tap-to-Shoot**: Release fires bullet in ship's direction
- **Touch Indicator**: Visual feedback showing touch position (mobile adaptation)
- **Pause Button**: Top-center button to pause/resume (mobile adaptation)

### 6. Haptic Feedback (Mobile Adaptation)
- Light impact: Shooting, asteroid destruction
- Medium impact: Item collection
- Heavy impact: Ship collision
- Notification: Wave start, game over
- Selection: Menu interactions

### 7. Visual Effects
- **Explosions**: 8-directional particle burst on collisions
- **Ship Color**: White = loaded, Black = reloading
- **HUD Elements**: Score, lives, asteroid count, backlog notifications

### 8. Audio System
Sound effects for:
- Fire, AsteroidHit, ShipHit, WaveStart, LifeUp, BulletUp
- Files stored in `Sound/` directory as `.wav`
- Loaded as resources in `Package.swift`

---

## Mobile Adaptation Features

Recent updates have enhanced the game for iPhone compatibility. See `MOBILE_ADAPTATION_PLAN.md` for comprehensive implementation details.

### Implemented Features

1. **Safe Area Support** (`ContentView.swift`)
   - GeometryReader captures safe area insets
   - Insets passed to scenes via `userData`
   - Prevents UI overlap with notches/Dynamic Island

2. **Responsive HUD Layout** (`Constants.swift`)
   - `HUDLayout` struct with dynamic calculations
   - Margins: 5% of screen width (min 20, max 50)
   - Font sizes: Scale from 60pt to 80pt based on screen width
   - Vertical spacing: 4% of screen height (min 30pt)

3. **Orientation Change Handling** (`GameScene.swift`)
   - `didChangeSize()` recalculates layout
   - Updates all HUD element positions
   - Maintains proper spacing across device rotations

4. **Haptic Feedback** (`HapticManager.swift`)
   - Singleton manager for all haptic types
   - Prepared generators for optimal performance
   - Context-appropriate feedback (light for shooting, heavy for collisions)

### Planned Features (See MOBILE_ADAPTATION_PLAN.md)

- Virtual joystick alternative controls
- Settings menu with control scheme selection
- Portrait mode support
- Performance optimizations (object pooling)
- Accessibility enhancements (VoiceOver, high contrast mode)

---

## Development Workflow

### Building & Running

**With iPad Swift Playgrounds:**
1. Open `Asteroid.swiftpm` in Swift Playgrounds app
2. Tap ▶ to run on device

**With Xcode:**
1. Open `Asteroid.swiftpm` in Xcode
2. Select iPad or iPhone simulator/device
3. Run (⌘R)

### Testing

**Devices to Test:**
- iPhone SE (smallest screen: 1334x750)
- iPhone 13/14 (standard: 2532x1170)
- iPhone 14 Pro Max (largest: 2796x1290)
- iPad (original target device)

**Orientations:**
- Landscape Left ✅
- Landscape Right ✅
- Portrait (not currently supported)

### Git Workflow

**Branch Naming Convention:**
- Feature branches: `claude/feature-name-<session-id>`
- Example: `claude/mobile-adaptation-plan-011CV5GVE5mJmiVw1WtjAKaK`

**Commit Message Style:**
- Imperative mood: "Add haptic feedback to asteroid collisions"
- Descriptive: "Implement MVP mobile adaptation features for Asteroids-Plus"
- Reference PRs: "Merge pull request #1 from RedGhoul/claude/..."

---

## Common Development Tasks

### Adding a New Game Object

1. **Create Node Class** (in `Shapes.swift`):
   ```swift
   class NewObjectNode: SKShapeNode {
       init(position: CGPoint) {
           super.init()
           // Define shape, physics body, properties
       }
       required init?(coder: NSCoder) {
           fatalError("init(coder:) not implemented")
       }
   }
   ```

2. **Add Physics Category** (in `Constants.swift`):
   ```swift
   let kNewObjectCategory: UInt32 = 0x1 << 3
   ```

3. **Setup Collision Detection** (in `GameScene.swift`):
   ```swift
   // In configure() or didMove()
   physicsWorld.contactDelegate = self

   // In didBegin(_ contact:)
   // Handle collision logic
   ```

### Adding a New Sound Effect

1. **Add .wav file** to `Sound/` directory
2. **Register in Package.swift**:
   ```swift
   resources: [
       .copy("Sound/NewSound.wav")
   ]
   ```
3. **Play in scene**:
   ```swift
   run(SKAction.playSoundFileNamed("NewSound.wav", waitForCompletion: false))
   ```

### Adding HUD Elements

1. **Define position in HUDLayout** (Constants.swift):
   ```swift
   let newElementPosition: CGPoint
   // Calculate in init()
   ```

2. **Create label in GameScene.swift**:
   ```swift
   let newLabel = SKLabelNode(fontNamed: kRetroFontName)
   newLabel.position = hudLayout!.newElementPosition
   newLabel.fontSize = hudLayout!.fontSize * 0.4
   addChild(newLabel)
   ```

3. **Update in didChangeSize()**:
   ```swift
   newLabel.position = hudLayout!.newElementPosition
   ```

### Modifying Game Constants

All tunable values are in `Constants.swift`:
- **Ship**: Scale, colors, name
- **Asteroid**: Movement duration, speed formula
- **Bullet**: Radius, name
- **HUD**: Margins, fonts, spacing
- **Animation**: Explosion duration, particle spread

Example adjustment:
```swift
// Make game easier: Slow down asteroids
let kDefaultMoveDuration: CFTimeInterval = 20.0  // Was 15.0
```

---

## Important Implementation Notes

### Safe Area Handling

**Always consider safe areas when positioning UI:**
```swift
// ✅ CORRECT: Use HUDLayout system
scoreLabel.position = hudLayout!.scorePosition

// ❌ INCORRECT: Hardcoded positions
scoreLabel.position = CGPoint(x: -size.width/2 + 50, y: size.height/2 - 50)
```

### Memory Management

**SpriteKit nodes must be removed when done:**
```swift
// Remove nodes that leave screen
if bullet.position.x > size.width {
    bullet.removeFromParent()
}
```

**Use actions with removeFromParent:**
```swift
let sequence = SKAction.sequence([
    SKAction.fadeOut(withDuration: 0.5),
    SKAction.removeFromParent()
])
node.run(sequence)
```

### Physics Contact Queue

GameScene uses a contact queue pattern:
```swift
var contactQueue = [SKPhysicsContact]()

func didBegin(_ contact: SKPhysicsContact) {
    contactQueue.append(contact)
}

// Process in update() to avoid mid-simulation mutations
```

### Vector Graphics Best Practices

**All game objects use CGMutablePath:**
```swift
let points = [CGPoint(...), CGPoint(...)]
let path = CGMutablePath()
path.move(to: points[0])
for i in 1..<points.count {
    path.addLine(to: points[i])
}
path.addLine(to: points[0])  // Close path
```

**Scaling points:**
```swift
let scale = CGPoint(x: 3.5, y: 3.5)
let scaledPoints = points.map { $0 * scale }  // Uses custom operator
```

---

## Troubleshooting Common Issues

### Issue: UI Elements Obscured by Notch

**Solution**: Ensure safe area insets are properly passed:
```swift
// In ContentView.swift
scene.userData?["safeAreaTop"] = geometry.safeAreaInsets.top

// In GameScene.swift didMove()
let topInset = userData?["safeAreaTop"] as? CGFloat ?? 0
hudLayout = HUDLayout(screenSize: size, safeAreaInsets: safeInsets)
```

### Issue: Haptics Not Working

**Check**:
1. `HapticManager.swift` is included in project
2. Haptic calls use correct syntax: `HapticManager.shared.impact(.light)`
3. Device supports haptics (not simulator)

### Issue: Sounds Not Playing

**Check**:
1. File exists in `Sound/` directory
2. File registered in `Package.swift` resources
3. Correct filename including extension: `"Fire.wav"` not `"Fire"`

### Issue: Collision Detection Not Working

**Verify**:
1. Both bodies have correct `categoryBitMask`
2. At least one has `contactTestBitMask` set to other's category
3. Scene has `physicsWorld.contactDelegate = self`
4. Scene conforms to `SKPhysicsContactDelegate`

### Issue: Game Crashes on Scene Transition

**Common causes**:
1. Accessing removed nodes
2. Not stopping actions before removing nodes
3. Scene size not set: `scene.size = geometry.size`
4. Missing required userData values

---

## Performance Considerations

### Optimization Strategies

1. **Limit Particle Counts**
   - Explosion animation uses 8 particles (optimized for mobile)
   - Each particle auto-removes after animation

2. **Reuse Nodes** (Future Enhancement)
   - Object pooling for bullets (see MOBILE_ADAPTATION_PLAN.md Phase 7.3)
   - Prevents excessive allocation/deallocation

3. **Efficient Collision Detection**
   - Use contact categories to limit checks
   - `usesPreciseCollisionDetection = true` only for bullets

4. **Action Management**
   - Remove actions before removing nodes: `node.removeAllActions()`
   - Use named actions to replace instead of stack: `run(action, withKey: "move")`

### Target Performance

- **60 FPS** on iPhone 12 and newer
- **Smooth gameplay** on iPhone SE (minimum target)
- **No memory leaks** during extended play (10+ minutes)

---

## Testing Checklist for AI Assistants

When making changes, verify:

- [ ] **Build succeeds** in Xcode
- [ ] **Game launches** without crashes
- [ ] **HUD elements visible** on all device sizes (SE, 13, Pro Max)
- [ ] **No UI overlap** with safe areas (notch, home indicator)
- [ ] **Touch controls responsive** (ship moves, bullets fire)
- [ ] **Collisions work** (asteroids split, ship takes damage)
- [ ] **Sounds play** for game events
- [ ] **Haptics feel appropriate** for actions
- [ ] **Scene transitions smooth** (menu to game, game over)
- [ ] **Performance** maintains 60 FPS during heavy gameplay
- [ ] **Code follows conventions** (k prefix, naming patterns)
- [ ] **No compiler warnings**

---

## External Resources & Credits

**Sound Effects**: Free Arcade Sound Effects from [mixkit.co](https://mixkit.co/free-sound-effects/arcade/)

**Item Sprites**: SF Symbols (Apple's system icon library)

**Coordinate References** (in README.md):
- [Asteroid shapes](https://github.com/ChoiysApple/Asteroids-Plus/blob/1838daa20c68676b00bd9d148dcf7ff7588ab4cd/Asteroid.swiftpm/Data/AsteroidType.swift#L13)
- [Ship shape](https://github.com/ChoiysApple/Asteroids-Plus/blob/1838daa20c68676b00bd9d148dcf7ff7588ab4cd/Asteroid.swiftpm/Data/Shapes.swift#L16)
- [Explosion animation](https://github.com/ChoiysApple/Asteroids-Plus/blob/1838daa20c68676b00bd9d148dcf7ff7588ab4cd/Asteroid.swiftpm/Helper/Animation.swift#L48)

---

## Quick Reference: File Purposes

| File | Purpose | When to Edit |
|------|---------|--------------|
| `MyApp.swift` | App entry point | Rarely (only for app-level config) |
| `ContentView.swift` | SpriteKit integration | Safe area handling, scene setup |
| `GameScene.swift` | Main game logic | Gameplay mechanics, scoring, collisions |
| `MainMenuScene.swift` | Start menu | Menu UI, navigation |
| `GameScenePopup.swift` | Popups | Wave transitions, game over screen |
| `Constants.swift` | All constants | Tuning values, adding categories |
| `AsteroidType.swift` | Asteroid data | New shapes, sizes, scoring |
| `Shapes.swift` | Game objects | New object types |
| `Extenstions.swift` | Utility extensions | New operators, formatters |
| `Animation.swift` | Visual effects | Explosion tweaks, new effects |
| `HapticManager.swift` | Haptic feedback | Haptic patterns |
| `Package.swift` | Build config | Adding resources, changing targets |

---

## AI Assistant Best Practices

### When Analyzing Code
1. **Check Constants.swift first** for configuration values
2. **Understand scene hierarchy**: ContentView → MainMenuScene → GameScene
3. **Trace physics interactions** via category bitmasks
4. **Consider safe areas** for any UI changes

### When Making Changes
1. **Follow existing patterns** (k prefix, extensions, factories)
2. **Test on multiple device sizes** (use simulator size classes)
3. **Preserve vector graphics style** (don't replace with bitmaps)
4. **Maintain 60 FPS performance** (profile with Instruments if needed)
5. **Add haptics for new interactions** (consistency with mobile UX)

### When Adding Features
1. **Check MOBILE_ADAPTATION_PLAN.md** for planned features (avoid duplicates)
2. **Update this CLAUDE.md** with new patterns or conventions
3. **Add to testing checklist** if introducing new systems
4. **Consider iPad AND iPhone** compatibility

### When Debugging
1. **Check safe area insets** for layout issues
2. **Verify physics categories** for collision issues
3. **Confirm resource registration** for missing assets
4. **Use print debugging** in `update()` or `didBegin()` for physics

---

## Changelog

### Recent Updates
- **Nov 2024**: Mobile adaptation features implemented
  - Safe area support
  - Responsive HUD layout system
  - Haptic feedback manager
  - Touch indicator
  - Orientation change handling
- **Initial Release**: WWDC22 Student Challenge submission
  - Core gameplay
  - Wave system
  - Power-ups
  - Vector graphics
  - Sound effects

---

## Contact & Contribution

**Original Author**: Daegeon Choi (@ChoiysApple)

**Repository**: [github.com/ChoiysApple/Asteroids-Plus](https://github.com/ChoiysApple/Asteroids-Plus)

**High Score Sharing**: Submit PR with screenshot (see README.md)

---

**This documentation is maintained for AI assistants (Claude, GPT, etc.) to effectively understand and contribute to the Asteroids-Plus codebase.**

*Last Updated: 2024-11*
