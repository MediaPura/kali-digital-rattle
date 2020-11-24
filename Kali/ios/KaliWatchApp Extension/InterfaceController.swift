//
//  InterfaceController.swift
//  KaliWatchApp Extension
//
//  Created by Theodore Bendixson on 11/20/20.
//

import WatchKit
import AVFoundation
import Foundation

class InterfaceController: WKInterfaceController
{
    enum AnimatedCharacterState
    {
        case intro
        case tapMySnout
        case awaitingSnoutTap
        case world
        case tapMyAntlers
        case waldoIntroduction
    }

    var characterState: AnimatedCharacterState = .intro

    @IBOutlet private weak var animatedImage: WKInterfaceImage?
    private var soundPlayer: AVAudioPlayer?

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
        } catch
        {
            assertionFailure("It should always be possible to create a sound player")
        }
    }

    override func willActivate()
    {
        super.willActivate()

        switch characterState {

        case .intro:
            displayImage(imageName: "Moosie")
            playSound(soundName: "MoosiePlayGame")

        case .tapMySnout:
            displayImage(imageName: "Moosie")
            playSound(soundName: "TapMySnout")

        case .awaitingSnoutTap:
            displayImage(imageName: "Moosie")
            playSound(soundName: "WhereDidYouGoSnoutTap")

        default: break

        }
    }

    @IBAction func tappedImage()
    {
        if characterState == .awaitingSnoutTap
        {
            characterState = .world
            displayImage(imageName: "earth", animated: true)
            playSound(soundName: "WorldMooseCritters")
        }

        
    }
}

extension InterfaceController: AVAudioPlayerDelegate
{
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool)
    {
        // NOTE: (Ted)  Don't continue unless it has played successfully.
        guard flag else
        {
            return
        }

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

        default: break
        }

    }
}
