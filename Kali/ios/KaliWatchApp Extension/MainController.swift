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
        case letsLearnALetterIntro
        case letter(letter: String)
        case awaitingLetterTap(letter: String)
        case letterObject(letter: String)
        case awaitingLetterObjectTap(letter: String)
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

    let kaliIntroAtlas = SKTextureAtlas(named: "Kali")

    let goodJobAtlas = SKTextureAtlas(named: "GoodJob")
    var goodJobAtlasLoaded = false

    let learnLetterIntroAtlas = SKTextureAtlas(named: "LetsLearnALetter")
    var learnLetterAtlasLoaded = false

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

                introFrames.append(kaliIntroAtlas.textureNamed(textureName))
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

            kaliIntroAtlas.preload(completionHandler: { [weak self] in
                guard let weakSelf = self else { return }
                weakSelf.sceneState = .intro

                guard 
                    let kaliNode = kaliScene.childNode(withName: "Kali") as? SKSpriteNode,
                    let backgroundColorNode = kaliScene.childNode(withName: "Background") as? SKSpriteNode
                else
                {
                    assertionFailure("The Kali Scene Must have all nodes hooked up in IB")
                    return
                }

                guard 
                    let introLabelsNode = kaliScene.childNode(withName: "IntroLabels"),
                    let tapToStart = kaliScene.childNode(withName: "TapToStart") else
                {
                    assertionFailure("The Kali Scene Must have intro labels node hooked up in IB")
                    return
                }

                introLabelsNode.alpha = 0
                tapToStart.alpha = 1

                kaliScene.backgroundColorNode = backgroundColorNode
                kaliScene.kaliNode = kaliNode 
                weakSelf.kaliScene = kaliScene
            })

            learnLetterIntroAtlas.preload(completionHandler: { [weak self] in
                self?.learnLetterAtlasLoaded = true
            })

            goodJobAtlas.preload(completionHandler: { [weak self] in
                self?.goodJobAtlasLoaded = true
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


        switch sceneState {
            case .awaitingLetterTap(let letter): 
                sceneState = .letter(letter: letter)

            case .awaitingLetterObjectTap(let letter):
                sceneState = .letterObject(letter: letter)

            default: break
        }
    }

    override func willActivate()
    {
        super.willActivate()

        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false, block: { [weak self] (timer) in
            guard 
                let weakSelf = self,
                !weakSelf.soundIsPlaying else { return }

            switch weakSelf.sceneState {

            case .playingIntro:
                weakSelf.playCurrentLetter()

            case .letsLearnALetterIntro:
                weakSelf.changeLetterAndPlayIt()

            case .letter(let letter):
                weakSelf.playSound(soundName: "Letter\(letter)")

            case .letterObject(let letter):
                weakSelf.playSound(soundName: "Letter\(letter)Object")

            case .goodJob:
                weakSelf.playCurrentLetter()

            default: break
            }

        })
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

        for index in 0...3
        {
            frames.append(textureAtlas.textureNamed("\(index)"))
        }

        kaliScene.animateKali(frames: frames, repeats: true, isLetter: true)
        playSound(soundName: "Letter\(currentLetter)")
    }

    private func playAnimationInSpriteKitScene(frames: [SKTexture], repeats: Bool = false, 
                                               isLetter: Bool)
    {
        guard let kaliScene = kaliScene else
        {
            assertionFailure("Expected Kali Scene and Kali Node to be hooked up")
            return
        }

        kaliScene.animateKali(frames: frames, repeats: repeats, isLetter: isLetter)
    }

    private func playLetsLearnALetter()
    {
        sceneState = .letsLearnALetterIntro

        var frames: [SKTexture] = []

        for frameNumber in 16...140
        {
            var textureName = String()

            if frameNumber < 100
            {
                textureName = "Kali_LetsLearnALetter_04_000\(frameNumber)"
            } else if frameNumber >= 100
            {
                textureName = "Kali_LetsLearnALetter_04_00\(frameNumber)"
            }

            frames.append(learnLetterIntroAtlas.textureNamed(textureName))
        }

        playAnimationInSpriteKitScene(frames: frames, isLetter: false)
        playSound(soundName: "Kali_LetsLearnALetter_04")
    }

    @IBAction func didTapWatchFace()
    {
        switch sceneState {
        
        case .intro:
            sceneState = .playingIntro

            guard 
                let kaliScene = kaliScene,
                let tapToStart = kaliScene.childNode(withName: "TapToStart") else
            {
                assertionFailure("Expected to load Kali Scene")
                return
            }

            tapToStart.alpha = 0
            playSound(soundName: "Kali_Intro_05")
            kaliScene.animateKali(frames: introFrames, isLetter: false)

        case .playingIntro:

            if learnLetterAtlasLoaded
            {
                playLetsLearnALetter()
            } else
            {
                playCurrentLetter()
            }

        case .awaitingLetterTap(let letter):
            sceneState = .letterObject(letter: letter)

            var frames: [SKTexture] = []

            guard let textureAtlas = letterObjectAtlases[letter] else
            {
                assertionFailure("All letter Object Texture Atlases must be populated by now")
                return
            }

            for index in 0...3
            {
                frames.append(textureAtlas.textureNamed("\(index)"))
            }

            playAnimationInSpriteKitScene(frames: frames, repeats: true, isLetter: true)
            playSound(soundName: "Letter\(letter)Object")

        case .awaitingLetterObjectTap:

            // TODO: (Ted)  Consider randomizing this behavior.
            if goodJobAtlasLoaded
            {
                sceneState = .goodJob

                var frames: [SKTexture] = []

                for frameNumber in 0...150
                {
                    var textureName = String()

                    if frameNumber < 10
                    {
                        textureName = "Kali_KeepGoing_04_0000\(frameNumber)"
                    } else if frameNumber < 100
                    {
                        textureName = "Kali_KeepGoing_04_000\(frameNumber)"
                    } else if frameNumber >= 100
                    {
                        textureName = "Kali_KeepGoing_04_00\(frameNumber)"
                    }

                    frames.append(goodJobAtlas.textureNamed(textureName))
                }

                playAnimationInSpriteKitScene(frames: frames, isLetter: false)
                playSound(soundName: "Kali_KeepGoing_04")

            } else
            {
                changeLetterAndPlayIt()
            }

        case .goodJob:
            changeLetterAndPlayIt()

        default: break
        }

    }

    private func changeLetterAndPlayIt()
    {
        var randomNumber = 0 

        repeat {
            randomNumber = Int(arc4random_uniform(3))
        } while randomNumber == letterIndex

        letterIndex = randomNumber
      
        playCurrentLetter()
    }
}

extension MainController: AVAudioPlayerDelegate
{

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool)
    {
        // NOTE: (Ted)  Don't continue unless it has played successfully.
        guard flag else { return }

        switch sceneState {

        case .letsLearnALetterIntro:
            changeLetterAndPlayIt()

        case .letter(let letter):
            sceneState = .awaitingLetterTap(letter: letter)

        case .letterObject(let letter):
            sceneState = .awaitingLetterObjectTap(letter: letter)

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
    var backgroundColorNode: SKSpriteNode?

    func animateKali(frames: [SKTexture], repeats: Bool = false, isLetter: Bool)
    {
        guard 
            let kaliNode = kaliNode,
            let backgroundColorNode = backgroundColorNode else
        {
            assertionFailure("Unable to find Kali Node in SpriteKit Scene")
            return
        }

        let backgroundColor: UIColor

        if isLetter
        {
            //  Purple Color Hex
            //  0x493069

            // R   G   B
            // 73, 48, 105
            backgroundColor = UIColor(red: 73/255, green: 48/255, blue: 105/255, alpha: 1)

        } else
        {
            // Grey Color Hex
            // 0xDCDCDC

            // RGB == 220 across the board.
            backgroundColor = UIColor(red: 220/255, green: 220/255, blue: 220/255, alpha: 1)
        }


        let animateAction = SKAction.animate(with: frames,
                                     timePerFrame: 1/30,
                                           resize: false,
                                          restore: false)

        kaliNode.removeAllActions()

        if repeats
        {
            kaliNode.run(SKAction.repeatForever(animateAction))
        } else
        {
            kaliNode.run(animateAction)
        }

        backgroundColorNode.color = backgroundColor
    }
}

