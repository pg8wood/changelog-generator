//
//  LogCommandTests.swift
//  
//
//  Created by Patrick Gatewood on 2/23/21.
//

import XCTest
import TSCBasic
import ArgumentParser
@testable import ChangelogCore

class LogCommandTests: XCTestCase {
    var mockDiskWriter = MockDiskWriter()
    var mockPrompt = MockPrompt<Confirmation>()
    var mockFileManager = MockFileManager()
    
    override func setUp() {
        super.setUp()
        mockDiskWriter = MockDiskWriter()
        mockFileManager = MockFileManager()
        mockPrompt = MockPrompt<Confirmation>()
    }
    
    func test_givenChangelogDirectoryDoesNotExist_whenPromptIsConfirmed_thenCreateChangelogDirectory() throws {
        mockPrompt.mockPromptResponse = try Confirmation.parse(["y"])
        
        mockFileManager.fileExistsHook = { _ in false }
        let expectation = expectation(description: "Directory should not be created")
        mockFileManager.createDirectoryHook = { _, _, _ in
            expectation.fulfill()
        }
        
        var logCommand = Log(
            diskWriter: mockDiskWriter,
            fileManager: mockFileManager,
            prompt: mockPrompt
        )
        
        try logCommand.run()
        
        waitForExpectations(timeout: 0.1)
    }
    
    func test_givenChangelogDirectoryDoesNotExist_whenPromptIsDenied_thenDoNotCreateChangelogDirectory() throws {
        mockPrompt.mockPromptResponse = try Confirmation.parse(["n"])
        mockFileManager.fileExistsHook = { _ in false }
        
        var logCommand = Log(
            diskWriter: mockDiskWriter,
            fileManager: mockFileManager,
            prompt: mockPrompt
        )
        
        XCTAssertThrowsError(try logCommand.run())
    }
    
    func test_givenChangelogDirectoryExists_thenDoNotCreateChangelogDirectory() throws {
        mockPrompt.mockPromptResponse = try Confirmation.parse(["y"])
        mockFileManager.fileExistsHook = { _ in true }
        
        let expectation = expectation(description: "Directory should not be created (because it already exists!)")
        expectation.isInverted = true
        mockFileManager.createDirectoryHook = { _, _, _ in
            expectation.fulfill()
        }
        
        var logCommand = Log(
            diskWriter: mockDiskWriter,
            fileManager: mockFileManager,
            prompt: mockPrompt
        )
        
        try logCommand.run()
        
        waitForExpectations(timeout: 0.1)
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

/// https://github.com/apple/swift-argument-parser/issues/359#issuecomment-991336822
private extension Log {
    init(
        diskWriter: DiskWriting,
        fileManager: FileManaging,
        prompt: PromptProtocol
    ) {
        self.init()
        self.diskWriter = diskWriter
        self.fileManager = fileManager
        self.prompt = prompt
        entryType = .add
        text = ["not used in this test but must be initialized to satisfy the ArgumentParser"]
        options = Changelog.Options(unreleasedChangelogsDirectory: Changelog.Options.defaultUnreleasedChangelogDirectory)
    }
}
