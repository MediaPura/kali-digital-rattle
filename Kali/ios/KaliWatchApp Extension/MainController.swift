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
        case awaitingIntroTap
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

    enum SoundFileType
    {
        case mp3
        case m4a
    }

    private func getSoundURL(soundName: String, fileType: SoundFileType) -> URL
    {
        var fileTypeString = String()

        switch fileType {
        case .mp3:
            fileTypeString = "mp3"
        case .m4a:
            fileTypeString = "m4a"
        }

        guard let soundURL = Bundle.main.url(forResource: soundName,
                                             withExtension: fileTypeString) else
        {
            fatalError("All sounds must exist before being loaded")
        }

        return soundURL
    }

    // NOTE: (Ted)  This is purely a convenience, meant only for situations
    //              when we don't really care if the sound syncs with any
    //              given animations.
    private func playSoundLowAudioSync(soundName: String, fileType: SoundFileType = .m4a)
    {
        let soundURL = getSoundURL(soundName: soundName, fileType: fileType)

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
        let soundURL = getSoundURL(soundName: soundName, fileType: .m4a)

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
    private var isAnimatedCongratulation = false

    var goodJobAtlas: SKTextureAtlas?
    var goodJobAtlasLoaded = false

    private var lessonCount = 0

    var letterIndex = 0 
    let supportedLetters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S",
                            "T", "U", "V", "W", "X", "Y", "Z"]

    private var letterAtlas = SKTextureAtlas(named: "Letters")
    private var lettersHighlightedAtlas = SKTextureAtlas(named: "LettersHighlighted")
    private var letterObjectsAtlas = SKTextureAtlas(named: "LetterObjects")
    private var letterObjectsHighlightedAtlas = SKTextureAtlas(named: "LetterObjectsHighlighted")
    private var goodJobStillsAtlas = SKTextureAtlas(named: "GoodJobStills")
    private var miscellaneousAtlas = SKTextureAtlas(named: "Miscellaneous")

    private var loadingScreensAtlas = SKTextureAtlas(named: "LoadingScreen")

    override func awake(withContext context: Any?)
    {
        super.awake(withContext: context)
        crownSequencer.delegate = self
        crownSequencer.focus()

        // NOTE: (Ted)  Detect Watch OS version and possibly do something about it.
        var size: size_t = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0);
        var machine = CChar()
        sysctlbyname("hw.machine", &machine, &size, nil, 0);
        let model = String(cString: &machine, encoding: String.Encoding.utf8)
        print(model)
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


            case .awaitingIntroTap:
                sceneState = .playingIntro

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

        if !audioTrackPlayerInitialized
        {
            guard let backgroundTrackURL = Bundle.main.url(forResource: "BackgroundMusic",
                                                           withExtension: "mp3") else
            {
                fatalError("All sounds must exist before being loaded")
            }

            do {
                audioTrackPlayer = try AVAudioPlayer(contentsOf: backgroundTrackURL)
                audioTrackPlayer!.volume = 0.2
                audioTrackPlayer!.numberOfLoops = -1
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

                audioTrackPlayer.numberOfLoops = -1
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
                            textureName = "Kali_Intro_06_0000\(frameNumber)"
                        } else if (frameNumber < 100)
                        {
                            textureName = "Kali_Intro_06_000\(frameNumber)"
                        } else
                        {
                            textureName = "Kali_Intro_06_00\(frameNumber)"
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
                            textureName = "Kali_LetsLearnALetter_05_000\(frameNumber)"
                        } else if frameNumber >= 100
                        {
                            textureName = "Kali_LetsLearnALetter_05_00\(frameNumber)"
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
                        let backgroundNode = kaliScene.childNode(withName: "Background") as? SKSpriteNode
                    else
                    {
                        assertionFailure("The Kali Scene Must have all nodes hooked up in IB")
                        return
                    }

                    kaliNode.texture = weakSelf.loadingScreensAtlas.textureNamed("Loaded")
                    kaliScene.backgroundNode = backgroundNode
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

        kaliScene.animateKali(frames: frames, 
                              backgroundTexture: miscellaneousAtlas.textureNamed("Background"))
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

    enum StaticContentMode
    {
        case letterOrLetterObject
        case goodJobScene
    }


    private func displayStaticContent(texture: SKTexture, staticContentMode: StaticContentMode = .letterOrLetterObject)
    {
        guard 
            let kaliScene = kaliScene,
            let kaliNode = kaliScene.kaliNode,
            let backgroundNode = kaliScene.backgroundNode 
            
            else 
        {
            assertionFailure("Expected to load Kali Scene")
            return
        }

        kaliNode.removeAllActions()
        kaliNode.texture = texture 
        kaliNode.color = UIColor.clear

        switch staticContentMode {
        case .letterOrLetterObject:
            backgroundNode.texture = miscellaneousAtlas.textureNamed("Background")
            backgroundNode.color = UIColor.clear

        case .goodJobScene:
            backgroundNode.texture = nil
            backgroundNode.color = UIColor(red: 225/255, green: 248/255, blue: 232/255, alpha: 1)
        }
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
                        textureName = "Kali_KeepGoing_05_0000\(frameNumber)"
                    } else if frameNumber < 100
                    {
                        textureName = "Kali_KeepGoing_05_000\(frameNumber)"
                    } else if frameNumber >= 100
                    {
                        textureName = "Kali_KeepGoing_05_00\(frameNumber)"
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

            let randomNumber = Int.random(in: 0...6)

            if randomNumber < 6
            {
                // NOTE: (Ted)  Use any of the still images. Make that a tap to keep going.
                audioFilename = "Kali_KeepGoing_04"
                displayStaticContent(texture: goodJobStillsAtlas.textureNamed("\(randomNumber)"), 
                                     staticContentMode: .goodJobScene)
                isAnimatedCongratulation = false
            } else
            {
                playAnimationInSpriteKitScene(frames: frames)
                isAnimatedCongratulation = true
            }

            playSoundLowAudioSync(soundName: audioFilename)

        } else
        {
            changeLetterAndPlayIt()
        }
    }

    private let successSoundName = "TapLetter"

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

            kaliScene.animateKali(frames: introFrames, 
                                  backgroundTexture: miscellaneousAtlas.textureNamed("Background"))

        case .awaitingIntroTap:
            clearIntroMemory()
            playCurrentLetter()

        case .awaitingLetterTap:
            sceneState = .successDingLetter
            let currentLetter = supportedLetters[letterIndex]
            displayStaticContent(texture: lettersHighlightedAtlas.textureNamed(currentLetter))
            playSoundLowAudioSync(soundName: successSoundName, fileType: .mp3)

        case .successDingLetter:
            playCurrentLetterObject()

        case .awaitingLetterObjectTap:
            sceneState = .successDingLetterObject
            let currentLetter = supportedLetters[letterIndex]
            displayStaticContent(texture: letterObjectsHighlightedAtlas.textureNamed(currentLetter))
            playSoundLowAudioSync(soundName: successSoundName, fileType: .mp3)

        case .successDingLetterObject:
            congratulateIfLoadedIfNotChangeLetter()

        case .goodJob:
            changeLetterAndPlayIt()

        default: break
        }

    }

    private func changeLetterAndPlayIt()
    {
        letterIndex += 1
     
        if letterIndex > 25
        {
            letterIndex = 0
        }

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
            case .kali: 
                sceneState = .awaitingIntroTap
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

            if isAnimatedCongratulation
            {
                switch congratulationType {
                case .long: break
                case .short:
                    changeLetterAndPlayIt()
                }
            }

            isAnimatedCongratulation = false

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
    var backgroundNode: SKSpriteNode?

    func animateKali(frames: [SKTexture], backgroundTexture: SKTexture)
    {
        guard 
            let kaliNode = kaliNode,
            let backgroundNode = backgroundNode else
        {
            assertionFailure("Unable to find Kali Node in SpriteKit Scene")
            return
        }

        let animateAction = SKAction.animate(with: frames,
                                     timePerFrame: 1/30,
                                           resize: false,
                                          restore: false)

        kaliNode.removeAllActions()
        kaliNode.run(animateAction)

        backgroundNode.texture = backgroundTexture 
        backgroundNode.color = UIColor.clear
    }
}

