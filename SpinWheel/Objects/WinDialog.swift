//
//  WinDialog.swift
//  SpinWheel
//
//  Created by DeviL on 2019-10-24.
//  Copyright © 2019 Orange Think Box. All rights reserved.
//

import Foundation
import SpriteKit

protocol WinDialogDelegate: NSObject {
    func closeWinDialog()
}

class WinDialog: SKSpriteNode {
    
    weak var delegate: WinDialogDelegate!
    
    private var background: SKSpriteNode!
    private var youWonLabel: SKLabelNode!
    private var prizeLabel: SKLabelNode!
    private var prizeImage: SKSpriteNode!
    private var wheelTexture: SKTexture!
    
    private var claimButton: PushButton!
    
    private var title = ""
    private var image = ""
    private var imageRotation: CGFloat = 0
    
    init(size: CGSize, title: String, image: String, imageRotation: CGFloat = 0, wheelTexture: SKTexture) {
        
        super.init(texture: nil, color: .clear, size: size)
        
        self.size = size
        self.title = title
        self.image = image
        self.imageRotation = imageRotation
        self.wheelTexture = wheelTexture
        
        zPosition = 2000
        //alpha = 0
        
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setup()
    }
    
    func setup() {
        
        if let winDialogReference = SKReferenceNode(fileNamed: "WinDialog") {
            
            background = findSpriteObject(named: "background", in: winDialogReference)
            let wheel = findSpriteObject(named: "wheel", in: winDialogReference)
            wheel.texture = wheelTexture
            
            let _ = findSpriteObject(named: "sunray", in: winDialogReference)

            if let sparkleBlast = winDialogReference.childNode(withName: "//sparkleBlast") as? SKEmitterNode {
                sparkleBlast.isPaused = false
                sparkleBlast.removeFromParent()
                addChild(sparkleBlast)
            }
            
            prizeImage = findSpriteObject(named: "prizeImage", in: winDialogReference)
            prizeImage.texture = SKTexture(imageNamed: image)
            prizeImage.size = prizeImage.texture!.size()
            if imageRotation != 0 {
                prizeImage.zRotation = imageRotation.degreesToRadians()
            }
            prizeImage.setScale(2.0)
            
            youWonLabel = findLabelObject(named: "youWonLabel", in: winDialogReference)

            prizeLabel = findLabelObject(named: "prizeLabel", in: winDialogReference)
            prizeLabel.text = title
            
            if let claimButton = winDialogReference.childNode(withName: "//claimButton") as? PushButton {
                claimButton.isPaused = false
                claimButton.createButtonText(buttonText: "claim")
                claimButton.removeFromParent()
                addChild(claimButton)
                claimButton.quickSetUpWith(imageBaseName: "button_blank_medium_up", action: { [weak self] in self!.close() })
            }
        }
    }
    
    func findSpriteObject(named name: String, in referenceNode: SKReferenceNode) -> SKSpriteNode {

        if let sprite = referenceNode.childNode(withName: "//\(name)") as? SKSpriteNode {
            sprite.isPaused = false
            sprite.removeFromParent()
            addChild(sprite)

            return sprite
        }

        return SKSpriteNode()
    }

    func findLabelObject(named name: String, in referenceNode: SKReferenceNode) -> SKLabelNode {

        if let label = referenceNode.childNode(withName: "//\(name)") as? SKLabelNode {
            label.fontName = kGameFont
            label.isPaused = false
            label.removeFromParent()
            addChild(label)

            return label
        }

        return SKLabelNode()
    }
    
    func fadeIn() {
        
        let fadeIn = SKAction.fadeIn(withDuration: 1.0)
        self.run(fadeIn)
    }
    
    func closeDialog() {
        
        let fadeOut = SKAction.fadeOut(withDuration: 1.0)
        self.run(fadeOut) {
           self.removeAllActions()
           self.removeFromParent()
        }
    }
    
    func close() {
        
        self.closeDialog()
        
        self.delegate?.closeWinDialog()
    }
}
