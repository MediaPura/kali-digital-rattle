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
        case letter
        case awaitingLetterTap
        case successDingLetter
        case letterObject
        case successDingLetterObject
        case awaitingLetterObjectTap
        case goodJob
    }

    private var sceneState: SceneState = .loadingIntro

    private var kaliScene: KaliScene?
    private var crownRotationEventCount: Int = 0

    private var audioTrackPlayer: AVAudioPlayer?
    private var audioTrackPlayerInitialized = false

    private var soundPlayer: AVAudioPlayer?
    private var soundIsPlaying: Bool = false

    private func getSoundURLForM4aFile(soundName: String) -> URL
    {
        guard let soundURL = Bundle.main.url(forResource: soundName,
                                             withExtension: "m4a") else
        {
            fatalError("All sounds must exist before being loaded")
        }

        return soundURL
    }

    // NOTE: (Ted)  This is purely a convenience, meant only for situations
    //              when we don't really care if the sound syncs with any
    //              given animations.
    private func playSoundLowAudioSync(soundName: String)
    {
        let soundURL = getSoundURLForM4aFile(soundName: soundName)

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

    private func preloadSound(soundName: String)
    {
        let soundURL = getSoundURLForM4aFile(soundName: soundName)

        do {
            soundPlayer = try AVAudioPlayer(contentsOf: soundURL)

            // NOTE: (Ted)  This is important for the animations. Since a heavy amount
            //              of work is happening at startup, we want to make sure the sound
            //              player is ready and has acquired its resources by the time
            //              the user taps to start the intro animation.
            soundPlayer!.prepareToPlay()
        } catch 
        {
            assertionFailure("It should always be possible to create a sound player")
        }
    }

    var introAtlas: SKTextureAtlas? 
    var introFrames: [SKTexture] = [SKTexture]()

    enum IntroType
    {
        case kali
        case letsLearnALetter
    }

    private var introType: IntroType = .kali

    enum CongratulationType
    {
        case short
        case long
    }

    private var congratulationType: CongratulationType = .long

    var goodJobAtlas: SKTextureAtlas?
    var goodJobAtlasLoaded = false

    private var lessonCount = 0

    // TODO: (Ted)  Get rid of letter and letter object atlases. Replace with straight textures.
    var letterIndex = 0
    let supportedLetters = ["A", "B", "C"]
    private var letterAtlas = SKTextureAtlas(named: "Letters")
    private var lettersHighlightedAtlas = SKTextureAtlas(named: "LettersHighlighted")
    private var letterObjectsAtlas = SKTextureAtlas(named: "LetterObjects")
    private var letterObjectsHighlightedAtlas = SKTextureAtlas(named: "LetterObjectsHighlighted")

    private var loadingScreensAtlas = SKTextureAtlas(named: "LoadingScreen")

    override func awake(withContext context: Any?)
    {
        super.awake(withContext: context)
        crownSequencer.delegate = self
        crownSequencer.focus()
    }

    private func loadGoodJobAnimation()
    {
        let randomNumber = Int(arc4random_uniform(2))

        if randomNumber == 0
        {
            congratulationType = .long
            goodJobAtlas = SKTextureAtlas(named: "GoodJob")
        } else if randomNumber == 1
        {
            congratulationType = .short
            goodJobAtlas = SKTextureAtlas(named: "GoodJobShort")
        }

        guard let goodJobAtlas = goodJobAtlas else 
        {
            assertionFailure("Good Job Atlas should be set by now")
            return
        }

        DispatchQueue.global(qos: .background).async
        {
            for textureName in goodJobAtlas.textureNames
            {
                let texture = goodJobAtlas.textureNamed(textureName)
                print(texture.size())
            }

            DispatchQueue.main.async { [weak self] in
                self?.goodJobAtlasLoaded = true
            }
        }
    }

    private var currentLetter: String 
    {
        return supportedLetters[letterIndex]
    }

    override func didDeactivate()
    {
        super.didDeactivate()

        if let soundPlayer = soundPlayer 
        {
            soundPlayer.pause()
            soundIsPlaying = false
        }

        if let audioTrackPlayer = audioTrackPlayer 
        {
            audioTrackPlayer.pause() 
        }

        switch sceneState {

            case .awaitingLetterTap: 
                sceneState = .letter

            case .awaitingLetterObjectTap:
                sceneState = .letterObject

            default: break
        }
    }

    override func willActivate()
    {
        func loadStandardIntro()
        {
            introAtlas = SKTextureAtlas(named: "Kali")
            introType = .kali
        }

        super.willActivate()

        // TODO: (Ted)  Bring this back once we've got a background audio track that won't
        //              annoy the crap out of people.
        
        if !audioTrackPlayerInitialized
        {
            guard let backgroundTrackURL = Bundle.main.url(forResource: "Jumpshot",
                                                           withExtension: "mp3") else
            {
                fatalError("All sounds must exist before being loaded")
            }

            do {
                audioTrackPlayer = try AVAudioPlayer(contentsOf: backgroundTrackURL)
                audioTrackPlayer!.volume = 0.2
                audioTrackPlayer!.play() 
                audioTrackPlayerInitialized = true
            } catch
            {
                assertionFailure("It should always be possible to create a sound player")
            }
        } else
        {
            Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false, block: { [weak self] (timer) in
                guard let audioTrackPlayer = self?.audioTrackPlayer else
                {
                    fatalError("Audio track player should be set up by now")
                }

                audioTrackPlayer.play() 
            })
        }

        // NOTE: (Ted)  If the app goes intro the background and the intro has not yet loaded, load the intro
        switch sceneState {
        case .loadingIntro:

            guard 
                let spriteKitScene = spriteKitScene,
                let kaliScene = KaliScene(fileNamed: "Kali.sks"),
                let kaliNode = kaliScene.childNode(withName: "Kali") as? SKSpriteNode else
            {
                assertionFailure("Expected to load Kali Scene")
                return
            }

            let currentDevice = WKInterfaceDevice.current()
            let bounds = currentDevice.screenBounds
            let dimension = bounds.width - 16
            kaliNode.size.height = dimension 
            kaliNode.size.width = dimension 
            kaliScene.kaliNode = kaliNode 
            self.kaliScene = kaliScene

            spriteKitScene.preferredFramesPerSecond = 30
            spriteKitScene.presentScene(kaliScene)

            let defaults = UserDefaults.standard
            let firstLaunchKey = "FirstLaunch"

            if defaults.bool(forKey: firstLaunchKey) == false
            {
                loadStandardIntro()
                defaults.setValue(true, forKey: firstLaunchKey)
            } else
            {
                let randomNumber = Int(arc4random_uniform(2))

                if randomNumber == 0
                {
                    introAtlas = SKTextureAtlas(named: "LetsLearnALetter")
                    introType = .letsLearnALetter
                } else if randomNumber == 1
                {
                    loadStandardIntro()
                }
            }

            var introAudioFilename = String()

            switch introType {
            case .kali:
                introAudioFilename = "Kali_Intro_05"
            case .letsLearnALetter:
                introAudioFilename = "Kali_LetsLearnALetter_04"
            }

            preloadSound(soundName: introAudioFilename)

            guard let introAtlas = introAtlas else
            {
                assertionFailure("Kali Intro Atlas must be set at startup")
                return
            }

            DispatchQueue.global(qos: .background).async { [weak self] in
                guard let weakSelf = self else { return }

                switch weakSelf.introType {

                case .kali:

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

                        let texture = introAtlas.textureNamed(textureName)
                        print("Kali Intro Size: \(texture.size())")
                        weakSelf.introFrames.append(texture)
                    }

                case .letsLearnALetter:

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

                        let texture = introAtlas.textureNamed(textureName)
                        print("Learn Letter Intro Size: \(texture.size())")
                        weakSelf.introFrames.append(texture)
                    }

                }

                DispatchQueue.main.async { [weak self] in

                    guard let weakSelf = self else { return }
                    weakSelf.sceneState = .intro

                    guard 
                        let kaliNode = kaliScene.kaliNode,
                        let backgroundColorNode = kaliScene.childNode(withName: "Background") as? SKSpriteNode
                    else
                    {
                        assertionFailure("The Kali Scene Must have all nodes hooked up in IB")
                        return
                    }

                    kaliNode.texture = weakSelf.loadingScreensAtlas.textureNamed("Loaded")
                    kaliScene.backgroundColorNode = backgroundColorNode
                }
            }

        default: break
        }

        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false, block: { [weak self] (timer) in
            guard 
                let weakSelf = self,
                !weakSelf.soundIsPlaying else { return }

            switch weakSelf.sceneState {

            case .playingIntro:
                weakSelf.clearIntroMemory()
                weakSelf.playCurrentLetter()

            case .letter:
                weakSelf.playSoundLowAudioSync(soundName: "Letter\(weakSelf.currentLetter)")

            case .successDingLetter:
                weakSelf.playCurrentLetterObject()

            case .letterObject:
                weakSelf.playSoundLowAudioSync(soundName: "Letter\(weakSelf.currentLetter)Object")

            case .successDingLetterObject:
                weakSelf.congratulateIfLoadedIfNotChangeLetter()

            case .goodJob:
                weakSelf.playCurrentLetter()

            default: break
            }

        })
    }

    private func playCurrentLetter()
    {
        sceneState = .letter

        guard let kaliScene = kaliScene else
        {
            assertionFailure("Expected Kali Scene and Kali Node to be hooked up")
            return
        }

        displayStaticContent(texture: letterAtlas.textureNamed(currentLetter))
        playSoundLowAudioSync(soundName: "Letter\(currentLetter)")
    }

    private func playAnimationInSpriteKitScene(frames: [SKTexture])
    {
        guard let kaliScene = kaliScene else
        {
            assertionFailure("Expected Kali Scene and Kali Node to be hooked up")
            return
        }

        kaliScene.animateKali(frames: frames)
    }

    private func clearIntroMemory()
    {
        introAtlas = nil
        introFrames.removeAll()
    }

    private func playCurrentLetterObject()
    {
        sceneState = .letterObject
        displayStaticContent(texture: letterObjectsAtlas.textureNamed(currentLetter))
        playSoundLowAudioSync(soundName: "Letter\(currentLetter)Object")
    }

    private func displayStaticContent(texture: SKTexture)
    {
        guard 
            let kaliScene = kaliScene,
            let kaliNode = kaliScene.kaliNode,
            let backgroundColorNode = kaliScene.backgroundColorNode 
            
            else 
        {
            assertionFailure("Expected to load Kali Scene")
            return
        }

        kaliNode.removeAllActions()
        kaliNode.texture = texture 
        backgroundColorNode.color = UIColor(red: 73/255, green: 48/255, blue: 105/255, alpha: 1)
    }
           
    private func congratulateIfLoadedIfNotChangeLetter()
    {
        if goodJobAtlasLoaded
        {
            guard let goodJobAtlas = goodJobAtlas else
            {
                assertionFailure("Good job atlas must be loaded and set before it is used")
                return
            }

            sceneState = .goodJob

            var frames: [SKTexture] = []
            var audioFilename = String()

            switch congratulationType {
            case .long:

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

                audioFilename = "Kali_KeepGoing_04"

            case .short:

                for frameNumber in 0...70
                {
                    frames.append(goodJobAtlas.textureNamed("\(frameNumber)"))
                }

                audioFilename = "Kali_GoodJob_04b"
            }

            playAnimationInSpriteKitScene(frames: frames)
            playSoundLowAudioSync(soundName: audioFilename)

        } else
        {
            changeLetterAndPlayIt()
        }
    }

    @IBAction func didTapWatchFace()
    {
        switch sceneState {
        
        case .intro:
            sceneState = .playingIntro

            guard 
                let kaliScene = kaliScene else
            {
                assertionFailure("Expected to load Kali Scene")
                return
            }

            guard let soundPlayer = soundPlayer else
            {
                assertionFailure("The Sound Player must exist and be setup by the time a user taps to start the intro")
                return
            }

            soundPlayer.volume = 0.5
            soundPlayer.delegate = self
            soundPlayer.play() 
            soundIsPlaying = true

            kaliScene.animateKali(frames: introFrames)

        case .playingIntro:
            clearIntroMemory()
            playCurrentLetter()

        case .awaitingLetterTap:
            sceneState = .successDingLetter
            let currentLetter = supportedLetters[letterIndex]
            displayStaticContent(texture: lettersHighlightedAtlas.textureNamed(currentLetter))
            playSoundLowAudioSync(soundName: "success_ding")

        case .successDingLetter:
            playCurrentLetterObject()

        case .awaitingLetterObjectTap:
            sceneState = .successDingLetterObject
            let currentLetter = supportedLetters[letterIndex]
            displayStaticContent(texture: letterObjectsHighlightedAtlas.textureNamed(currentLetter))
            playSoundLowAudioSync(soundName: "success_ding")

        case .successDingLetterObject:
            congratulateIfLoadedIfNotChangeLetter()

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

        case .playingIntro:
            clearIntroMemory()

            switch introType {
            case .kali: break
            case .letsLearnALetter:
                playCurrentLetter()
            }

        case .letter:
            sceneState = .awaitingLetterTap

        case .successDingLetter:
            playCurrentLetterObject()

        case .letterObject:
            sceneState = .awaitingLetterObjectTap

            if !goodJobAtlasLoaded && lessonCount > 2
            {
                loadGoodJobAnimation()
            }

            lessonCount += 1

        case .successDingLetterObject:
            congratulateIfLoadedIfNotChangeLetter()

        case .goodJob:

            switch congratulationType {
            case .long: break
            case .short:
                playCurrentLetter()
            }

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

    func animateKali(frames: [SKTexture])
    {
        guard 
            let kaliNode = kaliNode,
            let backgroundColorNode = backgroundColorNode else
        {
            assertionFailure("Unable to find Kali Node in SpriteKit Scene")
            return
        }

        // Grey Color Hex
        // 0xDCDCDC

        // RGB == 220 across the board.
        let backgroundColor = UIColor(red: 220/255, green: 220/255, blue: 220/255, alpha: 1)

        let animateAction = SKAction.animate(with: frames,
                                     timePerFrame: 1/30,
                                           resize: false,
                                          restore: false)

        kaliNode.removeAllActions()
        kaliNode.run(animateAction)

        backgroundColorNode.color = backgroundColor
    }
}

