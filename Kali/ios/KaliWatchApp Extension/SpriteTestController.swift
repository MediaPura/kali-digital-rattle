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

    // NOTE: (Ted)  Switch the presentation mode whenever the scene is tapped.
    @IBAction func tappedScene(gestureRecognizer: WKGestureRecognizer)
    {
        guard 
            let kaliScene = kaliScene,
            let kaliNode = kaliScene.kaliNode else
        {
            assertionFailure("Kali Scene and Kali Node should be hooked up")
            return
        }

        switch kaliScene.presentationMode {
            case .pixelArt:
                kaliScene.presentationMode = .fullResolution
                let texture = SKTexture(imageNamed: "KaliHighRes")
                texture.filteringMode = .linear
                kaliNode.texture = texture
            case .fullResolution:
                kaliScene.presentationMode = .pixelArt
                let texture = SKTexture(imageNamed: "KaliF")
                texture.filteringMode = .nearest
                kaliNode.texture = texture
        }

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
    
    enum PresentationMode
    {
        case pixelArt
        case fullResolution
    }

    var presentationMode: PresentationMode = .pixelArt

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

