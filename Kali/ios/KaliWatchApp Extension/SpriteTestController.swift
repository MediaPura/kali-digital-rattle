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
            let kaliScene = KaliScene(fileNamed: "Kali.sks") else
        {
            assertionFailure("Expected to load Kali Scene")
            return
        }

        spriteKitScene.presentScene(kaliScene, transition: .crossFade(withDuration: 0.1))
    }
}

class KaliScene: SKScene
{
    var kaliNode: SKSpriteNode?

    override func sceneDidLoad()
    {
        super.sceneDidLoad()

        kaliNode = childNode(withName: "Kali") as? SKSpriteNode

        guard let kaliNode = kaliNode else
        {
            assertionFailure("Unable to find Kali Node in SpriteKit Scene")
            return
        }

        guard let kaliTexture = kaliNode.texture else
        {
            assertionFailure("Unable to get Kali Texture")
            return
        }

        kaliTexture.filteringMode = .nearest
    }
}

