//
//  MockPrompt.swift
//  
//
//  Created by Patrick Gatewood on 1/20/22.
//

import ArgumentParser
@testable import ChangelogCore
import XCTest

struct MockPrompt<ParsableType: ParsableArguments>: PromptProtocol {
    var mockPromptResponse: ParsableType?
    
    func promptUser<ParsableType: ParsableArguments>(with prompt: String) throws -> ParsableType {
        let response = mockPromptResponse as? ParsableType
        return try XCTUnwrap(response)
    }
}
