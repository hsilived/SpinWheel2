//
//  SpinWheel.swift
//  SpinWheel
//
//  Created by Ron Myschuk on 2016-05-27.
//  Copyright © 2016 Orange Think Box. All rights reserved.
//

import Foundation
import SpriteKit

enum WheelState : Int {
    case stopped
    case ready
    case spinning
    case waiting
}

enum SpinDirection: Int {
    case clockwise = -1, counterClockwise = 1
}

protocol SpinWheelDelegate: NSObject {
    
    func won(text: String, amount: Int)
}

class SpinWheel: SKSpriteNode {
    
    weak var spinWheelDelegate: SpinWheelDelegate?
    
    //MARK: - Local variables
    private var wheel: SKSpriteNode!
    private var flapper: SKSpriteNode!
    private var pivotPin: SKSpriteNode!
    private var springPin: SKSpriteNode!
    //    private var center: SKSpriteNode!
    
    private var wheelState: WheelState = .waiting
    private var slots = [[String: AnyObject]]()
    private var pegPoints = [(CGFloat, CGFloat)]()
    private var prizeImages = [SKSpriteNode]()
    private var tickSound: SKAction!
    private var errorSound: SKAction!
    private var wonSound: SKAction!
    private var wooshSound: SKAction!
    private var startPos: CGFloat = 0
    private var backwardsDegree: CGFloat!
    
    private var foundPrizeTextLabel = false
    private var prizeTextColor = SKColor(white: 0.125, alpha: 1.0)
    private var prizeTextSize: CGFloat = 38.0
    private var prizeTextYPosOffset: CGFloat = -110
    private var prizeTextLineBreakMode: NSLineBreakMode = NSLineBreakMode.byTruncatingTail
    private var prizeTextPreferredMaxLayoutWidth: CGFloat = 0
    private var prizeTextVerticalAlignmentMode: SKLabelVerticalAlignmentMode = .center
    private var prizeImagePosY: CGFloat = 0
    private var prizeTextPosY: CGFloat = 0
    private var prizeImageScale: CGFloat = 1.0
    private var exitButton: PushButton!
    private var wheelHub: PushButton!
    private var dialogTitleLabel: SKLabelNode!
    private var spinEmitter: SKEmitterNode!
    private var streaks = [SKEmitterNode]()
    private var wonPrizeTitle = ""
    private var wonPrizeAmount = 0
    private var flapperAngle: CGFloat = 0
    
    var spinDirection: SpinDirection = .clockwise
    var hubSpinsWheel = kHubSpinsWheel {
        
        didSet {
            wheelHub.isEnabled = hubSpinsWheel
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        setup()
    }
    
    func setup() {
        
        isUserInteractionEnabled = true
        isPaused = false
        
        setupSounds()
        
        //gets the prizes that have been loaded and stored from the plist
        slots = Prizes.prizes
        
        createWheel()
        
        loadWheelHub()
        
        loadEmitters()
        
        createFlapper()
        
        setupButtons()
    }
    
    func createWheel() {
        
        if let wheel = self.childNode(withName: "wheel") as? SKSpriteNode {
            
            self.wheel = wheel
            
            //this is the positioning square the shows which indicates where the slot image will go
            loadPrizeImageInformationFromSceneLabel()
            
            //this is the label on the wheel in the editor which dictates what the label for each slot will look like
            loadPrizeTextInformationFromSceneLabel()
            
            //the pegs are the outer pegs of the wheel that interact with the flapper
            let physicsBodies = loadWheelPegs()
            
            //add the peg physics to the wheel
            wheel.physicsBody = SKPhysicsBody(bodies: physicsBodies)
            wheel.physicsBody!.categoryBitMask = pegCategory
            wheel.physicsBody!.collisionBitMask = flapperCategory
            wheel.physicsBody!.contactTestBitMask = flapperCategory
            wheel.physicsBody!.isDynamic = true
            wheel.physicsBody!.affectedByGravity = false
            wheel.physicsBody!.allowsRotation = false
            wheel.physicsBody!.mass = 200
        }
    }
    
    func loadPrizeImageInformationFromSceneLabel() {
        
        //this is the positioning square the shows which indicates where the slot image will go
        if let prizeImage = wheel.childNode(withName: "prizeImage") as? SKSpriteNode {
            
            prizeImagePosY = prizeImage.position.y
            prizeImageScale = prizeImage.xScale
            //we loaded the info from this image now remove it from the scene
            prizeImage.removeFromParent()
        }
    }
    
    func loadPrizeTextInformationFromSceneLabel() {
        
        if let prizeText = wheel.childNode(withName: "prizeText") as? SKLabelNode {
            
            //this finds the labelNode in the scene and pulls characteristics from it. this allows you to change the font characteristics on the fly in the scene editor
            foundPrizeTextLabel = true
            prizeTextColor = prizeText.fontColor!
            prizeTextSize = prizeText.fontSize
            prizeTextPosY = prizeText.position.y
            prizeTextVerticalAlignmentMode = prizeText.verticalAlignmentMode
            prizeTextLineBreakMode = prizeText.lineBreakMode
            prizeTextPreferredMaxLayoutWidth = prizeText.preferredMaxLayoutWidth
            
            //we loaded the info from this label now remove it from the scene
            prizeText.removeFromParent()
        }
    }
    
    func loadWheelPegs() -> [SKPhysicsBody] {
        
        var physicsBodies = [SKPhysicsBody]()
        
        if let pegs = self.childNode(withName: "//pegs") {
            
            var lastPegPos: CGPoint!
            var distanceBetweenPegs: CGFloat = 0
            var distanceToCenter: CGFloat = 0
            var pegAngle: CGFloat!
            var pegIndex = 0
            var firstPegPos: CGPoint!
            var percentageFromCenter: CGFloat = 75
            
            //the pegs are the outer pegs of the wheel that interact with the flapper
            for peg in pegs.children {
                
                if peg is DummyPeg { }
                else {
                    
                    let peg = peg as! SKSpriteNode
                    
                    if lastPegPos != nil {
                        
                        let pegPos = self.convert(self.convert(peg.position, from: wheel), to: self)
                        distanceBetweenPegs = pegPos.distanceTo(point: lastPegPos!)
                        let angle = asin((distanceBetweenPegs / 2) / distanceToCenter).radiansToDegrees() * 2
                        
                        if pegAngle == nil {
                            pegAngle = firstPegPos.x - wheel.position.x < 0 ? -(angle / 2) : 0
                        }
                        
                        //save the peg positions as angles so that we can calculate where the wheel lands
                        pegPoints.append((pegAngle, pegAngle + angle))
                        
                        let imageAngle: CGFloat = pegAngle + angle / 2
                        pegAngle += angle
                        
                        //adjust the position of the prize image if they have adjustment image on the wheel in the editor
                        if prizeImagePosY != 0 {
                            percentageFromCenter = prizeImagePosY / distanceToCenter * 100
                        }
                        
                        //figuring out where to put the prize info
                        //middle of the last peg and this peg
                        let midRing = lastPegPos.midPointTo(point: pegPos)
                        //distance to the center of the wheel from the midRing point
                        let distanceToMid = midRing.distanceTo(point: wheel.position)
                        let adjustedPercent = percentageFromCenter * distanceToCenter / distanceToMid
                        //if the wheel isnt in the center of the page adjust the location of the midRing accordingly
                        let adjustedMidRing = midRing - wheel.position
                        
                        let midPos = CGPoint.zero.betweenPointTo(point: adjustedMidRing, byPercentage: adjustedPercent)
                        
                        loadSlotInfo(slot: pegIndex, position: midPos, rotation: imageAngle, textOffset: prizeImagePosY - prizeTextPosY)
                        
                        //close of the loop of prizes by doing the last peg
                        if peg == pegs.children.last {
                            
                            //save the peg positions as angles so that we can calculate where the wheel lands
                            pegPoints.append((pegAngle, pegAngle + angle))
                            
                            let imageAngle = pegAngle + angle / 2
                            let midRing = pegPos.midPointTo(point: firstPegPos!)
                            let distance = midRing.distanceTo(point: wheel.position)
                            let adjustedPercent = percentageFromCenter * distanceToCenter / distance
                            let adjustedMidRing = midRing - wheel.position
                            let midPos = CGPoint.zero.betweenPointTo(point: adjustedMidRing, byPercentage: adjustedPercent)
                            
                            loadSlotInfo(slot: pegIndex + 1, position: midPos, rotation: imageAngle, textOffset: prizeImagePosY - prizeTextPosY)
                        }
                        
                        pegIndex += 1
                    }
                    else {
                        
                        //figure out where the first peg is so that we can start our angle calculations from it
                        firstPegPos = self.convert(self.convert(peg.position, from: wheel), to: self)
                        //calculate the distance from the pegs to the center of the wheel
                        distanceToCenter = firstPegPos.distanceTo(point: wheel.position)
                    }
                    lastPegPos = self.convert(self.convert(peg.position, from: wheel), to: self)
                }
                
                let peg = peg as? SKSpriteNode
                var pegPos = peg!.position//self.convert(self.convert(peg!.position, from: wheel), to: self)
                
                //if the wheel doesn't have a scale of 1.0 we need to accordingly adjust the postion of the pegs
                if wheel.xScale != 1 {
                    pegPos *= wheel.xScale
                }
                
                let pegPhysics = SKPhysicsBody(circleOfRadius: peg!.size.width / 2, center: pegPos)
                physicsBodies.append(pegPhysics)
                peg!.physicsBody = nil
            }
        }
        
        return physicsBodies
    }
    
    func loadWheelHub() {
        
        //this is the hub in the center of the wheel
        //this hub can also act as a spin button if kHubSpinsWheel is set in Settings.swift or if hubSpinsWheel is set to true in this file
        if let wheelHub = self.childNode(withName: "wheelHub") as? PushButton {
            self.wheelHub = wheelHub
            wheelHub.quickSetUpWith(imageBaseName: "wheelHub", action: { [weak self] in self!.spinWheel() })
        }
    }

    func loadEmitters() {
        
        //the smoke emitter behind the wheel, only active when the weheel spins
        if let spinEmitter = self.childNode(withName: "//spinEmitter") as? SKEmitterNode {
            self.spinEmitter = spinEmitter
            spinEmitter.targetNode = self
            spinEmitter.isHidden = true
            spinEmitter.isPaused = true
        }
        
        //the streak emitters on the wheel face, only active when the weheel spins
        if let streakNodes = self.childNode(withName: "//streakNodes") {
            
            streakNodes.enumerateChildNodes(withName: "streak") { streak, _ in
                
                let streak = streak as! SKEmitterNode
                self.disable(emitter: streak)
                streak.isHidden = true
                self.streaks.append(streak)
            }
        }
    }
    
    func setupButtons() {
        
        if let exitButton = self.childNode(withName: "exitButton") as? PushButton {
            exitButton.setButtonAction(target: self, event: .touchUpInside, function: closeSpinWheel, parent: self)
        }
        
        if let spinButton = self.childNode(withName: "spinButton") as? PushButton {
            spinButton.quickSetUpWith(imageBaseName: "button_blank_up", action: { [weak self] in self!.spinWheel() })
            spinButton.createButtonText(buttonText: "spin")
        }
    }
    
    func setupSounds() {
        
        tickSound = SKAction.playSoundFileNamed("bubble_pop.aac", waitForCompletion: false)
        errorSound = SKAction.playSoundFileNamed("error.aac", waitForCompletion: false)
        wonSound = SKAction.playSoundFileNamed("victory.aac", waitForCompletion: false)
        wooshSound = SKAction.playSoundFileNamed("woosh.aac", waitForCompletion: false)
    }
    
    //MARK: - Create Prize Wheel Objects
    
    func loadSlotInfo(slot: Int, position: CGPoint, rotation: CGFloat, textOffset: CGFloat) {

        let prizeImage = createPrizeImage(name: slots[slot]["image"] as! String)
        prizeImage.position = position
        prizeImage.zRotation = CGFloat.degreesToRadians(-rotation)()
        wheel.addChild(prizeImage)
        
        if foundPrizeTextLabel {
            if let prizeLabel = createPrizeLabel(text: String(slots[slot]["amount"] as! Int), textOffset: textOffset) {
                prizeImage.addChild(prizeLabel)
            }
        }
        //add the prizeImages to an array so that we can highlight it later when they win
        prizeImages.append(prizeImage)
    }
    
    func createPrizeImage(name: String) -> SKSpriteNode {
        
        let texture = SKTexture(imageNamed: name)
        let prizeImage = SKSpriteNode(texture: texture)
        prizeImage.size = texture.size()
        prizeImage.name = "prize"
        prizeImage.setScale(prizeImageScale)
        prizeImage.zPosition = 60
        
        return prizeImage
    }
    
    func createPrizeLabel(text: String, textOffset: CGFloat) -> SKNode? {
        
        guard text != "", text != "0" else { return nil }
        
        let prizeText = SKLabelNode(fontNamed: kGameFont)
        prizeText.text = text
        prizeText.fontSize = prizeTextSize
        prizeText.fontColor = prizeTextColor
        prizeText.lineBreakMode = prizeTextLineBreakMode
        prizeText.verticalAlignmentMode = prizeTextVerticalAlignmentMode
        prizeText.numberOfLines = 13
        prizeText.preferredMaxLayoutWidth = prizeTextPreferredMaxLayoutWidth
        prizeText.position = CGPoint(x: 0, y: -textOffset)
        
        return prizeText
    }
    
    func createFlapper() {
        
        if let flapperNode = self.childNode(withName: "flapperNode") {
            
            flapperAngle = flapperNode.zRotation.radiansToDegrees()
            
            if let pivotPin = flapperNode.childNode(withName: "pivotPin") as? SKSpriteNode {
                self.pivotPin = pivotPin
            }
            
            if let springPin = self.childNode(withName: "//springPin") as? SKSpriteNode {
                self.springPin = springPin
            }
            
            if let flapper = pivotPin.childNode(withName: "flapper") as? SKSpriteNode {
                self.flapper = flapper
                
                //at the time of writing this iOS13 DOESNT properly create physics bodies from textures
                //it worked properly prior in ios11 and ios12 and may work again in ios13 if a fix is released (hahahahah)
                //so as a write around we are creating the physics body from a polygon path
                //physics properties are still initially set in the editor
                //if you need to do your won polygon drawing I recommend PaintCode
                let polygonPath = UIBezierPath()
                polygonPath.move(to: CGPoint(x: 51, y: -5))
                polygonPath.addCurve(to: CGPoint(x: 0, y: -101), controlPoint1: CGPoint(x: 51, y: -49), controlPoint2: CGPoint(x: 0, y: -101))
                polygonPath.addCurve(to: CGPoint(x: -51, y: -5), controlPoint1: CGPoint(x: 0, y: -101), controlPoint2: CGPoint(x: -51, y: -49))
                polygonPath.addCurve(to: CGPoint(x: 0, y: 50), controlPoint1: CGPoint(x: -51, y: 39), controlPoint2: CGPoint(x: -25, y: 50))
                polygonPath.addCurve(to: CGPoint(x: 51, y: -5), controlPoint1: CGPoint(x: 25, y: 50), controlPoint2: CGPoint(x: 51, y: 39))
                polygonPath.close()
                
                flapper.physicsBody = SKPhysicsBody(polygonFrom: polygonPath.cgPath)
                flapper.physicsBody!.usesPreciseCollisionDetection = true
                //you have to repin this after changing the physics body
                flapper.physicsBody!.pinned = true
            }
        }
    }
    
    func initPhysicsJoints() {
        
        self.wheel.physicsBody!.pinned = true

        let springJoint = SKPhysicsJointSpring.joint(withBodyA: springPin.physicsBody!, bodyB: flapper.physicsBody!, anchorA: springPin.position, anchorB: flapper.position)
        springJoint.frequency = 50
        self.scene?.physicsWorld.add(springJoint)
    }
    
    //MARK: - Game Loop

    func updateWheel(_ currentTime: TimeInterval) {
        
        guard wheelState == .spinning else { return }
        
        let degree = CGFloat.radiansToDegrees(wheel.zRotation)()
        
        if backwardsDegree == nil {
            backwardsDegree = degree
        }
        
        if wheel.physicsBody!.isResting {
            stopWheelOn(degree: degree)
        }
        else {
            
            let av = wheel.physicsBody!.angularVelocity
            
            if spinDirection == .counterClockwise && av < 0 || spinDirection == .clockwise && av > 0 {
                
                wheelState = .stopped
                self.run(.wait(forDuration: 0.25)) {
                    self.wheel.physicsBody!.angularVelocity = 0
                    self.wheel.physicsBody!.allowsRotation = false
                }
                
                self.run(.wait(forDuration: 1.0)) {
                    self.stopWheelOn(degree: CGFloat.radiansToDegrees(self.wheel.zRotation)())
                }
            }
        }
    }
    
    func stopWheelOn(degree: CGFloat) {
        
        print("\nstopped wheel at \(degree)")
        
        wheelState = .stopped
        
        var degree = degree
        wheel.physicsBody!.angularVelocity = 0
        
        disableAllEmitters()
        
        //check if the flapper is up against a peg and rotated, the result should be the tip of the flapper not the center
        print("flapper degrees \(flapper.zRotation.radiansToDegrees())")
        degree += flapper.zRotation.radiansToDegrees() / 2
        print("0 degree changed to \(degree)")
        
        //see if the flapperNode has been rotated to a different part of the wheel so that we know where to find the winning section of the wheel
        print("flapperAngle \(flapperAngle)")
        if flapperAngle != 0 {
            degree -= flapperAngle
            print("1 degree changed to \(degree)")
        }
        
        if degree < pegPoints[0].0 {
            
            degree += 360
            print("2 degree changed to \(degree)")
        }
        
        print("\n\nshoulda checked for a prize on degree \(degree)")
        
        for x in 0..<pegPoints.count {
            
            if degree > pegPoints[x].0 && degree < pegPoints[x].1 {
                print("You landed on \(slots[x]["title"] as! String) degree \(degree)")
                
                won(prizeTitle: String(describing: slots[x]["title"] as! String))
                
                highlightWin(x)
                break
            }
        }
    }
    
    func won(prizeTitle: String) {
        
        if prizeTitle == "a present" {
            //they've won a prize so do something with the it
        }
        else if prizeTitle.hasSuffix("coins")  {
            //they've won coins so do something with the coins
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        guard wheelState == .spinning else { return }
        
        if let firstNode = contact.bodyA.node as? SKSpriteNode, let secondNode = contact.bodyB.node as? SKSpriteNode {
            
            let object1: String = firstNode.name!
            let object2: String = secondNode.name!
            
            if (object1 == "wheel") || (object2 == "wheel") {
                run(tickSound)
            }
        }
    }
    
    //MARK: - Touch functions
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard wheelState != .spinning, kCanSwipeToSpinWheel else { return }
        
        for touch: UITouch in touches {
            
            let touchPoint: String = atPoint(touch.location(in: self)).name ?? ""
            
            if (touchPoint == "wheelHub") {
                spinWheel()
                return
            }
            
            if (touchPoint == "wheel") || (touchPoint == "prize") {
                wheelState = .ready
                startPos = touch.previousLocation(in: self).y
                return
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard wheelState == .ready, kCanSwipeToSpinWheel else { return }
        
        let touch: UITouch = touches.first!
        let positionInScene: CGPoint = touch.location(in: self)
        let impulse: CGFloat = (startPos - positionInScene.y) / 100
        rotate(impulse)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        guard wheelState == .ready, kCanSwipeToSpinWheel else { return }
        
        let touch: UITouch = touches.first!
        let positionInScene: CGPoint = touch.location(in: self)
        //print("start \(startPos)");
        //print("end \(positionInScene.y)");
        let impulse: CGFloat = fabs(startPos - positionInScene.y)
        spin(impulse)
        
        if impulse > 100 {
            wheelState = .spinning
        }
        else {
            run(errorSound)
        }
    }
    
    //MARK: - Wheel Turn functions
    
    func rotate(_ impulse: CGFloat) {
        
        // print("velocity \(impulse)", impulse);
        wheel.zRotation = wheel.zRotation - CGFloat.degreesToRadians(impulse)()
    }
    
    func disableAllEmitters() {
        
        for streak in streaks {
            disable(emitter: streak)
        }
        
        disable(emitter: spinEmitter)
    }
    
    func disable(emitter: SKEmitterNode) {
        
        emitter.isPaused = true
        emitter.isHidden = true
        emitter.alpha = 0
    }
    
    func enableAllEmitters() {
        
        for streak in streaks {
            enable(emitter: streak)
        }
        
        enable(emitter: spinEmitter)
    }
    
    func enable(emitter: SKEmitterNode) {
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.1)
        
        emitter.isPaused = false
        emitter.isHidden = false
        emitter.run(fadeIn)
    }
    
    func spinWheel() {
        
        if wheelState != .spinning {
            
            enableAllEmitters()
            
            var spinPower = CGFloat.random(min: 1200, max: 2800)
            //            spinPower = 1600.9
            
            if wheel.xScale != 1 {
                spinPower *= wheel.xScale
            }
            
            wheel.physicsBody!.allowsRotation = true
            print("spinPower \(spinPower)")
            spin(spinPower)
            wheelState = .spinning
        }
    }
    
    func spin(_ impulse: CGFloat) {
        
        //print("velocity \(impulse)");
        wheel.physicsBody!.applyAngularImpulse((impulse * 30.0) * CGFloat(spinDirection.rawValue))
        wheel.physicsBody!.angularDamping = 1
        let maxAngularVelocity: CGFloat = 100
        wheel.physicsBody!.angularVelocity = min(wheel.physicsBody!.angularVelocity, maxAngularVelocity)
        
        run(wooshSound)
    }
    
    //MARK: - Highlight win functions
    
    func highlightWin(_ index: Int) {
        
        let temp = prizeImages[index]
        
        run(wonSound)
        
        explodeImage(temp, duration: 1.5)
        
        self.run(SKAction.wait(forDuration: 0.5)) {
            self.explodeImage(temp, duration: 0.5)
        }
        
        let emitter = SKEmitterNode(fileNamed: "SparkleBlast")!
        emitter.position = temp.position
        emitter.particlePositionRange = CGVector(dx: temp.size.width * 2, dy: temp.size.height * 2)
        emitter.zPosition = 11
        wheel.addChild(emitter)
        
        self.run(SKAction.wait(forDuration: 2.0)) {
            self.createWinDialog(index)
        }
    }
    
    func explodeImage(_ image: SKSpriteNode, duration: TimeInterval) {
        
        let prizeImage = image.copy() as! SKSpriteNode
        prizeImage.zPosition = 500
        let scale: SKAction = SKAction.scale(to: 4, duration: duration)
        let fade: SKAction = SKAction.fadeAlpha(to: 0.2, duration: duration)
        let group: SKAction = SKAction.group([scale, fade])
        wheel.addChild(prizeImage)
        
        prizeImage.run(group) {
            prizeImage.removeFromParent()
        }
    }
    
    func createWinDialog(_ winnningIndex: Int) {
        
        wonPrizeTitle = slots[winnningIndex]["title"] as! String
        let prizeImage = slots[winnningIndex]["image"] as! String
        wonPrizeAmount = slots[winnningIndex]["amount"] as! Int
        
        let winDialog = WinDialog(size: self.size, title: wonPrizeTitle, image: prizeImage, imageRotation: flapperAngle, wheelTexture: wheel.texture!)
        winDialog.delegate = self
        self.addChild(winDialog)
        
        winDialog.fadeIn()
    }
    
    func closeSpinWheel() {
        
        self.removeFromParent()
    }
}

extension SpinWheel: WinDialogDelegate {
    
    func closeWinDialog() {
        
        let fadeOut = SKAction.fadeOut(withDuration: 1.0)
        self.run(fadeOut) {
            self.removeAllActions()
            self.removeFromParent()
        }
        
        self.spinWheelDelegate?.won(text: wonPrizeTitle, amount: wonPrizeAmount)
    }
}

//Empty class for pegs on the wheel which don't signify the edge of a new pie piece
class DummyPeg: SKSpriteNode {}
