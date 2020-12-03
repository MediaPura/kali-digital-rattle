//
//  SpriteTestController.swift
//  KaliWatchApp Extension
//
//  Created by Theodore Bendixson on 12/3/20.
//

import Foundation
import WatchKit
import SpriteKit

class SpriteTestInterfaceController: WKInterfaceController
{
    @IBOutlet private weak var spriteKitScene: WKInterfaceSKScene?

    override func awake(withContext context: Any?)
    {
        super.awake(withContext: context)

        guard 
            let spriteKitScene = spriteKitScene,
            let kaliScene = SKScene(fileNamed: "Kali.sks") else
        {
            assertionFailure("Expected to load Kali Scene")
            return
        }

        spriteKitScene.presentScene(kaliScene, transition: .crossFade(withDuration: 0.1))
    }
}

