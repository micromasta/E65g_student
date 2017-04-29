//
//  SimulationViewController.swift
//  Final Project
//
//  Created by Janak Patel on 4/1/17.
//  Copyright © 2017 Harvard Division of Continuing Education. All rights reserved.
//

import UIKit

class SimulationViewController: UIViewController, EngineDelegate, GridViewDataSource {

    @IBOutlet weak var gridView: GridView!
    
    @IBAction func myStepButtonAction(_ sender: Any) {
        _ = engine.step() // steps the engine, which will update its grid to its next state, and trigger delegate.
    }
    
    let engine = StandardEngine.engine
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // set self (SimulationViewController) as delegate of StandardEngine
        engine.delegate = self
        gridView.myGrid = self // Important - sets grid in GridView.
        gridView.size = engine.rows // Sets size variable in GridView.
        
        let nc = NotificationCenter.default
        let name = Notification.Name(rawValue: "EngineUpdate")
        nc.addObserver(
            forName: name,
            object: nil,
            queue: nil) { (n) in
                self.gridView.setNeedsDisplay()
        }
        
    }
    
    // engineDidUpdate declaration to implement EngineDelegate
    func engineDidUpdate(withGrid: GridProtocol) {
        self.gridView.size = engine.rows
        self.gridView.setNeedsDisplay()
    }

    // subscript declaration to implement GridViewDataSource; gets and sets current engine grid.
    public subscript (row: Int, col: Int) -> CellState {
        get { return engine.grid[row,col] }
        set { engine.grid[row,col] = newValue }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

