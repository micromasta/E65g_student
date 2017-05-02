//
//  GridEditorViewController.swift
//  FinalProject
//
//  Created by Janak Patel on 4/30/17.
//  Copyright © 2017 Harvard Division of Continuing Education. All rights reserved.
//

import UIKit

class GridEditorViewController: UIViewController, EngineDelegate, GridViewDataSource  {

    @IBOutlet weak var editorGrid: GridView!
    
    @IBOutlet weak var gridNameTextField: UITextField!
    
    @IBAction func save(_ sender: Any) {
        if let newValue = gridNameTextField.text,
            let saveClosure = saveClosure {
            engine.setGrid(to: editor.grid)
            // Uncomment following line if we want 'save' button in grid editor to save to user defaults also.
            //engine.saveCurrentGridToUserDefaults(gridName: newValue)
            saveClosure(newValue, editor.grid)
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    let editor = StandardEngine.editor
    let engine = StandardEngine.engine
    var nameValue: String?
    var saveClosure: ((String, GridProtocol) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.isNavigationBarHidden = false // shows top NavBar
        
        if let nameValue = nameValue {
            gridNameTextField.text = nameValue
        }
        
        editor.delegate = self  // Set as delegate
        editorGrid.myGrid = self // Important - sets grid in GridView.
        editorGrid.size = editor.rows // Sets size variable in GridView.

    }
    
    // engineDidUpdate declaration to implement EngineDelegate
    func engineDidUpdate(withGrid: GridProtocol) {
        self.editorGrid.size = editor.rows
        self.editorGrid.setNeedsDisplay()
    }
    
    // subscript declaration to implement GridViewDataSource; gets and sets current engine grid.
    public subscript (row: Int, col: Int) -> CellState {
        get { return editor.grid[row,col] }
        set { editor.grid[row,col] = newValue }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
