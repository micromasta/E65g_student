//
//  InstrumentationViewController.swift
//  Final Project
//
//  Created by Janak Patel on 4/1/17.
//  Copyright © 2017 Harvard Division of Continuing Education. All rights reserved.
//

import UIKit

class InstrumentationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
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
    
    @IBAction func add(_ sender: Any) {
        // Create new row in tableView
        self.gridTitles.insert("NewGrid", at: 0)
        self.gridContainer.setGridTitles(to: self.gridTitles)
        
        // add new grid to gridConfigurations[] array.
        let myGrid = Grid(20, 20, cellInitializer: {_,_ in .empty})
        self.gridConfigurations.insert(myGrid, at: 0)
        self.gridContainer.setGridConfigurations(to: self.gridConfigurations)
        self.tableView.reloadData()
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
    let editor = StandardEngine.editor
    var finalProjectURL = "https://dl.dropboxusercontent.com/u/7544475/S65g.json"
    var gridTitles: [String] = []
    var gridConfigurations: [GridProtocol] = []
    let gridContainer = GridContainer.myGridContainer
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sizeStepper.value = Double(engine.grid.size.rows)
        sizeDisplayLabel.text = "(\(Int(sizeStepper.value))x\(Int(sizeStepper.value)))"
        refreshRateDisplayLabel.text = String(format:"(%.1f)", refreshRateSlider.value)
        
        // updates grid configurations
        updateGridConfigurations(url: finalProjectURL) {
            
            self.gridTitles = self.gridContainer.gridTitles
            self.gridConfigurations = self.gridContainer.gridConfigurations
            
            // refresh table view
            self.tableView.reloadData()
        } // End of updateGridConfigurations closure.
        
        // updates instrumentation panel when underlying Engine is updated.
        let nc = NotificationCenter.default
        let name = Notification.Name(rawValue: "EngineUpdate")
        nc.addObserver(
            forName: name,
            object: nil,
            queue: nil) { (n) in
                self.updateInstrumentationPanel()
        }
        
        // reloads Table View when needed.
        NotificationCenter.default.addObserver(self, selector: #selector(reloadList), name: NSNotification.Name(rawValue: "reload"), object: nil)
        
    } // End of viewDidLoad()
    
    // reloads Table View
    func reloadList(){
        self.gridTitles = self.gridContainer.gridTitles
        self.gridConfigurations = self.gridContainer.gridConfigurations
        // reload table view data
        self.tableView.reloadData()
    }
    
    // updates size stepper value and size labels to current state of engine grid.
    func updateInstrumentationPanel() {
        sizeStepper.value = Double(engine.grid.size.rows)
        sizeDisplayLabel.text = "(\(Int(sizeStepper.value))x\(Int(sizeStepper.value)))"
    }
    
    // hides to NavBar
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.isNavigationBarHidden = true
    }
    
    // updates gridTitles[] and gridConfigurations[] based on JSON from given URL
    func updateGridConfigurations(url: String, completion: @escaping () -> Void) {
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
                if maxRowColValue >= 50 && maxRowColValue <= 150 {  // if large grid, make it about the same size as the largest rowcol value.
                    let doubleOneTenthGridSize: Double = Double(maxRowColValue) / 10.0
                    let roundedUpOneTenthGridSize: Double = doubleOneTenthGridSize.rounded(.up)
                    myGridSize = Int(roundedUpOneTenthGridSize) * 10
                } else { // else create new grid roughly the size of maxRowColValue times two.
                    myGridSize = (Int((Double(maxRowColValue)/10.0).rounded(.up) * 10) * 2)
                }
                
                if myGridSize <= 150 {
                    var myGrid = Grid(myGridSize, myGridSize, cellInitializer: {_,_ in .empty})
                    
                    // set grid cells to alive where appropriate.
                    for i in 0..<jsonContents.count {
                        let row: Int = jsonContents[i][0]
                        let col: Int = jsonContents[i][1]
                        myGrid[(row,col)] = CellState.alive
                    }
                    
                    // add grid to gridConfigurations[] array.
                    self.gridContainer.gridConfigurations.append(myGrid)
                    // add grid configuration title to gridTitles[] array.
                    self.gridContainer.gridTitles.append(jsonTitle)
                }
            }
            
            OperationQueue.main.addOperation {
                completion()
            }
            
        } // End of fetcher
    } // End of updateGridConfigurations()
    
    // Stepper increments or decrements grid size.
    @IBAction func step(_ sender: Any) {
        let newGridSize = Int(sizeStepper.value)
        engine.changeGridSize(newGridSize, newGridSize)
        sizeDisplayLabel.text = "(\(newGridSize)x\(newGridSize))"
    }
    
    // MARK: - Table view data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return gridContainer.gridTitles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "basic"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        let label = cell.contentView.subviews.first as! UILabel

        label.text = gridContainer.gridTitles[indexPath.item]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // remove grid to gridConfigurations[] array.
            self.gridContainer.gridConfigurations.remove(at: indexPath.item)
            // remove grid configuration title to gridTitles[] array.
            self.gridContainer.gridTitles.remove(at: indexPath.item)
            
            tableView.deleteRows(at: [indexPath], with: .automatic)
            self.reloadList()  // does tableView.reloadData() also.
        }
    }
    
    // End of Table View data source methods.
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Sets "back" button to "cancel"
        let cancelNavBarButton = UIBarButtonItem()
        cancelNavBarButton.title = "Cancel"
        navigationItem.backBarButtonItem = cancelNavBarButton
        
        // Sets grid that GridEditor View Controller will present after segue.
        let indexPath = tableView.indexPathForSelectedRow
        if let indexPath = indexPath {
            let gridIndex = indexPath.row  // Index in gridTitles and gridConfigurations we need.
            //print(gridIndex)
            if let vc = segue.destination as? GridEditorViewController {
                // set gridEditorViewController's grid from gridConfigurations.
                let newGrid = gridConfigurations[gridIndex]
                vc.editor.setGrid(to: newGrid)
                // set gridNameTextField value from gridTitles.
                vc.nameValue = gridTitles[gridIndex]
                
                // Update grid configuration name based on value set in gridEditor save()
                vc.saveClosure = { newValue, newGrid in
                    self.gridTitles[gridIndex] = newValue
                    self.gridContainer.setGridTitles(to: self.gridTitles)
                    
                    self.gridConfigurations[gridIndex] = newGrid
                    self.gridContainer.setGridConfigurations(to: self.gridConfigurations)
                    
                    self.tableView.reloadData()
                }
            }
        }
    } // End of prepare()
    
} // End of InstrumentationViewController

