//
//  SpriteTestController.swift
//  KaliWatchApp Extension
//
//  Created by Theodore Bendixson on 12/3/20.
//

import Foundation
import WatchKit
import SpriteKit
import AVFoundation

// TODO: (Ted)  Rename this. It has become more official.
class SpriteTestInterfaceController: WKInterfaceController
{
    @IBOutlet private weak var spriteKitScene: WKInterfaceSKScene?

    private var kaliScene: KaliScene?
    private var crownRotationEventCount: Int = 0

    private var soundPlayer: AVAudioPlayer?
    private var soundIsPlaying: Bool = false

    private func playSound(soundName: String)
    {
        guard let soundURL = Bundle.main.url(forResource: soundName,
                                             withExtension: "m4a") else
        {
            assertionFailure("All sounds must exist before being loaded")
            return
        }

        do {
            soundPlayer = try AVAudioPlayer(contentsOf: soundURL)
            soundPlayer!.volume = 0.75
            soundPlayer!.play() 
            soundIsPlaying = true
        } catch
        {
            assertionFailure("It should always be possible to create a sound player")
        }
    }

    var loadedFrames = false
    let textureAtlas = SKTextureAtlas(named: "Kali")

    override func awake(withContext context: Any?)
    {
        super.awake(withContext: context)

        if !loadedFrames
        {
            var frames: [SKTexture] = []

            for frameNumber in 242...447
            {
                var textureName = String()

                if (frameNumber < 10)
                {
                    textureName = "Kali_Intro_05_0000\(frameNumber)"
                } else if (frameNumber < 100)
                {
                    textureName = "Kali_Intro_05_000\(frameNumber)"
                } else
                {
                    textureName = "Kali_Intro_05_00\(frameNumber)"
                }

                frames.append(textureAtlas.textureNamed(textureName))
            }

            guard 
                let spriteKitScene = spriteKitScene,
                let kaliScene = KaliScene(fileNamed: "Kali.sks") else
            {
                assertionFailure("Expected to load Kali Scene")
                return
            }
        
            spriteKitScene.preferredFramesPerSecond = 30
            spriteKitScene.presentScene(kaliScene)

            textureAtlas.preload(completionHandler: { [weak self] in
                guard let weakSelf = self else { return }
                weakSelf.loadedFrames = true
                kaliScene.frames = frames
                weakSelf.kaliScene = kaliScene
                weakSelf.playSound(soundName: "Kali_Intro_05")
                kaliScene.animateKali()
            })
        }

        crownSequencer.delegate = self
        crownSequencer.focus()
    }

    override func didDeactivate()
    {
        super.didDeactivate()

        if let soundPlayer = soundPlayer 
        {
            soundPlayer.pause()
            soundIsPlaying = false
        }
    }

    override func willActivate()
    {
        super.willActivate()

        if let soundPlayer = soundPlayer,
           !soundIsPlaying
        {
            soundPlayer.play() 
        }
    }

    @IBAction func didTapWatchFace()
    {
        playSound(soundName: "Kali_Intro_05")
        kaliScene!.animateKali()
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
    var frames: [SKTexture] = []

    func animateKali()
    {
        kaliNode = childNode(withName: "Kali") as? SKSpriteNode

        guard let kaliNode = kaliNode else
        {
            assertionFailure("Unable to find Kali Node in SpriteKit Scene")
            return
        }

        let animateAction = SKAction.animate(with: frames,
                                     timePerFrame: 1/30,
                                           resize: false,
                                          restore: true)

        kaliNode.run(animateAction)
    }
}

