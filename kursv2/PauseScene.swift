//
//  PauseScene.swift
//  kursv2
//
//  Created by Артем on 01/12/2018.
//  Copyright © 2018 Артем. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit
import GameplayKit

class PauseScene: UIViewController {
    
    @IBAction func PressStati(_ sender: Any) {
        isStatistic = true;
        
    }
    @IBAction func continueButtonPressed(_ sender: Any) {
        isStatistic = false;
    }
    @IBAction func Start(_ sender: Any) {
        isStatistic = false
    }
}
