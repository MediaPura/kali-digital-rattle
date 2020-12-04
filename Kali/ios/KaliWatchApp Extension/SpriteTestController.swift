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

    private var kaliScene: KaliScene?
    private var crownRotationEventCount: Int = 0

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

        self.kaliScene = kaliScene
        spriteKitScene.presentScene(kaliScene, transition: .crossFade(withDuration: 0.1))

        crownSequencer.delegate = self
        crownSequencer.focus()
    }


}

extension SpriteTestInterfaceController: WKCrownDelegate
{
    func crownDidRotate(_ crownSequencer: WKCrownSequencer?, rotationalDelta: Double)
    {
        guard 
            let kaliScene = kaliScene,
            let kaliNode = kaliScene.kaliNode else
        {
            return
        }

        crownRotationEventCount += 1

        if crownRotationEventCount == 30
        {
            crownRotationEventCount = 0
            kaliNode.zRotation = kaliNode.zRotation + 3.14159
        }
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

