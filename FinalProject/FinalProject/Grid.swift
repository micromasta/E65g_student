//
//  Grid.swift
//
import Foundation

public typealias GridPosition = (row: Int, col: Int)
public typealias GridSize = (rows: Int, cols: Int)

fileprivate func norm(_ val: Int, to size: Int) -> Int { return ((val % size) + size) % size }

public enum CellState {
    case alive, empty, born, died
    
    public var isAlive: Bool {
        switch self {
        case .alive, .born: return true
        default: return false
        }
    }
    
    public func description() -> CellState {
        return self
    }
}

public protocol GridProtocol {
    init(_ rows: Int, _ cols: Int, cellInitializer: (GridPosition) -> CellState)
    var description: String { get }
    var size: GridSize { get }
    subscript (row: Int, col: Int) -> CellState { get set }
    func next() -> Self 
}

public let lazyPositions = { (size: GridSize) in
    return (0 ..< size.rows)
        .lazy
        .map { zip( [Int](repeating: $0, count: size.cols) , 0 ..< size.cols ) }
        .flatMap { $0 }
        .map { GridPosition($0) }
}


let offsets: [GridPosition] = [
    (row: -1, col:  -1), (row: -1, col:  0), (row: -1, col:  1),
    (row:  0, col:  -1),                     (row:  0, col:  1),
    (row:  1, col:  -1), (row:  1, col:  0), (row:  1, col:  1)
]

extension GridProtocol {
    public var description: String {
        return lazyPositions(self.size)
            .map { (self[$0.row, $0.col].isAlive ? "*" : " ") + ($0.col == self.size.cols - 1 ? "\n" : "") }
            .joined()
    }
    
    private func neighborStates(of pos: GridPosition) -> [CellState] {
        return offsets.map { self[pos.row + $0.row, pos.col + $0.col] }
    }
    
    private func nextState(of pos: GridPosition) -> CellState {
        let iAmAlive = self[pos.row, pos.col].isAlive
        let numLivingNeighbors = neighborStates(of: pos).filter({ $0.isAlive }).count
        switch numLivingNeighbors {
        case 2 where iAmAlive,
             3: return iAmAlive ? .alive : .born
        default: return iAmAlive ? .died  : .empty
        }
    }
    
    public func next() -> Self {
        var nextGrid = Self(size.rows, size.cols) { _, _ in .empty }
        lazyPositions(self.size).forEach { nextGrid[$0.row, $0.col] = self.nextState(of: $0) }
        return nextGrid
    }
}

public struct Grid: GridProtocol {
    private var _cells: [[CellState]]
    public let size: GridSize

    public subscript (row: Int, col: Int) -> CellState {
        get { return _cells[norm(row, to: size.rows)][norm(col, to: size.cols)] }
        set { _cells[norm(row, to: size.rows)][norm(col, to: size.cols)] = newValue }
    }
    
    public init(_ rows: Int, _ cols: Int, cellInitializer: (GridPosition) -> CellState = { _, _ in .empty }) {
        _cells = [[CellState]](repeatElement( [CellState](repeatElement(.empty, count: rows)), count: cols))
        size = GridSize(rows, cols)
        lazyPositions(self.size).forEach { self[$0.row, $0.col] = cellInitializer($0) }
    }
}

extension Grid: Sequence {
    fileprivate var living: [GridPosition] {
        return lazyPositions(self.size).filter { return  self[$0.row, $0.col].isAlive   }
    }
    
    public struct GridIterator: IteratorProtocol {
        private class GridHistory: Equatable {
            let positions: [GridPosition]
            let previous:  GridHistory?
            
            static func == (lhs: GridHistory, rhs: GridHistory) -> Bool {
                return lhs.positions.elementsEqual(rhs.positions, by: ==)
            }
            
            init(_ positions: [GridPosition], _ previous: GridHistory? = nil) {
                self.positions = positions
                self.previous = previous
            }
            
            var hasCycle: Bool {
                var prev = previous
                while prev != nil {
                    if self == prev { return true }
                    prev = prev!.previous
                }
                return false
            }
        }
        
        private var grid: GridProtocol
        private var history: GridHistory!
        
        init(grid: Grid) {
            self.grid = grid
            self.history = GridHistory(grid.living)
        }
        
        public mutating func next() -> GridProtocol? {
            if history.hasCycle { return nil }
            let newGrid:Grid = grid.next() as! Grid
            history = GridHistory(newGrid.living, history)
            grid = newGrid
            return grid
        }
    }
    
    public func makeIterator() -> GridIterator { return GridIterator(grid: self) }
}

public extension Grid {
    public static func gliderInitializer(pos: GridPosition) -> CellState {
        switch pos {
        case (0, 1), (1, 2), (2, 0), (2, 1), (2, 2): return .alive
        default: return .empty
        }
    }
}

public protocol GridViewDataSource {
    subscript (row: Int, col: Int) -> CellState { get set }
}

public protocol EngineDelegate {
    func engineDidUpdate(withGrid: GridProtocol)
}

public protocol EngineProtocol {
    var delegate: EngineDelegate? {get set}
    var grid: GridProtocol {get set}
    var refreshRate: Double {get set}
    var refreshTimer: Timer? {get set}
    var rows: Int {get set}
    var cols: Int {get set}
    init(_ rows: Int, _ cols: Int)
    func step() -> GridProtocol
    
}


class StandardEngine : EngineProtocol {
    
    static let engine: StandardEngine = StandardEngine(10, 10)
    
    var delegate: EngineDelegate?
    var grid: GridProtocol
    var rows: Int
    var cols: Int
    
    var refreshTimer: Timer?
    var refreshRate: TimeInterval = 0.0 {
        didSet {
            if refreshRate > 0.0 {
                refreshTimer = Timer.scheduledTimer(
                    withTimeInterval: refreshRate,
                    repeats: true
                ) { (t: Timer) in
                    _ = self.step()
                }
            }
            else {
                refreshTimer?.invalidate()
                refreshTimer = nil
            }
        }
    }
    
    internal required init(_ rows: Int,_ cols: Int) {
        self.grid = Grid(rows, cols, cellInitializer: {_,_ in .empty})
        self.rows = rows
        self.cols = cols
        delegate?.engineDidUpdate(withGrid: grid)
    }
    
    func step() -> GridProtocol {
        let newGrid = grid.next()
        grid = newGrid
        //         updateClosure?(self.grid)
        delegate?.engineDidUpdate(withGrid: grid)
        
        // Notification to all noting Engine has been updated.
        let nc = NotificationCenter.default
        let name = Notification.Name(rawValue: "EngineUpdate")
        let n = Notification(name: name,
                             object: nil,
                             userInfo: ["engine" : self])
        nc.post(n)
        
        return grid
    }
    
    func setGrid(newGrid: GridProtocol) -> Void {
        let newGrid = newGrid
        grid = newGrid
        
        // Delegate update
        delegate?.engineDidUpdate(withGrid: grid)
        
        // Notification to all noting Engine has been updated.
        let nc = NotificationCenter.default
        let name = Notification.Name(rawValue: "EngineUpdate")
        let n = Notification(name: name,
                             object: nil,
                             userInfo: ["engine" : self])
        nc.post(n)
        
    }
    
    // subscript for engine; gets and sets current engine grid.
    public subscript (row: Int, col: Int) -> CellState {
        get { return self.grid[row,col] }
        set { self.grid[row,col] = newValue }
    }
    
    // handles requests to update Engine's grid size.
    public func changeGridSize(_ rows: Int,_ cols: Int) -> Void {
        self.grid = Grid(rows, cols, cellInitializer: {_,_ in .empty})
        self.rows = rows
        self.cols = cols
        delegate?.engineDidUpdate(withGrid: grid)
        
        // Notification to all noting Engine has been updated.
        let nc = NotificationCenter.default
        let name = Notification.Name(rawValue: "EngineUpdate")
        let n = Notification(name: name,
                             object: nil,
                             userInfo: ["engine" : self])
        nc.post(n)
    }
    
    var aliveCellCount: Int = 0
    var bornCellCount: Int = 0
    var deadCellCount: Int = 0
    var emptyCellCount: Int = 0
    
    public func updateCellStatusCounts() -> Void {
        aliveCellCount = 0
        bornCellCount = 0
        deadCellCount = 0
        emptyCellCount = 0
        
        for row in 0..<self.rows {
            for col in 0..<self.cols {
                switch StandardEngine.engine[row,col].description() {
                case .alive:
                    aliveCellCount += 1
                case .born:
                    bornCellCount += 1
                case .died:
                    deadCellCount += 1
                case .empty:
                    emptyCellCount += 1
                }
            }
        }
    }
    
}


class GridConfig {
    var finalProjectURL = "https://dl.dropboxusercontent.com/u/7544475/S65g.json"
    var gridTitles: [String] = []
    var gridConfigurations: [GridProtocol] = []
    
    
    init() {
        gridTitles = []
        gridConfigurations = []
        
        let fetcher = Fetcher()
        fetcher.fetchJSON(url: URL(string:finalProjectURL)!) { (json: Any?, message: String?) in
            guard message == nil else {
                print(message ?? "nil")
                return
            }
            guard let json = json else {
                print("no json")
                return
            }
            print(json)
            
            /*
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
                    //myGridSize = Int(ceil(Double(maxRowColValue/10))) * 10
                    myGridSize = Int(Double(maxRowColValue/10).rounded(.up)) * 10
                } else { // else create new grid roughly the size of maxRowColValue times two.
                    // create new grid roughly the size of maxRowColValue times two.
                    myGridSize = (Int(maxRowColValue/10) * 10) * 2
                }
                
                
                //let myGridSize: Int = (Int(maxRowColValue/10) * 10) * 2
                var myGrid: GridProtocol
                if myGridSize <= 150 {
                    myGrid = Grid(myGridSize, myGridSize, cellInitializer: {_,_ in .empty})
                    
                    // set grid cells to alive where appropriate.
                    for i in 0..<jsonContents.count {
                        let row: Int = jsonContents[i][0]
                        let col: Int = jsonContents[i][1]
                        myGrid[(row,col)] = CellState.alive
                    }
                    
                    // add grid to gridConfigurations Array.
                    self.gridConfigurations.append(myGrid)
                    // add grid configuration title to gridTitles[] array.
                    self.gridTitles.append(jsonTitle)
                }
                
            }
            
            //print (jsonTitle, jsonContents)
            OperationQueue.main.addOperation {
                //self.textView.text = resultString
                var myGrid = Grid(100, 100, cellInitializer: {_,_ in .empty})
                myGrid[1,1] = CellState.alive
            }
            */
        } // End of fetcher
    }
    
}

