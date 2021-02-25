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
        var publishCommand = Publish()
        publishCommand.options = Changelog.Options(unreleasedChangelogsDirectory: Changelog.Options.defaultUnreleasedChangelogDirectory)
        
        XCTAssertThrowsError(try publishCommand.run())
    }
    
    func test_givenValidCommand_whenChangelogDirectoryDoesntExist_thenThrowsError() {
        var publishCommand = Publish()
        publishCommand.version = "42"
        publishCommand.options = Changelog.Options(unreleasedChangelogsDirectory: Changelog.Options.defaultUnreleasedChangelogDirectory)

        XCTAssertThrowsError(try publishCommand.run())
    }
    
    func test_givenValidCommand_whenChangelogDirectoryIsEmpty_thenThrowsError() {
        var publishCommand = Publish()
        publishCommand.version = "42"
        publishCommand.options = Changelog.Options()
        
        XCTAssertNoThrow(try withTemporaryDirectory { directory in
            let changelogOptions = Changelog.Options(unreleasedChangelogsDirectory: directory.asURL)
            publishCommand.options = changelogOptions
            
            XCTAssertThrowsError(try publishCommand.run()) { error in
                XCTAssertEqual(error as? ChangelogError, .noEntriesFound)
            }
        })
    }
    
    func test_givenValidCommand_whenChangelogsExistButNoChangelogFileExists_thenErrorIsThrown() {
        XCTAssertNoThrow(try withTemporaryDirectory { directory in
            try withTemporaryChangelogEntry(dir: directory) { _ in
                
                var publishCommand = Publish()
                publishCommand.version = "42"
                publishCommand.releaseDate = Publish.makeDefaultReleaseDateString()
                publishCommand.dryRun = false
                publishCommand.changelogFilename = "CHANGELOG.md"
                publishCommand.options = Changelog.Options(unreleasedChangelogsDirectory: Changelog.Options.defaultUnreleasedChangelogDirectory)

                let changelogOptions = Changelog.Options(unreleasedChangelogsDirectory: directory.asURL)
                publishCommand.options = changelogOptions
                
                XCTAssertThrowsError(try publishCommand.run()) { error in
                    XCTAssertEqual(error as? ChangelogError, .changelogNotFound)
                }
            }
        })
    }
    
    func test_givenValidCommand_whenChangelogsExist_thenReleaseIsDocumented() {
        XCTAssertNoThrow(try withTemporaryDirectory { directory in
            try withTemporaryChangelogEntry(dir: directory) { changelogEntry in
                let absoluteChangelogPath = AbsolutePath(FileManager.default.currentDirectoryPath)
                
                try withTemporaryFile(dir: absoluteChangelogPath, prefix: "CHANGELOG", suffix: "md") { changelogFile in
                    var publishCommand = Publish()
                    publishCommand.version = "42"
                    publishCommand.releaseDate = Publish.makeDefaultReleaseDateString()
                    publishCommand.dryRun = false
                    publishCommand.changelogFilename = changelogFile.path.pathString
                    
                    let changelogOptions = Changelog.Options(unreleasedChangelogsDirectory: directory.asURL)
                    publishCommand.options = changelogOptions
                    
                    try publishCommand.run()
                    
                    let changelogEntryContent = try String(contentsOf: changelogFile.path.asURL)
                    let publishedChangelogContent = try String(contentsOf: changelogFile.path.asURL)
                    
                    XCTAssertFalse(publishedChangelogContent.isEmpty)
                    XCTAssertTrue(publishedChangelogContent.contains(changelogEntryContent))
                }
            }
        })
    }
    
    func test_givenValidCommand_whenChangelogsExist_thenUnreleasedChangelogsAreDeleted() {
        XCTAssertNoThrow(try withTemporaryDirectory { directory in
            func fetchUnreleasedChangelogFileCount() throws -> Int {
                try FileManager.default.contentsOfDirectory(atPath: directory.asURL.path).count
            }
            
            try withTemporaryChangelogEntry(dir: directory) { changelogEntry in
                XCTAssertEqual(try fetchUnreleasedChangelogFileCount(), 1)
                let absoluteChangelogPath = AbsolutePath(FileManager.default.currentDirectoryPath)
                
                try withTemporaryFile(dir: absoluteChangelogPath, prefix: "CHANGELOG", suffix: "md") { changelogFile in
                    var publishCommand = Publish()
                    publishCommand.version = "42"
                    publishCommand.releaseDate = Publish.makeDefaultReleaseDateString()
                    publishCommand.dryRun = false
                    publishCommand.changelogFilename = changelogFile.path.pathString
                    
                    let changelogOptions = Changelog.Options(unreleasedChangelogsDirectory: directory.asURL)
                    publishCommand.options = changelogOptions
                    
                    try publishCommand.run()
                    
                    XCTAssertEqual(try fetchUnreleasedChangelogFileCount(), 0)
                }
            }
        })
    }
    
    func test_givenValidCommand_whenDryRunFlagIsSupplied_thenNoChangelogsAreDeleted() {
        XCTAssertNoThrow(try withTemporaryDirectory { directory in
            func fetchUnreleasedChangelogFileCount() throws -> Int {
                try FileManager.default.contentsOfDirectory(atPath: directory.asURL.path).count
            }
            
            try withTemporaryChangelogEntry(dir: directory) { changelogEntry in
                let absoluteChangelogPath = AbsolutePath(FileManager.default.currentDirectoryPath)
                
                try withTemporaryFile(dir: absoluteChangelogPath, prefix: "CHANGELOG", suffix: "md") { changelogFile in
                    var publishCommand = Publish()
                    publishCommand.version = "42"
                    publishCommand.releaseDate = Publish.makeDefaultReleaseDateString()
                    publishCommand.dryRun = true
                    publishCommand.changelogFilename = changelogFile.path.pathString
                    
                    let changelogOptions = Changelog.Options(unreleasedChangelogsDirectory: directory.asURL)
                    publishCommand.options = changelogOptions
                    
                    try publishCommand.run()
                    
                    XCTAssertEqual(try fetchUnreleasedChangelogFileCount(), 1)
                }
            }
        })
    }

    
    private func withTemporaryChangelogEntry(dir directory: AbsolutePath?, _ body: (TemporaryFile) throws -> Void) throws {
        try withTemporaryFile(dir: directory, prefix: "fakeEntry", suffix: "md") { changelogEntryFile in
            let changelogEntry = ChangelogEntry(type: .addition, text: "Added temporarily")
            let changelogEntryData = try JSONEncoder().encode(changelogEntry)
            changelogEntryFile.fileHandle.write(changelogEntryData)
            
            try body(changelogEntryFile)
        }
    }
}
