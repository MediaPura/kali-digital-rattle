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
    @IBOutlet private weak var animatedImage: WKInterfaceImage?
    private var soundPlayer: AVPlayer?

    override func awake(withContext context: Any?) 
    {
        super.awake(withContext: context)

        guard let animatedImage = animatedImage else
        {
            assertionFailure("WKInterfaceImage: animatedImage unavailable. Did you hook up the IBOutlet?")
            return
        }

        animatedImage.setImageNamed("Smile")

        guard let soundURL = Bundle.main.url(forResource: "PlayGame",
                                             withExtension: "m4a") else
        {
            assertionFailure("All sounds must exist before being loaded")
            return
        }

        let asset = AVAsset(url: soundURL)
        let playerItem = AVPlayerItem(asset: asset)
        soundPlayer = AVPlayer(playerItem: playerItem)
    }

    override func willActivate() 
    {
        super.willActivate()

        guard let soundPlayer = soundPlayer else
        {
            assertionFailure("The Sound Player must be setup before the watch screen activates")
            return
        }

        soundPlayer.play()
    }
    
    @IBAction func tappedImage()
    {

    }
}
