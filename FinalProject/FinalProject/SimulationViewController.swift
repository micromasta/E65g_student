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
    
    @IBAction func save(_ sender: Any) {
        
        let alertController = UIAlertController(title:"Enter new name:", message: nil, preferredStyle: .alert)
        
        alertController.addTextField { textField in
            textField.placeholder = "Grid name"
        }
        
        // closure completion handler executed after user hits OK
        let okActionHandler = { (action:UIAlertAction!) -> Void in
            let usersGridName = alertController.textFields?[0].text
            
            // save current grid state to user defaults
            self.engine.saveCurrentGridToUserDefaults(gridName: usersGridName!)
            
            self.engine.currentGridName = usersGridName!
            
            self.gridContainer.gridTitles.insert(usersGridName!, at: 0)
            self.gridContainer.gridConfigurations.insert(self.engine.grid, at: 0)
            
            // ask Instrumentation controller to reload Table View
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "reload"), object: nil)
        }
        
        let ok = UIAlertAction(title:"OK", style: UIAlertActionStyle.default, handler:okActionHandler)
        alertController.addAction(ok)
        
        self.present(alertController, animated:true, completion:nil)
    }
    
    @IBAction func reset(_ sender: Any) {
        engine.changeGridSize(10, 10)
    }
    
    let engine = StandardEngine.engine
    let gridContainer = GridContainer.myGridContainer
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // set self (SimulationViewController) as delegate of StandardEngine
        engine.delegate = self
        gridView.myGrid = self // Important - sets grid in GridView.
        gridView.size = engine.rows // Sets size variable in GridView.
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

