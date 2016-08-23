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
    private var descriptionAccumulator = "0" {
        didSet {
            if pending == nil {
                currentPrecedence = Int.max
            }
        }
    }
    private var currentPrecedence = Int.max
    private var internalProgram = [AnyObject]()
    private var pending: PendingBinaryOperationInfo?
    private var error: String?
    
    private var operations: Dictionary<String,Operation> = [
        "π" : Operation.constant(M_PI),
        "e" : Operation.constant(M_E),
        "+" : Operation.binary(+, {$0 + " + " + $1}, 0, nil),
        "−" : Operation.binary(-, {$0 + " - " + $1}, 0, nil),
        "×" : Operation.binary(*, {$0 + " × " + $1}, 1, nil),
        "÷" : Operation.binary(/, {$0 + " ÷ " + $1}, 1, { $1 == 0.0 ? "Division by zero" : nil }),
        "±" : Operation.unary({ -$0}, {"-(" + $0 + ")"}, nil),
        "rand" : Operation.nullary(drand48, "rand()"),
        "cos" : Operation.unary(cos, {"cos(" + $0 + ")"}, nil),
        "sin" : Operation.unary(sin, {"sin(" + $0 + ")"}, nil),
        "tan" : Operation.unary(tan, {"tan(" + $0 + ")"}, nil),
        "sin⁻¹" : Operation.unary(asin, {"sin⁻¹(" + $0 + ")"}, {($0 < -1.0 || $0 > 1.0) ? "out of -1...1" : nil}),
        "cos⁻¹" : Operation.unary(acos, {"cos⁻¹(" + $0 + ")"}, {($0 < -1.0 || $0 > 1.0) ? "out of -1...1" : nil}),
        "tan⁻¹" : Operation.unary(atan, {"tan⁻¹(" + $0 + ")"}, nil),
        "x⁻¹" : Operation.unary({ 1.0/$0 }, {"(" + $0 + ")⁻¹"}, { $0 == 0.0 ? "Division by zero" : nil }),
        "x²" : Operation.unary({ $0*$0 }, {"(" + $0 + ")²"}, nil),
        "xʸ" : Operation.binary({ pow($0, $1) }, {"(" + $0 + ")^(" + $1 + ")"}, 2, nil),
        "ln" : Operation.unary(log, {"ln(" + $0 + ")"}, {$0 < 0.0 ? "Negative argument" : nil}),
        "√" : Operation.unary(sqrt, {"√(" + $0 + ")"}, {$0 < 0.0 ? "Negative argument" : nil}),
        "=" : Operation.equals
        
    ]
    
    private enum Operation {
        case variable
        case constant(Double)
        case nullary( () -> Double, String)
        case unary( (Double) -> Double, (String) ->String, ((Double) -> String?)? )
        case binary((Double, Double) -> Double, (String, String) -> String, Int, ((Double, Double)->String?)?)
        case equals
    }

    var result: (Double, String?) {
        return (accumulator, error)
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
    var variableValues = [String:Double]() {
        didSet {
            program = internalProgram
        }
    }
    typealias PropertyList = Any
    var program:PropertyList {
        get {
            return internalProgram
        }
        set {
            clear()
            if let arrayOfOpps = newValue as? [AnyObject] {
                for op in arrayOfOpps {
                    if let operand = op as? Double {
                        setOperand(operand)
                    } else if let symbol = op as? String {
                        performOperation(symbol)
                    }
                }
            }
            
        }
    }
    var isPartialResult: Bool {
        return pending != nil
    }

    private struct PendingBinaryOperationInfo {
        var binaryFunction: (Double, Double) -> Double
        var firstOperand: Double
        var descriptionFunction: (String , String) -> String
        var descriptionOperand: String
        
        var validator: ((Double, Double) -> String?)?
    }
    
    private func executePandingBinaryOperation() {
        if pending != nil {
            error = pending!.validator?(pending!.firstOperand, accumulator)
            
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
        internalProgram.removeAll(keepingCapacity: false)
    }
    
    func clearVariables() {
        variableValues = [:]
    }
    
    func undoLast() {
        guard !internalProgram.isEmpty else { clear(); return}
        internalProgram.removeLast()
        program = internalProgram
    }
    
    func setOperand(_ operand: Double) {
        accumulator = operand
        internalProgram.append(operand as AnyObject)
        descriptionAccumulator = formatter.string(from: NSNumber(value: accumulator)) ?? ""
        
    }
    
    func setOperand(_ variable: String) {
        operations[variable] = Operation.variable
        performOperation(variable)
    }
    
    func performOperation(_ symbol: String) {
        
        internalProgram.append(symbol as AnyObject)
        
        if let operation = operations[symbol] {
            switch operation {
            case .variable:
                accumulator = variableValues[symbol] ?? 0
                descriptionAccumulator = symbol
            case .constant(let value):
                accumulator = value
                descriptionAccumulator = symbol
            case .nullary(let function, let descriptionValue):
                accumulator = function()
                descriptionAccumulator = descriptionValue
            case .unary(let function, let descriptionFunction, let validator):
                error = validator?(accumulator)
                accumulator = function(accumulator)
                descriptionAccumulator = descriptionFunction(descriptionAccumulator)
            case .binary(let function, let descriptionFunction, let precedence, let validator):
                executePandingBinaryOperation()
                
                if currentPrecedence < precedence {
                    descriptionAccumulator = "(" + descriptionAccumulator + ")"
                }
                
                currentPrecedence = precedence
                
                pending = PendingBinaryOperationInfo(binaryFunction: function,
                                                     firstOperand: accumulator,
                                                     descriptionFunction: descriptionFunction,
                                                     descriptionOperand: descriptionAccumulator,
                                                     validator: validator)

            case .equals:
                executePandingBinaryOperation()
            }
        }
    }
}
