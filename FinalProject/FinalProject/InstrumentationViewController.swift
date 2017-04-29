//
//  InstrumentationViewController.swift
//  Final Project
//
//  Created by Janak Patel on 4/1/17.
//  Copyright © 2017 Harvard Division of Continuing Education. All rights reserved.
//

import UIKit

class InstrumentationViewController: UIViewController {
    
    @IBOutlet weak var sizeStepper: UIStepper!
    
    @IBOutlet weak var refreshRateSlider: UISlider!
    
    @IBOutlet weak var refeshTimerToggle: UISwitch!
    
    @IBOutlet weak var sizeDisplayLabel: UILabel!
    
    @IBOutlet weak var refreshRateDisplayLabel: UILabel!
    
    @IBAction func refreshOnOff(_ sender: Any) {
        if (refeshTimerToggle.isOn) {
            engine.refreshRate = TimeInterval(refreshRateSlider.value)
        } else {
            engine.refreshRate = 0.0
        }
    }
    
    @IBAction func refreshRateValueChange(_ sender: Any) {
        refreshRateDisplayLabel.text = String(format:"(%.2f)", refreshRateSlider.value)
        if (refeshTimerToggle.isOn) { // If toggle button is turned on...
            // then update the engine refresh rate, otherwise do nothing.
            engine.refreshRate = 0.0 // Invalidate any existing timer.
            engine.refreshRate = TimeInterval(refreshRateSlider.value)
        }
    }
    
    let engine = StandardEngine.engine
    var finalProjectURL = "https://dl.dropboxusercontent.com/u/7544475/S65g.json"
    var gridTitles: [String] = []
    var gridConfigurations: [GridProtocol] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sizeStepper.value = Double(engine.grid.size.rows)
        sizeDisplayLabel.text = "(\(Int(sizeStepper.value))x\(Int(sizeStepper.value)))"
        refreshRateDisplayLabel.text = String(format:"(%.1f)", refreshRateSlider.value)
        
        // Final Project addition
        updateGridConfigurations(url: finalProjectURL)
        
        // HELP: This for loop never executes because gridTitles array is somehow reset to empty. WHY??
        // I can seem to set and retain the gridTitles and gridConfigurations Arrays after calling updateGridConfigurations() method.
        for title in gridTitles {
            print(title)
        }
        print("Done viewDidLoad method!")
        
    }
    
    func updateGridConfigurations(url: String) {
        gridTitles = []
        gridConfigurations = []
        
        let fetcher = Fetcher()
        fetcher.fetchJSON(url: URL(string:url)!) { (json: Any?, message: String?) in
            guard message == nil else {
                print(message ?? "nil")
                return
            }
            guard let json = json else {
                print("no json")
                return
            }
            //print(json)
            
            
            let jsonArray = json as! NSArray
            for item in 0..<jsonArray.count {  // for every json item...
                let jsonDictionary = jsonArray[item] as! NSDictionary
                
                let jsonTitle = jsonDictionary["title"] as! String
                let jsonContents = jsonDictionary["contents"] as! [[Int]]
                
                // find max value so we know how big to make the grid.
                var maxRowColValue: Int = 10 // minimum Grid Size will be set to 10.
                for i in 0..<jsonContents.count {
                    if (jsonContents[i].max()! > maxRowColValue){maxRowColValue = jsonContents[i].max()!}
                }
                
                // define size of grid we're about to create based on maxRowColValue
                var myGridSize: Int
                if maxRowColValue >= 75 && maxRowColValue <= 150 {  // if large grid, make it about the same size as the largest rowcol value.
                    let doubleOneTenthGridSize: Double = Double(maxRowColValue) / 10.0
                    let roundedUpOneTenthGridSize: Double = doubleOneTenthGridSize.rounded(.up)
                    myGridSize = Int(roundedUpOneTenthGridSize) * 10
                } else { // else create new grid roughly the size of maxRowColValue times two.
                    myGridSize = (Int((Double(maxRowColValue)/10.0).rounded(.up) * 10) * 2)
                }
                
                //var myGrid: GridProtocol
                if myGridSize <= 150 {
                    var myGrid = Grid(myGridSize, myGridSize, cellInitializer: {_,_ in .empty})
                    
                    // set grid cells to alive where appropriate.
                    for i in 0..<jsonContents.count {
                        let row: Int = jsonContents[i][0]
                        let col: Int = jsonContents[i][1]
                        myGrid[(row,col)] = CellState.alive
                    }
                    
                    OperationQueue.main.addOperation {
                        // add grid to gridConfigurations Array.
                        self.gridConfigurations.append(myGrid)
                        // add grid configuration title to gridTitles[] array.
                        self.gridTitles.append(jsonTitle)
                    }
                }
            }
            
            OperationQueue.main.addOperation {
                //self.textView.text = resultString
                /*
                for title in self.gridTitles {
                    print(title)
                }*/
            }
            
        } // End of fetcher
    } // End of updateGridConfigurations()
    
    // Stepper increments or decrements grid size.
    @IBAction func step(_ sender: Any) {
        let newGridSize = Int(sizeStepper.value)
        engine.changeGridSize(newGridSize, newGridSize)
        sizeDisplayLabel.text = "(\(newGridSize)x\(newGridSize))"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}

