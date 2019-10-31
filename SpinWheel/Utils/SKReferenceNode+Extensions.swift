//
//  SKReferenceNode+Extensions.swift
//  Balls
//
//  Created by DeviL on 2017-03-03.
//  Copyright © 2017 Orange Think Box. All rights reserved.
//

import Foundation
import SpriteKit

extension SKReferenceNode {
    
    func getBaseChildNode() -> SKNode? {
        if let child = self.children.first?.children.first { return child }
        else { return nil }
    }
}
