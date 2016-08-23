//
//  CalculatorBrain.swift
//  Calculator
//
//  Created by Kyralesov on 19.08.16.
//  Copyright © 2016 Kyralesov. All rights reserved.
//

import Foundation

class CalculatorBrain {
    
    private var accumulator = 0.0
    
    private var currentPrecedence = Int.max
    
    private var descriptionAccumulator = "0" {
        didSet {
            if pending == nil {
                currentPrecedence = Int.max
            }
        }
    }
    
    var result: Double {
        return accumulator
    }
    
    var isPartialResult: Bool {
        return pending != nil
    }
    
    var description: String {
        get {
            if pending == nil {
                return descriptionAccumulator
            } else {
                return pending!.descriptionFunction(pending!.descriptionOperand,
                                                    pending!.descriptionOperand != descriptionAccumulator ? descriptionAccumulator : "")
            }
        }
    }
    
    private var operations: Dictionary<String,Operation> = [
        "π" : Operation.constant(M_PI),
        "e" : Operation.constant(M_E),
        "+" : Operation.binary(+, {$0 + " + " + $1}, 0),
        "−" : Operation.binary(-, {$0 + " - " + $1}, 0),
        "×" : Operation.binary(*, {$0 + " × " + $1}, 1),
        "÷" : Operation.binary(/, {$0 + " ÷ " + $1}, 1),
        "±" : Operation.unary({ -$0}, {"-(" + $0 + ")"}),
        "rand" : Operation.nullary(drand48, "rand()"),
        "cos" : Operation.unary(cos, {"cos(" + $0 + ")"}),
        "sin" : Operation.unary(sin, {"sin(" + $0 + ")"}),
        "tan" : Operation.unary(tan, {"tan(" + $0 + ")"}),
        "sin⁻¹" : Operation.unary(asin, {"sin⁻¹(" + $0 + ")"}),
        "cos⁻¹" : Operation.unary(acos, {"cos⁻¹(" + $0 + ")"}),
        "tan⁻¹" : Operation.unary(atan, {"tan⁻¹(" + $0 + ")"}),
        "x⁻¹" : Operation.unary({ 1.0/$0 }, {"(" + $0 + ")⁻¹"}),
        "x²" : Operation.unary({ $0*$0 }, {"(" + $0 + ")²"}),
        "xʸ" : Operation.binary({ pow($0, $1) }, {"(" + $0 + ")^(" + $1 + ")"}, 2),
        "ln" : Operation.unary(log, {"ln(" + $0 + ")"}),
        "√" : Operation.unary(sqrt, {"√(" + $0 + ")"}),
        "=" : Operation.equals
    
    ]
    
    private enum Operation {
        case constant(Double)
        case nullary( () -> Double, String)
        case unary( (Double) -> Double, (String) ->String )
        case binary((Double, Double) -> Double, (String, String) -> String, Int)
        case equals
    }
    
    private var pending: PendingBinaryOperationInfo?
    
    private struct PendingBinaryOperationInfo {
        var binaryFunction: (Double, Double) -> Double
        var firstOperand: Double
        var descriptionFunction: (String , String) -> String
        var descriptionOperand: String
    }
    
    private func executePandingBinaryOperation() {
        if pending != nil {
            accumulator = pending!.binaryFunction(pending!.firstOperand, accumulator)
            descriptionAccumulator = pending!.descriptionFunction(pending!.descriptionOperand, descriptionAccumulator)
            pending = nil
        }
    }
    
    func clear() {
        accumulator = 0.0
        descriptionAccumulator = " "
        currentPrecedence = Int.max
        pending = nil
    }
    
    func setOperand(_ operand: Double) {
        accumulator = operand
        descriptionAccumulator = formatter.string(from: NSNumber(value: accumulator)) ?? ""
        
    }
    
    func performOperation(_ symbol: String) {
        if let operation = operations[symbol] {
            switch operation {
            case .constant(let value):
                accumulator = value
                descriptionAccumulator = symbol
            case .nullary(let function, let descriptionValue):
                accumulator = function()
                descriptionAccumulator = descriptionValue
            case .unary(let function, let descriptionFunction):
                accumulator = function(accumulator)
                descriptionAccumulator = descriptionFunction(descriptionAccumulator)
            case .binary(let function, let descriptionFunction, let precedence):
                executePandingBinaryOperation()
                
                if currentPrecedence < precedence {
                    descriptionAccumulator = "(" + descriptionAccumulator + ")"
                }
                
                currentPrecedence = precedence
                
                pending = PendingBinaryOperationInfo(binaryFunction: function,
                                                     firstOperand: accumulator,
                                                     descriptionFunction: descriptionFunction,
                                                     descriptionOperand: descriptionAccumulator)

            case .equals:
                executePandingBinaryOperation()
            }
        }
    }
}
