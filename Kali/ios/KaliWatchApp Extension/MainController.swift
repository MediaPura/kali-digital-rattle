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

class MainController: WKInterfaceController
{
    @IBOutlet private weak var spriteKitScene: WKInterfaceSKScene?

    enum SceneState
    {
        case loadingIntro
        case intro
        case playingIntro

        // TODO: (Ted)  Sandwich Let's learn a letter here.
        case letter(letter: String)
        case letterObject(letter: String)
        case goodJob
    }

    private var sceneState: SceneState = .loadingIntro

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
            soundPlayer!.volume = 0.5
            soundPlayer!.delegate = self
            soundPlayer!.play() 
            soundIsPlaying = true
        } catch
        {
            assertionFailure("It should always be possible to create a sound player")
        }
    }

    // TODO: (Ted)  Rename this later.
    let textureAtlas = SKTextureAtlas(named: "Kali")

    var letterIndex = 0
    let supportedLetters = ["A", "B", "C"]
    private var letterAtlases: [String: SKTextureAtlas] = [String: SKTextureAtlas]()
    private var letterObjectAtlases: [String: SKTextureAtlas] = [String: SKTextureAtlas]()

    private var introFrames: [SKTexture] = []

    override func awake(withContext context: Any?)
    {
        super.awake(withContext: context)

        switch sceneState {
        case .loadingIntro:

            for letter in supportedLetters
            {
                letterAtlases[letter] = SKTextureAtlas(named: "Letter\(letter)")
                letterObjectAtlases[letter] = SKTextureAtlas(named: "Letter\(letter)Object")
            }

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

                introFrames.append(textureAtlas.textureNamed(textureName))
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
                weakSelf.sceneState = .intro

                guard let kaliNode = kaliScene.childNode(withName: "Kali") as? SKSpriteNode else
                {
                    assertionFailure("The Kali Scene Must have a Kali Node hooked up in IB")
                    return
                }

                kaliNode.alpha = 1.0
                kaliScene.kaliNode = kaliNode 
                weakSelf.kaliScene = kaliScene
            })

        default: break

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

    private func playCurrentLetter()
    {
        let currentLetter = supportedLetters[letterIndex]
        sceneState = .letter(letter: currentLetter)

        guard let kaliScene = kaliScene else
        {
            assertionFailure("Expected Kali Scene and Kali Node to be hooked up")
            return
        }

        var frames: [SKTexture] = []

        guard let textureAtlas = letterAtlases[currentLetter] else
        {
            assertionFailure("All letter Texture Atlases must be populated by now")
            return
        }

        frames.append(textureAtlas.textureNamed("0"))
        kaliScene.animateKali(frames: frames)
        playSound(soundName: "Letter\(currentLetter)")
    }

    @IBAction func didTapWatchFace()
    {
        switch sceneState {
        case .intro:
            sceneState = .playingIntro

            guard let kaliScene = kaliScene else
            {
                assertionFailure("Expected to load Kali Scene")
                return
            }

            playSound(soundName: "Kali_Intro_05")
            kaliScene.animateKali(frames: introFrames)

        case .playingIntro:
            playCurrentLetter()

        case .letter(let letter):
            sceneState = .letterObject(letter: letter)

            guard let kaliScene = kaliScene else
            {
                assertionFailure("Expected Kali Scene and Kali Node to be hooked up")
                return
            }

            var frames: [SKTexture] = []

            guard let textureAtlas = letterObjectAtlases[letter] else
            {
                assertionFailure("All letter Object Texture Atlases must be populated by now")
                return
            }

            frames.append(textureAtlas.textureNamed("0"))
            kaliScene.animateKali(frames: frames)
            playSound(soundName: "Letter\(letter)Object")

        case .letterObject:
            sceneState = .goodJob
            playSound(soundName: "GoodJob")

        default: break
        }

    }
}

extension MainController: AVAudioPlayerDelegate
{

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool)
    {
        // NOTE: (Ted)  Don't continue unless it has played successfully.
        guard flag else { return }

        switch sceneState {

        case .goodJob:

            letterIndex += 1

            if letterIndex == 3
            {
                letterIndex = 0
            }
          
            playCurrentLetter()

        default: break
        }
    }
}

extension MainController: WKCrownDelegate
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

    func animateKali(frames: [SKTexture])
    {
        guard let kaliNode = kaliNode else
        {
            assertionFailure("Unable to find Kali Node in SpriteKit Scene")
            return
        }

        let animateAction = SKAction.animate(with: frames,
                                     timePerFrame: 1/30,
                                           resize: false,
                                          restore: false)

        kaliNode.run(animateAction)
    }
}

