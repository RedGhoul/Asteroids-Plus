//
//  VirtualJoystick.swift
//  Asteroid
//
//  Created for mobile adaptation
//

import SpriteKit

class VirtualJoystick: SKNode {
    private let baseRadius: CGFloat = 60
    private let thumbRadius: CGFloat = 30
    private let maxDistance: CGFloat = 50

    private var baseNode: SKShapeNode!
    private var thumbNode: SKShapeNode!
    private var isTracking = false

    var direction: CGVector = .zero
    var angle: CGFloat = 0

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
            angle = atan2(delta.y, delta.x)
            thumbNode.position = CGPoint(
                x: cos(angle) * maxDistance,
                y: sin(angle) * maxDistance
            )
            direction = CGVector(dx: cos(angle), dy: sin(angle))
        }

        // Update angle for ship orientation
        if distance > 0 {
            angle = atan2(delta.y, delta.x)
        }
    }

    func touchEnded() {
        isHidden = true
        isTracking = false
        thumbNode.position = .zero
        direction = .zero
    }

    func isTouching() -> Bool {
        return isTracking
    }
}
