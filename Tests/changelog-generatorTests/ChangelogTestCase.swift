//
//  ChangelogTestCase.swift
//  
//
//  Created by Patrick Gatewood on 1/21/22.
//

import XCTest
@testable import ChangelogCore

class ChangelogTestCase: XCTestCase {
    var mockDiskWriter = MockDiskWriter()
    var mockPrompt = MockPrompt<Confirmation>()
    var mockFileManager = MockFileManager()
    
    override func setUp() {
        super.setUp()
        mockDiskWriter = MockDiskWriter()
        mockFileManager = MockFileManager()
        mockPrompt = MockPrompt<Confirmation>()
    }
}
