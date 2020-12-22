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

class SpriteTestInterfaceController: WKInterfaceController
{
    @IBOutlet private weak var spriteKitScene: WKInterfaceSKScene?

    private var kaliScene: KaliScene?
    private var crownRotationEventCount: Int = 0

    private var soundPlayer: AVAudioPlayer?
    private var soundIsPlaying: Bool = false

    private var soundIndex = 0

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
            soundPlayer!.delegate = self
            soundPlayer!.play() 
            soundIsPlaying = true
        } catch
        {
            assertionFailure("It should always be possible to create a sound player")
        }
    }

    private func incrementIndexAndPlaySound()
    {
        soundIndex = soundIndex + 1

        if (soundIndex > 10)
        {
            soundIndex = 1
        }

        let soundName = "\(soundIndex)-clean-full_01"
        playSound(soundName: soundName)
    }

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

    override func willActivate()
    {
        super.willActivate()
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false, block: { [weak self] (timer) in
            guard 
                let weakSelf = self,
                !weakSelf.soundIsPlaying else { return }
        
                weakSelf.incrementIndexAndPlaySound()
        })

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

    @IBAction func tappedScene(gestureRecognizer: WKGestureRecognizer)
    {
        incrementIndexAndPlaySound()
    }
}

extension SpriteTestInterfaceController: AVAudioPlayerDelegate
{
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool)
    {
        guard flag else { return } 

        soundIsPlaying = false
        incrementIndexAndPlaySound()
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

