//
//  PublishCommandTests.swift
//
//
//  Created by Patrick Gatewood on 2/23/21.
//

import XCTest
import TSCBasic
@testable import ChangelogCore

class PublishCommandTests: XCTestCase {
    func test_givenNoVersionArgument_thenThrowsError() {
        var publishCommand = Publish.makeCommandWithFakeCommandLineArguments()
        publishCommand.version = ""
        publishCommand.options = Changelog.Options(unreleasedChangelogsDirectory: Changelog.Options.defaultUnreleasedChangelogDirectory)
        
        XCTAssertThrowsError(try publishCommand.run())
    }
    
    func test_givenValidCommand_whenChangelogDirectoryDoesntExist_thenThrowsError() {
        var publishCommand = Publish.makeCommandWithFakeCommandLineArguments()
        publishCommand.version = "42"
        publishCommand.options = Changelog.Options(unreleasedChangelogsDirectory: Changelog.Options.defaultUnreleasedChangelogDirectory)
        
        XCTAssertThrowsError(try publishCommand.run())
    }
    
    func test_givenValidCommand_whenChangelogDirectoryIsEmpty_thenThrowsError() throws {
        var publishCommand = Publish()
        publishCommand.version = "42"
        publishCommand.options = Changelog.Options()
        
        try withTemporaryDirectory { directory in
            let changelogOptions = Changelog.Options(unreleasedChangelogsDirectory: directory.asURL)
            publishCommand.options = changelogOptions
            
            XCTAssertThrowsError(try publishCommand.run()) { error in
                XCTAssertEqual(error as? ChangelogError, .noEntriesFound)
            }
        }
    }
    
    func test_givenValidCommand_whenChangelogsExistButNoChangelogFileExists_thenErrorIsThrown() throws {
        try withTemporaryDirectory { directory in
            try withTemporaryChangelogEntry(dir: directory) { _ in
                var publishCommand = Publish.makeCommandWithFakeCommandLineArguments()
                publishCommand.changelogFilename = "FileThatDoesntExist"
                
                let changelogOptions = Changelog.Options(unreleasedChangelogsDirectory: directory.asURL)
                publishCommand.options = changelogOptions
                
                XCTAssertThrowsError(try publishCommand.run()) { error in
                    XCTAssertEqual(error as? ChangelogError, .changelogNotFound)
                }
            }
        }
    }
    
    func test_givenValidCommand_whenChangelogsExist_thenReleaseIsDocumented() throws {
        try withTemporaryDirectory { directory in
            try withTemporaryChangelogEntry(dir: directory) { changelogEntry in
                let absoluteChangelogPath = AbsolutePath(FileManager.default.currentDirectoryPath)
                
                try withTemporaryFile(dir: absoluteChangelogPath, prefix: "CHANGELOG", suffix: "md") { changelogFile in
                    var publishCommand = Publish.makeCommandWithFakeCommandLineArguments()
                    publishCommand.changelogFilename = changelogFile.path.pathString
                    
                    let changelogOptions = Changelog.Options(unreleasedChangelogsDirectory: directory.asURL)
                    publishCommand.options = changelogOptions
                    
                    let entry = try ChangelogEntry(contentsOf: changelogEntry.path.asURL)
                    
                    try publishCommand.run()
                    
                    let publishedChangelogContent = try String(contentsOf: changelogFile.path.asURL)
                    
                    XCTAssertFalse(publishedChangelogContent.isEmpty)
                    XCTAssertTrue(publishedChangelogContent.contains(entry.text))
                }
            }
        }
    }
    
    func test_givenValidCommand_whenChangelogsExist_thenUnreleasedChangelogsAreDeleted() throws {
        try withTemporaryDirectory { directory in
            func fetchUnreleasedChangelogFileCount() throws -> Int {
                try FileManager.default.contentsOfDirectory(atPath: directory.asURL.path).count
            }
            
            try withTemporaryChangelogEntry(dir: directory) { changelogEntry in
                XCTAssertEqual(try fetchUnreleasedChangelogFileCount(), 1)
                let absoluteChangelogPath = AbsolutePath(FileManager.default.currentDirectoryPath)
                
                try withTemporaryFile(dir: absoluteChangelogPath, prefix: "CHANGELOG", suffix: "md") { changelogFile in
                    var publishCommand = Publish.makeCommandWithFakeCommandLineArguments()
                    
                    publishCommand.changelogFilename = changelogFile.path.pathString
                    
                    let changelogOptions = Changelog.Options(unreleasedChangelogsDirectory: directory.asURL)
                    publishCommand.options = changelogOptions
                    
                    try publishCommand.run()
                    
                    XCTAssertEqual(try fetchUnreleasedChangelogFileCount(), 0)
                }
            }
        }
    }
    
    func test_givenValidCommand_whenDryRunFlagIsSupplied_thenNoChangelogsAreDeleted() throws {
        try withTemporaryDirectory { directory in
            func fetchUnreleasedChangelogFileCount() throws -> Int {
                try FileManager.default.contentsOfDirectory(atPath: directory.asURL.path).count
            }
            
            try withTemporaryChangelogEntry(dir: directory) { changelogEntry in
                let absoluteChangelogPath = AbsolutePath(FileManager.default.currentDirectoryPath)
                
                try withTemporaryFile(dir: absoluteChangelogPath, prefix: "CHANGELOG", suffix: "md") { changelogFile in
                    var publishCommand = Publish.makeCommandWithFakeCommandLineArguments()
                    
                    publishCommand.dryRun = true
                    publishCommand.changelogFilename = changelogFile.path.pathString
                    
                    let changelogOptions = Changelog.Options(unreleasedChangelogsDirectory: directory.asURL)
                    publishCommand.options = changelogOptions
                    
                    try publishCommand.run()
                    
                    XCTAssertEqual(try fetchUnreleasedChangelogFileCount(), 1)
                }
            }
        }
    }
    
    func test_givenValidCommand_whenChangelogHeaderExists_thenHeaderIsPrependedToChangelog() throws {
        try withTemporaryDirectory { directory in
            try withTemporaryChangelogEntry(dir: directory) { changelogEntry in
                let absoluteChangelogPath = AbsolutePath(FileManager.default.currentDirectoryPath)
                
                try withTemporaryFile(dir: absoluteChangelogPath, prefix: "CHANGELOG", suffix: "md") { changelogFile in
                    
                    try withTemporaryFile { headerfile in
                        let header =
                            """
                            # Now this is changelogging!
                            ## Here's where the fun begins.
                            """
                        
                        let headerData = Data(header.utf8)
                        headerfile.fileHandle.write(headerData)
                        
                        var publishCommand = Publish.makeCommandWithFakeCommandLineArguments()
                        publishCommand.changelogFilename = changelogFile.path.pathString
                        publishCommand.changelogHeaderFileURL = headerfile.path.asURL
                        
                        let changelogOptions = Changelog.Options(unreleasedChangelogsDirectory: directory.asURL)
                        publishCommand.options = changelogOptions
                        
                        try publishCommand.run()
                        
                        let publishedChangelogContent = try String(contentsOf: changelogFile.path.asURL)
                        
                        XCTAssertTrue(publishedChangelogContent.contains(header))
                    }
                }
            }
        }
    }
    
    private func withTemporaryChangelogEntry(dir directory: AbsolutePath?, _ body: (TemporaryFile) throws -> Void) throws {
        try withTemporaryFile(dir: directory, prefix: "fakeEntry", suffix: "md") { changelogEntryFile in
            let entryContent = """
            ### Added
            - Added temporarily
            """
            
            changelogEntryFile.fileHandle.write(Data(entryContent.utf8))
            
            try body(changelogEntryFile)
        }
    }
}

private extension Publish {
    static func makeCommandWithFakeCommandLineArguments() -> Publish {
        var publish = Publish()
        publish.version = "42"
        publish.releaseDate = Publish.makeDefaultReleaseDateString()
        publish.dryRun = false
        publish.changelogFilename = "CHANGELOG.md"
        publish.changelogHeaderFileURL = URL(fileURLWithPath: "")
        publish.options = Changelog.Options(unreleasedChangelogsDirectory: Changelog.Options.defaultUnreleasedChangelogDirectory)
        return publish
    }
}
