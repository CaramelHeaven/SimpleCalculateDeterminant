//
//  ViewController.swift
//  test
//
//  Created by Sergey Fominov on 19/02/2020.
//  Copyright © 2020 Sergey Fominov. All rights reserved.
//

import UIKit

protocol MatrixTestable {
    /// Author
    static var author: String { get }

    /// Matrix constructor
    /// - Parameters:
    ///   - dimension: Matrix size
    ///   - elementConstructor: Closure with input element row and column, which return the element Int64 value
    init(dimension: Int, elementConstructor: (_ column: Int, _ row: Int) -> Int64)

    /// Determinant calculating function
    func determinant() -> Int64
}

class ViewController: UIViewController {
    @IBOutlet private var showMatrixTextView: UITextView!
    @IBOutlet private var resultLabel: UILabel!
    @IBOutlet private var dimensionTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func generateButtonPressed(_ sender: UIButton) {
        guard let number = dimensionTextField.text, let dimension = Int(number) else {
            print("Uncorrect entered number")
            return
        }

        if 3...9 ~= dimension {
            let worker = MyMatrix(dimension: dimension) { (x, y) -> Int64 in
                Int64(arc4random_uniform(UInt32(2 * (x + y))))
            }

            let text = worker.matrix.reduce("") { (result, row) -> String in
                result + row.map { String($0) }.joined(separator: " | ") + "\n"
            }

            self.showMatrixTextView.text = text

            self.resultLabel.text = "Determinant is: \(worker.determinant())"
        } else {
            print("Number is too large")
        }
    }
}

class MyMatrix: MatrixTestable {
    static var author: String { "Fominov Sergey" }

    fileprivate var matrix: [[Int64]]!

    required init(dimension: Int, elementConstructor: (Int, Int) -> Int64) {
        self.matrix = self.fillMatrix(dimension, elementConstructor)
    }

    func determinant() -> Int64 {
        return self.calculateDeterminant(value: self.matrix)
    }

    private func calculateDeterminant(value: [[Int64]]) -> Int64 {
        if let mx = self.calculateThirdRankMatrix(value) {
            return mx
        }
        var (optimalMatrix, optimalIndexRow) = self.findOptimalMatrixAndRowIndex(by: value)

        let retrievedOptimalRowLine = optimalMatrix[optimalIndexRow]
        optimalMatrix.remove(at: optimalIndexRow)

        var sumResult: Int64 = 0
        for columnIndex in retrievedOptimalRowLine.indices {
            let sign = (optimalIndexRow + columnIndex).isMultiple(of: 2) ? 1 : -1
            let value = retrievedOptimalRowLine[columnIndex]

            let newMatrix = optimalMatrix.getLowerRankMatrix(by: columnIndex)
            let subSum = Int64(sign) * value * self.calculateDeterminant(value: newMatrix)

            sumResult += subSum
        }

        return sumResult
    }

    private func findOptimalMatrixAndRowIndex(by matrix: [[Int64]]) -> ([[Int64]], Int) {
        let rightRotateMatrix = matrix.transpose().verticalReflection()

        let arrayOfZerosOnEachRow = matrix.map { $0.filter { $0 == 0 }.count }
        let arrayOfZerosOnEachColumn = rightRotateMatrix.map { $0.filter { $0 == 0 }.count }

        guard let maxRow = arrayOfZerosOnEachRow.max(), let maxColumn = arrayOfZerosOnEachColumn.max() else {
            return (matrix, Int.random(in: 0..<matrix.count))
        }

        if maxColumn == max(maxRow, maxColumn) {
            return (rightRotateMatrix, Int.random(in: 0..<matrix.count))
        }

        return (matrix, Int.random(in: 0..<matrix.count))
    }

    private func calculateThirdRankMatrix(_ matrix: [[Int64]]) -> Int64? {
        guard matrix.count == 3 else { return nil }

        let sumOfEachLeibniz = matrix.enumerated().map { (val) -> Int64 in
            var leibnizSpace = matrix
            leibnizSpace.remove(at: val.offset)

            if val.element[0] == 0 { return 0 }

            return val.element[0] * (leibnizSpace[0][1] * leibnizSpace[1][2] - leibnizSpace[0][2] * leibnizSpace[1][1])
        }

        return sumOfEachLeibniz
            .enumerated()
            .reduce(0, { $1.offset.isMultiple(of: 2) ? $0 + $1.element : $0 - $1.element })
    }

    private func fillMatrix(_ dimension: Int, _ elementConstructor: (Int, Int) -> Int64) -> [[Int64]] {
        var newMatrix = [[Int64]]()

        (0..<dimension).forEach { i in
            var row = [Int64]()
            (0..<dimension).forEach { j in
                row.append(elementConstructor(i, j))
            }
            newMatrix.append(row)
        }
        return newMatrix
    }
}

extension Array where Element == [Int64] {
    func getLowerRankMatrix(by columnIndex: Int) -> [[Int64]] {
        var currentMatrix = self

        for index in currentMatrix.indices {
            currentMatrix[index].remove(at: columnIndex)
        }
        return currentMatrix
    }

    func verticalReflection() -> [[Int64]] {
        let length = self.count
        var newValue = self

        (0..<length / 2).forEach { i in
            (0..<length).forEach { j in
                let temp = newValue[j][i]

                newValue[j][i] = newValue[j][length - (i + 1)]
                newValue[j][length - (i + 1)] = temp
            }
        }

        return newValue
    }

    func transpose() -> [[Int64]] {
        let length = self.count
        var newValue = self

        (0..<length).forEach { i in
            (0..<length).forEach { j in
                newValue[j][i] = self[i][j]
            }
        }

        return newValue
    }
}
