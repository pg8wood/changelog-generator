//
//  LogCommandTests.swift
//  
//
//  Created by Patrick Gatewood on 2/23/21.
//

import XCTest
import class Foundation.Bundle
import TSCBasic
@testable import ChangelogCore

class MockFileManager: FileManaging {
    var contentsOfDirectoryHook: () -> [URL] = {[]}
    var removeItemHook: () throws -> Void = { }
    
    func contentsOfDirectory(at: URL) throws -> [URL] {
        contentsOfDirectoryHook()
    }
    
    func removeItem(at: URL) throws {
        try removeItemHook()
    }
}

class LogCommandTests: XCTestCase {
    var mockFileManager = MockFileManager()
    
    override func setUp() {
        super.setUp()
        mockFileManager = MockFileManager()
    }
    
    func test_givenNoChangelogDirectory_thenLogThrowsError() {
        let logCommand = Log(fileManager: mockFileManager, text: ["Test entry"])
        XCTAssertThrowsError(try logCommand.run()) { error in
            XCTAssertEqual((error as NSError).code, NSFileNoSuchFileError)
        }
    }
    
    func test_givenAdditionOption_whenTextIsValid_thenTextIsWrittenToDisk() {
        let sampleAdditionText = "Test addition"
        
        var logCommand = Log(entryType: .addition, fileManager: mockFileManager, text: [sampleAdditionText])
        
        XCTAssertNoThrow(
            try withTemporaryDirectory { directory in
                logCommand.unreleasedChangelogsDirectory = directory.asURL
                try logCommand.run()
                
                let entryFile = try XCTUnwrap(try FileManager.default.contentsOfDirectory(at: directory.asURL).first)
                let entry = try JSONDecoder().decode(
                    ChangelogEntry.self,
                    from: Data(contentsOf: entryFile))
                
                let formattedSampleText = "- \(sampleAdditionText)"
                                
                XCTAssertEqual(entry.type, .addition)
                XCTAssertEqual(entry.text, formattedSampleText)
            }
        )
    }
}
