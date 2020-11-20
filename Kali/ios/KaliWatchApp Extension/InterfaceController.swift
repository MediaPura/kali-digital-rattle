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
    @IBOutlet private weak var animatedImage: WKInterfaceImage!
    private var player: AVPlayer!
    private let imageRange = NSRange(location: 0, length: 40)

    private var animationDuration: TimeInterval = 1

    override func awake(withContext context: Any?) 
    {
        super.awake(withContext: context)
        animatedImage.setImageNamed("earth")
    }

    private func slowAnimationAndPlayIt()
    {
        animationDuration += 1
        animatedImage.startAnimatingWithImages(in: imageRange, 
                                               duration: animationDuration, 
                                               repeatCount: 0)
    }

    override func willActivate() 
    {
        super.willActivate()
        slowAnimationAndPlayIt()
    }
    
    @IBAction func tappedImage()
    {
        slowAnimationAndPlayIt()
    }
}
