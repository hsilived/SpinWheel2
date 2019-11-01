//
//  GameScene.swift
//  SpinWheel
//
//  Created by Ron Myschuk on 2018-04-07.
//  Copyright © 2018 Orange Think Box. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    private var spinWheelOpen = false
    private var spinWheel: SpinWheel!
    private var wonLabel: SKLabelNode!
    
    override func didMove(to view: SKView) {
        
       setup()
    }
    
    func setup() {
        
        self.physicsWorld.contactDelegate = self
        
        if let wonLabel = self.childNode(withName: "wonLabel") as? SKLabelNode {
            self.wonLabel = wonLabel
            wonLabel.isHidden = true
        }
        
        if let spinButton1 = self.childNode(withName: "//spinButton") as? PushButton {
            spinButton1.quickSetUpWith(action: { self.displaySpinWheel1() })
            spinButton1.buttonImage = "spin_icon"
        }
        
        if let spinButton2 = self.childNode(withName: "//spinButton2") as? PushButton {
            spinButton2.quickSetUpWith(action: { self.displaySpinWheel2() })
            spinButton2.buttonImage = "spin_icon"
        }
        
        if let spinButton3 = self.childNode(withName: "//spinButton3") as? PushButton {
            spinButton3.quickSetUpWith(action: { self.displaySpinWheel3() })
            spinButton3.buttonImage = "spin_icon"
        }
        
        if let spinButton4 = self.childNode(withName: "//spinButton4") as? PushButton {
            spinButton4.quickSetUpWith(action: { self.displaySpinWheel4() })
            spinButton4.buttonImage = "spin_icon"
        }
    }
    
    func displaySpinWheel1() {
        
        Prizes.loadPrizes(file: "Prizes")
        
        if let spinWheel = SKReferenceNode(fileNamed: "SpinWheel")!.getBaseChildNode() as? SpinWheel {
            
            spinWheel.removeFromParent()
            self.spinWheel = spinWheel
            spinWheel.zPosition = 100
            spinWheel.spinWheelDelegate = self
            addChild(spinWheel)
            
            spinWheel.initPhysicsJoints()
            
            spinWheelOpen = true
        }
    }
    
    func displaySpinWheel2() {
        
        Prizes.loadPrizes(file: "Prizes2")
        
        if let spinWheel = SKReferenceNode(fileNamed: "SpinWheel2")!.getBaseChildNode() as? SpinWheel {
            
            spinWheel.removeFromParent()
            self.spinWheel = spinWheel
            spinWheel.zPosition = 100
            spinWheel.hubSpinsWheel = false
            spinWheel.spinWheelDelegate = self
            addChild(spinWheel)
            
            spinWheel.initPhysicsJoints()
            
            spinWheelOpen = true
        }
    }
    
    func displaySpinWheel3() {
        
        Prizes.loadPrizes(file: "Prizes3")
        
        if let spinWheel = SKReferenceNode(fileNamed: "SpinWheel3")!.getBaseChildNode() as? SpinWheel {
            
            spinWheel.removeFromParent()
            self.spinWheel = spinWheel
            spinWheel.spinDirection = .counterClockwise
            spinWheel.zPosition = 100
            spinWheel.hubSpinsWheel = false
            spinWheel.spinWheelDelegate = self
            addChild(spinWheel)
            
            spinWheel.initPhysicsJoints()
            
            spinWheelOpen = true
        }
    }
    
    func displaySpinWheel4() {
        
        Prizes.loadPrizes(file: "Prizes4")
        
        if let spinWheel = SKReferenceNode(fileNamed: "SpinWheel4")!.getBaseChildNode() as? SpinWheel {
            
            spinWheel.removeFromParent()
            self.spinWheel = spinWheel
            spinWheel.zPosition = 100
            spinWheel.hubSpinsWheel = false
            spinWheel.spinWheelDelegate = self
            addChild(spinWheel)
            
            spinWheel.initPhysicsJoints()
            
            spinWheelOpen = true
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        if spinWheelOpen {
            spinWheel.didBegin(contact)
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        if spinWheelOpen {
            spinWheel.updateWheel(currentTime)
        }
    }
}

extension GameScene: SpinWheelDelegate {
    
    func won(text: String, amount: Int) {
        
        var wonText = "you won \(text)"
        if amount > 0 {
            wonText += " with a value of \(amount)"
        }
        
        wonLabel.text = wonText
        wonLabel.isHidden = false
    }
}
