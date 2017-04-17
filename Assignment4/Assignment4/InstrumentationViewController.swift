//
//  InstrumentationViewController.swift
//  Assignment4
//
//  Created by Janak Patel on 4/1/17.
//  Copyright © 2017 Harvard Division of Continuing Education. All rights reserved.
//

import UIKit

class InstrumentationViewController: UIViewController {
    
    @IBOutlet weak var sizeStepper: UIStepper!
    
    @IBOutlet weak var refreshRateSlider: UISlider!
    
    @IBOutlet weak var refeshTimerToggle: UISwitch!
    
    @IBAction func refreshOnOff(_ sender: Any) {
        if (refeshTimerToggle.isOn) {
            engine.refreshRate = TimeInterval(refreshRateSlider.value)
        } else {
            engine.refreshRate = 0.0
        }
    }
    
    @IBAction func refreshRateValueChange(_ sender: Any) {
        if (refeshTimerToggle.isOn) { // If toggle button is turned on...
            // then update the engine refresh rate, otherwise do nothing.
            engine.refreshRate = 0.0 // Invalidate any existing timer.
            engine.refreshRate = TimeInterval(refreshRateSlider.value)
        }
    }
    
    let engine = StandardEngine.engine
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sizeStepper.value = Double(engine.grid.size.rows)
    }
    
    // Stepper increments or decrements grid size.
    @IBAction func step(_ sender: Any) {
        let newGridSize = Int(sizeStepper.value)
        engine.changeGridSize(newGridSize, newGridSize)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }    
}

