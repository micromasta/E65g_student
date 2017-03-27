//
//  ViewController.swift
//  Assignment3
//
//  Created by Van Simmons on 1/15/17.
//  Copyright © 2017 Harvard Division of Continuing Education. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    var audioPlayer = AVAudioPlayer()
    @IBOutlet weak var myStepButton: UIButton!  // ctrl dragged Step button here
    @IBOutlet weak var gridView: GridView!  // ctrl dragged Grid View here
    var player:AVAudioPlayer = AVAudioPlayer()
    
    @IBAction func myStepButtonAction(_ sender: Any) {
        // Plays audio file.
        audioPlayer.play()
        
        // Updates grid state to its next state.
        gridView.myGrid = gridView.myGrid.next()  // Updates myGrid to its next state.
        gridView.setNeedsDisplay()  // Refreshes display of Grid View.
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: URL.init(fileURLWithPath: Bundle.main.path(forResource: "VanceLaneTTS", ofType: "m4a")!))
            audioPlayer.prepareToPlay()
        } catch {
            print(error)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

