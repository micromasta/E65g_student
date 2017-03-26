//
//  GridView.swift
//  Assignment3
//
//  Created by Janak Patel on 3/18/17.
//  Copyright © 2017 Harvard Division of Continuing Education. All rights reserved.
//

import UIKit

@IBDesignable class GridView: UIView {
    
    @IBInspectable var size: Int = 20 {
        didSet {
            //var grid = [[Bool]] (repeating: [Bool](repeating: false, count:gridSize), count:gridSize)
            self.myGrid = Grid(size, size)
        }
    }
    @IBInspectable var livingColor: UIColor = .green
    @IBInspectable var emptyColor: UIColor = .white
    @IBInspectable var bornColor: UIColor = .blue
    @IBInspectable var diedColor: UIColor = .red
    @IBInspectable var gridColor: UIColor = .black
    @IBInspectable var gridWidth: CGFloat = 2.0
    
    var myGrid = Grid(0,0)
    
    override func draw(_ rect: CGRect) {
        let gridSize = CGFloat(self.size)  // gridSize is the CGFloat version of Int 'size'.
        
        // Calculates the width and height of sub-rectangles, i.e., individual cells in the grid.
        let subRectSize = CGSize(
            width: rect.size.width / gridSize,
            height: rect.size.height / gridSize
        )
        
        // Draws circles in the sub-rectangles.
        let base = rect.origin
        (0 ..< size).forEach { i in
            (0 ..< size).forEach { j in
                let origin = CGPoint(
                    x: base.x + (CGFloat(j) * subRectSize.width),
                    y: base.y + (CGFloat(i) * subRectSize.height)
                )
                let subRect = CGRect(
                    origin: origin,
                    size: subRectSize
                )
                /* // If we just want to clearly see all alive cells, uncomment this block instead.
                if myGrid[(i,j)].isAlive {
                    let path = UIBezierPath(ovalIn: subRect)
                    livingColor.setFill()
                    path.fill()
                }
                */
                let path = UIBezierPath(ovalIn: subRect)  // Creates path based on subRect
                switch myGrid[(i,j)].description() {  // Sets fill color of circle for this subRect based on cell status.
                case "alive":
                    livingColor.setFill()
                case "empty":
                    emptyColor.setFill()
                case "born":
                    bornColor.setFill()
                case "died":
                    diedColor.setFill()
                default:
                    emptyColor.setFill()
                }
                path.fill() // Fills cell with circle of appropriate color.
            }
        }
        
        //create the lines
        (0 ..< size+1 ).forEach {
            drawLine(
                start: CGPoint(x: CGFloat($0)/gridSize * rect.size.width, y: 0.0),
                end:   CGPoint(x: CGFloat($0)/gridSize * rect.size.width, y: rect.size.height)
            )
            
            drawLine(
                start: CGPoint(x: 0.0, y: CGFloat($0)/gridSize * rect.size.height ),
                end: CGPoint(x: rect.size.width, y: CGFloat($0)/gridSize * rect.size.height)
            )
        }
    }
    
    func drawLine(start:CGPoint, end: CGPoint) {
        let path = UIBezierPath()
        
        //set the path's line width to the height of the stroke
        path.lineWidth = gridWidth
        
        //move the initial point of the path
        //to the start of the horizontal stroke
        path.move(to: start)
        
        //add a point to the path at the end of the stroke
        path.addLine(to: end)
        
        //set the line stroke's color to gridColor
        gridColor.setStroke()
        
        //draw the stroke
        path.stroke()
    }
    
    // Touch Handling
    var lastTouchedPosition: Position?
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchedPosition = process(touches: touches)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchedPosition = process(touches: touches)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchedPosition = nil
    }
    
    typealias Position = (row: Int, col: Int)
    func process(touches: Set<UITouch>) -> Position? {
        guard touches.count == 1 else { return nil }
        let position = convert(touch: touches.first!)
        guard lastTouchedPosition?.row != position.row || lastTouchedPosition?.col != position.col
            else { return position }
        //myGrid[position] = myGrid[position].isAlive ? .empty : .alive
        myGrid[position] = CellState.toggle(value: myGrid[position])
        setNeedsDisplay()
        return position
    }
    
    func convert(touch: UITouch) -> Position {
        let touchY = touch.location(in: self).y
        let gridHeight = frame.size.height
        let row = touchY / gridHeight * CGFloat(self.size)
        
        let touchX = touch.location(in: self).x
        let gridWidth = frame.size.width
        let col = touchX / gridWidth * CGFloat(self.size)
        
        return (row: Int(row), col: Int(col))
    }
    
}
