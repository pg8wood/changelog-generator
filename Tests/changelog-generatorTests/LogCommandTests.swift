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

class LogCommandTests: XCTestCase {
    func test_givenNoChangelogDirectory_thenLogThrowsError() {
        var logCommand = Log()
        logCommand.entryType = .change
        logCommand.text = ["Test entry"]
        
        XCTAssertThrowsError(try logCommand.run()) { error in
            XCTAssertEqual((error as NSError).code, NSFileNoSuchFileError)
        }
    }
    
    func test_givenAdditionOption_whenTextIsValid_thenTextIsWrittenToDisk() {
        let sampleAdditionText = "Added an additive ability to add additions"
        
        var logCommand = Log()
        logCommand.entryType = .addition
        logCommand.text = [sampleAdditionText]
        
        XCTAssertNoThrow(
            try withTemporaryDirectory { directory in
                logCommand.unreleasedChangelogsDirectory = directory.asURL
                try logCommand.run()
                
                let entryFile = try XCTUnwrap(try FileManager.default.contentsOfDirectory(at: directory.asURL, includingPropertiesForKeys: nil).first)
                let entry = try JSONDecoder().decode(
                    ChangelogEntry.self,
                    from: Data(contentsOf: entryFile))
                
                let formattedSampleText = "- \(sampleAdditionText)"
                                
                XCTAssertEqual(entry.type, .addition)
                XCTAssertEqual(entry.text, formattedSampleText)
            }
        )
    }
    
    func test_giveFixOption_whenMultipleEntriesAreProvided_thenBulletedTextIsWrittenToDisk() {
        let sampleFixBullets = ["Fix-it Felix vs.", "Wreck-It Ralph"]
        
//        var logCommand = Log(entryType: .fix, text: sampleFixBullets)
        var logCommand = Log()
        logCommand.entryType = .fix
        logCommand.text = sampleFixBullets
        
        XCTAssertNoThrow(
            try withTemporaryDirectory { directory in
                logCommand.unreleasedChangelogsDirectory = directory.asURL
                try logCommand.run()
                
                let entryFile = try XCTUnwrap(try FileManager.default.contentsOfDirectory(at: directory.asURL, includingPropertiesForKeys: nil).first)
                let entry = try JSONDecoder().decode(
                    ChangelogEntry.self,
                    from: Data(contentsOf: entryFile))
                
                let formattedSampleText =
                    """
                    - \(sampleFixBullets[0])
                    - \(sampleFixBullets[1])
                    """
                
                XCTAssertEqual(entry.type, .fix)
                XCTAssertEqual(entry.text, formattedSampleText)
            }
        )
    }

}
