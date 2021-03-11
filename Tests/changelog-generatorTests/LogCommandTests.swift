//
//  LogCommandTests.swift
//  
//
//  Created by Patrick Gatewood on 2/23/21.
//

import XCTest
import TSCBasic
@testable import ChangelogCore

class LogCommandTests: XCTestCase {
    func test_givenNoChangelogDirectory_thenLogThrowsError() {
        var logCommand = Log()
        logCommand.entryType = .change
        logCommand.text = ["Test entry"]
        logCommand.options = Changelog.Options(unreleasedChangelogsDirectory: Changelog.Options.defaultUnreleasedChangelogDirectory)
        
        XCTAssertThrowsError(try logCommand.run()) { error in
            guard let changelogError = error as? ChangelogError,
                  case .changelogDirectoryNotFound(_) = changelogError else {
                XCTFail("Expected ChangelogError.changelogDirectoryNotFound to be thrown")
                return
            }
        }
    }
    
    func test_givenAdditionOption_whenTextIsValid_thenTextIsWrittenToDisk() throws {
        let sampleAdditionText = "Added an additive ability to add additions"
        
        var logCommand = Log()
        logCommand.entryType = .add
        logCommand.text = [sampleAdditionText]
        logCommand.options = Changelog.Options(unreleasedChangelogsDirectory: Changelog.Options.defaultUnreleasedChangelogDirectory)
        
        try withTemporaryDirectory { directory in
            let changelogOptions = Changelog.Options(unreleasedChangelogsDirectory: directory.asURL)
            logCommand.options = changelogOptions
            
            try logCommand.run()
            
            let entryFile = try XCTUnwrap(try FileManager.default.contentsOfDirectory(at: directory.asURL, includingPropertiesForKeys: nil).first)
            let entry = try ChangelogEntry(contentsOf: entryFile)
            
            let formattedSampleText = "- \(sampleAdditionText)\n"
            
            XCTAssertEqual(entry.type, .add)
            XCTAssertEqual(entry.text, formattedSampleText)
        }
    }
    
    func test_giveFixOption_whenMultipleEntriesAreProvided_thenBulletedTextIsWrittenToDisk() throws {
        let sampleFixBullets = ["Fix-it Felix vs.", "Wreck-It Ralph"]
        
        var logCommand = Log()
        logCommand.entryType = .fix
        logCommand.text = sampleFixBullets
        
        try withTemporaryDirectory { directory in
            let changelogOptions = Changelog.Options(unreleasedChangelogsDirectory: directory.asURL)
            logCommand.options = changelogOptions
            
            try logCommand.run()
            
            let entryFile = try XCTUnwrap(try FileManager.default.contentsOfDirectory(at: directory.asURL, includingPropertiesForKeys: nil).first)
            let entry = try ChangelogEntry(contentsOf: entryFile)
            
            let formattedSampleText =
                """
                - \(sampleFixBullets[0])
                - \(sampleFixBullets[1])

                """
            
            XCTAssertEqual(entry.type, .fix)
            XCTAssertEqual(entry.text, formattedSampleText)
        }
    }
    
}
