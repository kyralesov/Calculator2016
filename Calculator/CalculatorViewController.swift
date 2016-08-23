//
//  CalculatorViewController.swift
//  Calculator
//
//  Created by Kyralesov on 16.08.16.
//  Copyright © 2016 Kyralesov. All rights reserved.
//

import UIKit

let formatter:NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 6
    formatter.notANumberSymbol = "ERROR"
    formatter.groupingSeparator = " "
    formatter.locale = Locale.current
    return formatter
}()

class CalculatorViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    @IBOutlet private weak var display: UILabel!
    
    @IBOutlet private weak var history: UILabel! {
        didSet {
            history.text = " "
        }
    }
 
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private var userIsInTheMiddleOfTyping = false
    
    private let decimalSeparator = NumberFormatter().decimalSeparator ?? "."
    @IBOutlet private weak var separator: UIButton! {
        didSet {
            separator.setTitle(decimalSeparator, for: .normal)
        }
    }
    
    private var resultValue:(Double, String?) = (0.0, nil) {
        didSet{
            switch resultValue {
            case (_, nil): displayValue = resultValue.0
            case (_, let error):
                display.text = error
                history.text = brain.description + (brain.isPartialResult ? "..." : " =")
                userIsInTheMiddleOfTyping = false
            }
        }
    }
    
    private var displayValue: Double? {
        get {
            if let text = display.text,
                let value = formatter.number(from: text)?.doubleValue {
                return value
            }
            return nil
        }
        set {
            if let value = newValue {
                display.text = formatter.string(from: NSNumber(value: value))
                history.text = brain.description + (brain.isPartialResult ? "..." : " =")
            } else {
                display.text = "0"
                history.text = " "
                userIsInTheMiddleOfTyping = false
            }
        }
    }
    
    
    @IBAction private func touchDigit(_ sender: UIButton) {
        
        let digit = sender.currentTitle!
        
        if userIsInTheMiddleOfTyping {
            let textCurrentInDisplay = display.text!
            
            if  (digit != decimalSeparator) ||
                (textCurrentInDisplay.contains(decimalSeparator) == false) {
                
                display.text = textCurrentInDisplay + digit

            }
            
        } else {
            
            display.text = digit
        }
        
        userIsInTheMiddleOfTyping = true
        
        
    }

    private var brain = CalculatorBrain()
    
    @IBAction private func performOperation(_ sender: UIButton) {
        
        if userIsInTheMiddleOfTyping {
            if let value = displayValue {
                brain.setOperand(value)
            }
            
            userIsInTheMiddleOfTyping = false
        }
        
        if let mathematicalSymbol = sender.currentTitle {
            brain.performOperation(mathematicalSymbol)
        }
        
        resultValue = brain.result
        
        
    }
 
    @IBAction func setM(_ sender: UIButton) {
        userIsInTheMiddleOfTyping = false
        if let title = sender.currentTitle {
            let symbol = String(title.characters.dropFirst())
            
            if let value = displayValue {
                brain.variableValues[symbol] = value
                resultValue = brain.result
            }
        }

    }
    
    @IBAction func pushM(_ sender: UIButton) {
        brain.setOperand(sender.currentTitle!)
        resultValue = brain.result
    }
 
    @IBAction func backspace(_ sender: UIButton) {
        
        if userIsInTheMiddleOfTyping {
            display.text!.remove(at: display.text!.index(before: display.text!.endIndex))
            
            if display.text!.isEmpty {
                userIsInTheMiddleOfTyping = false
                resultValue = brain.result
            }
        } else {
            brain.undoLast()
            resultValue = brain.result
        }
        
    }
    
    @IBAction func clearAll(_ sender: UIButton) {
        brain.clear()
        brain.clearVariables()
        displayValue = nil
        
    }
 
}
