//
//  StatisticsViewController.swift
//  Assignment4
//
//  Created by Janak Patel on 4/1/17.
//  Copyright © 2017 Harvard Division of Continuing Education. All rights reserved.
//

import UIKit

class StatisticsViewController: UIViewController {

    @IBOutlet weak var numLivingCellsLabel: UILabel!
    
    @IBOutlet weak var numBornCellsLabel: UILabel!
    
    @IBOutlet weak var numDeadCellsLabel: UILabel!
    
    @IBOutlet weak var numEmptyCellsLabel: UILabel!
    
    let engine = StandardEngine.engine
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let nc = NotificationCenter.default
        let name = Notification.Name(rawValue: "EngineUpdate")
        nc.addObserver(
            forName: name,
            object: nil,
            queue: nil) { (n) in
                self.updateCellCounts()
        }
        
        updateCellCounts()
    }

    func updateCellCounts() {
        engine.updateCellStatusCounts()
        numLivingCellsLabel.text = String(engine.aliveCellCount)
        numBornCellsLabel.text = String(engine.bornCellCount)
        numDeadCellsLabel.text = String(engine.deadCellCount)
        numEmptyCellsLabel.text = String(engine.emptyCellCount)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
