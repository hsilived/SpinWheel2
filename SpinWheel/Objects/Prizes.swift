//
//  Prizes.swift
//  SpinWheel
//
//  Created by DeviL on 2019-10-27.
//  Copyright © 2019 Orange Think Box. All rights reserved.
//

import Foundation

class Prizes {
    
    static var prizes = [[String : AnyObject]]()
    
    class func loadPrizes(file: String) {

        //recall the plist
        if let plist = Plist(name: file) {
            
            let prizesArray = plist.getValuesInPlistFile()!
            prizes = prizesArray["Prizes"] as! [[String : AnyObject]]
        }
        else {
            print("Unable to get Plist")
        }
    }
}
