//
//  Prompt.swift
//  
//
//  Created by Patrick Gatewood on 1/20/22.
//

import Foundation
import ArgumentParser

protocol PromptProtocol {
    func promptUser<ParsableType: ParsableArguments>(with prompt: String) throws -> ParsableType
}

struct Prompt: PromptProtocol {
    let outputController: OutputControlling
    
    func promptUser<ParsableType: ParsableArguments>(with prompt: String) throws -> ParsableType {
        var userInput: String?
        
        repeat {
            outputController.write(prompt)
            userInput = readLine()
        } while userInput == nil
        
        return try ParsableType.parse([userInput!])
    }
}

struct Confirmation: ParsableArguments {
    @Argument(transform: boolValue) var value: Bool
    
    private static func boolValue(of string: String) throws -> Bool {
        (string as NSString).boolValue
    }
}
