//
//  PublishCommandTests.swift
//
//
//  Created by Patrick Gatewood on 2/23/21.
//

import XCTest
import class Foundation.Bundle
import TSCBasic
@testable import ChangelogCore

class PublishCommandTests: XCTestCase {
    
    func test_givenNoVersionArgument_thenThrowsError() {
        XCTAssertThrowsError(try Publish().run())
    }
    
    func test_givenValidCommand_whenChangelogDirectoryDoesntExist_thenThrowsError() {
        var publishCommand = Publish()
        publishCommand.version = "42"
        
        XCTAssertThrowsError(try publishCommand.run())
    }
    
    func test_givenValidCommand_whenChangelogDirectoryIsEmpty_thenThrowsError() {
        var publishCommand = Publish()
        publishCommand.version = "42"
        
        XCTAssertNoThrow(try withTemporaryDirectory { directory in
            publishCommand.unreleasedChangelogsDirectory = directory.asURL
            
            XCTAssertThrowsError(try publishCommand.run()) { error in
                XCTAssertEqual(error as? ChangelogError, .noEntriesFound)
            }
        })
    }
    
    func test_givenValidCommand_whenChangelogsExistButNoChangelogFileExists_thenReleaseIsDocumented() {
        XCTAssertNoThrow(try withTemporaryDirectory { directory in
            try recordEntry(in: directory.asURL)
            
            var publishCommand = Publish()
            publishCommand.version = "42"
            publishCommand.releaseDate = Publish.makeDefaultReleaseDateString()
            publishCommand.unreleasedChangelogsDirectory = directory.asURL
            publishCommand.dryRun = false
            publishCommand.changelogFilename = "CHANGELOG.md"
            
            XCTAssertThrowsError(try publishCommand.run()) { error in
                XCTAssertEqual(error as? ChangelogError, .changelogNotFound)
            }
        })
    }
    
    func test_givenValidCommand_whenChangelogsExist_thenReleaseIsDocumented() {
        XCTAssertNoThrow(try withTemporaryDirectory { directory in
            try withTemporaryFile(dir: directory, prefix: "fakeEntry", suffix: "md") { changelogEntryFile in
                let changelogEntry = ChangelogEntry(type: .addition, text: "Added temporarily")
                let changelogEntryData = try JSONEncoder().encode(changelogEntry)
                changelogEntryFile.fileHandle.write(changelogEntryData)
                
                let absoluteChangelogPath = AbsolutePath(FileManager.default.currentDirectoryPath)
                
                try withTemporaryFile(dir: absoluteChangelogPath, prefix: "CHANGELOG", suffix: "md") { changelogFile in
                    var publishCommand = Publish()
                    publishCommand.version = "42"
                    publishCommand.releaseDate = Publish.makeDefaultReleaseDateString()
                    publishCommand.unreleasedChangelogsDirectory = directory.asURL
                    publishCommand.dryRun = false
                    publishCommand.changelogFilename = changelogFile.path.pathString

                    try publishCommand.run()
                }
            }
        })
    }
    
    private func recordEntry(in directory: URL) throws {
        var log = Log()
        log.entryType = .change
        log.text = ["Made some additions"]
        log.unreleasedChangelogsDirectory = directory
        try log.run()
    }
}
