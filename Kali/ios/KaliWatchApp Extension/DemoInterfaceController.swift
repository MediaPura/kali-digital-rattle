//
//  InterfaceController.swift
//  KaliWatchApp Extension
//
//  Created by Theodore Bendixson on 11/20/20.
//

import WatchKit
import AVFoundation
import Foundation

class DemoInterfaceController: WKInterfaceController
{
    enum AnimatedCharacterState
    {
        case intro
        case tapMySnout
        case awaitingSnoutTap
        case world
        case tapMyAntlers
        case awaitingAntlerTap
        case waldoIntroduction
    }

    var characterState: AnimatedCharacterState = .intro

    @IBOutlet private weak var animatedImage: WKInterfaceImage?
    private var soundPlayer: AVAudioPlayer?

    private var soundIsPlaying: Bool = false

    private func displayImage(imageName: String, animated: Bool = false)
    {
        guard let animatedImage = animatedImage else
        {
            assertionFailure("WKInterfaceImage: animatedImage unavailable. Did you hook up the IBOutlet?")
            return
        }

        animatedImage.setImageNamed(imageName)

        if animated
        {
            animatedImage.startAnimating()
        } else
        {
            animatedImage.stopAnimating()
        }
    }

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

        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false, block: { [weak self] (timer) in
            guard 
                let weakSelf = self,
                !weakSelf.soundIsPlaying else { return }

            switch weakSelf.characterState {

            case .intro:
                weakSelf.displayImage(imageName: "Moosie")
                weakSelf.playSound(soundName: "MoosiePlayGame")

            case .tapMySnout:
                weakSelf.displayImage(imageName: "Moosie")
                weakSelf.playSound(soundName: "TapMySnout")

            case .awaitingSnoutTap:
                weakSelf.displayImage(imageName: "Moosie")
                weakSelf.playSound(soundName: "WhereDidYouGoSnoutTap")

            case .tapMyAntlers:
                weakSelf.displayImage(imageName: "Moosie")
                weakSelf.playSound(soundName: "TapMyAntlers")

            case .world:
                weakSelf.displayImage(imageName: "earth", animated: true)
                weakSelf.playSound(soundName: "WorldMooseCritters")

            case .awaitingAntlerTap:
                weakSelf.displayImage(imageName: "Moosie")
                weakSelf.playSound(soundName: "TapMyAntlers")

            case .waldoIntroduction:
                weakSelf.displayImage(imageName: "Waldo")
                weakSelf.playSound(soundName: "Waldo")


            default: break

            }
        })

    }

    @IBAction func tappedImage(gestureRecognizer: WKGestureRecognizer)
    {
        switch characterState {
        case .awaitingSnoutTap:
            characterState = .world
            displayImage(imageName: "earth", animated: true)
            playSound(soundName: "WorldMooseCritters")
       
        case .awaitingAntlerTap:
            let touchPoint = gestureRecognizer.locationInObject()
            let bounds = gestureRecognizer.objectBounds()

            if touchPoint.y < (bounds.height/2)
            {
                characterState = .waldoIntroduction 
                displayImage(imageName: "Waldo")
                playSound(soundName: "Waldo")
            }

        case .waldoIntroduction:
            displayImage(imageName: "Moosie")
            playSound(soundName: "MoosiePlayGame")
            characterState = .intro

        default: break
        }
        
    }
}

extension DemoInterfaceController: AVAudioPlayerDelegate
{
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool)
    {
        // NOTE: (Ted)  Don't continue unless it has played successfully.
        guard flag else { return }

        soundIsPlaying = false

        switch characterState {

        case .intro:
            characterState = .tapMySnout
            displayImage(imageName: "Moosie")
            playSound(soundName: "TapMySnout")

        case .tapMySnout:
            characterState = .awaitingSnoutTap

        case .world:
            characterState = .tapMyAntlers
            displayImage(imageName: "Moosie")
            playSound(soundName: "TapMyAntlers")
        
        case .tapMyAntlers:
            characterState = .awaitingAntlerTap

        default: break
        }

    }
}
