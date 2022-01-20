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
    func test_givenChangelogDirectoryDoesNotExist_whenPromptIsConfirmed_thenCreateChangelogDirectory() throws {
        var mockPrompt = MockPrompt<Confirmation>()
        mockPrompt.mockPromptResponse = try Confirmation.parse(["y"])
        
        var mockFileManager = MockFileManager()
        mockFileManager.fileExistsHook = { _ in false }
        let expectation = expectation(description: "Directory created")
        mockFileManager.createDirectoryHook = { _, _, _ in
            expectation.fulfill()
        }
        
        var logCommand = Log(fileManager: mockFileManager, prompt: mockPrompt)
        logCommand.entryType = .add
        logCommand.text = ["not used in this test but must be initialized to satisfy the ArgumentParser"]
        logCommand.options = Changelog.Options(unreleasedChangelogsDirectory: Changelog.Options.defaultUnreleasedChangelogDirectory)
        
        // This will swallow other errors thrown by the Log command, but these cases are handled by
        // the rest of the test suite. In the future, String.write() should be wrapped and mocked
        // in order to make this test better
        try? logCommand.run()
        
        waitForExpectations(timeout: 0.1)
    }
    
    func test_givenChangelogDirectoryDoesNotExist_whenPromptIsDenied_thenDoNotCreateChangelogDirectory() throws {
        var mockPrompt = MockPrompt<Confirmation>()
        mockPrompt.mockPromptResponse = try Confirmation.parse(["n"])
        
        var mockFileManager = MockFileManager()
        mockFileManager.fileExistsHook = { _ in false }
        
        let expectation = expectation(description: "Directory should not be created")
        expectation.isInverted = true
        mockFileManager.createDirectoryHook = { _, _, _ in
            expectation.fulfill()
        }
        
        var logCommand = Log(fileManager: mockFileManager, prompt: mockPrompt)
        logCommand.entryType = .add
        logCommand.text = ["not used in this test but must be initialized to satisfy the ArgumentParser"]
        logCommand.options = Changelog.Options(unreleasedChangelogsDirectory: Changelog.Options.defaultUnreleasedChangelogDirectory)
        
        // This will swallow other errors thrown by the Log command, but these cases are handled by
        // the rest of the test suite. In the future, String.write() should be wrapped and mocked
        // in order to make this test better
        try? logCommand.run()
        
        waitForExpectations(timeout: 0.1)
    }
    
    func test_givenChangelogDirectoryExists_thenDoNotCreateChangelogDirectory() throws {
        var mockPrompt = MockPrompt<Confirmation>()
        mockPrompt.mockPromptResponse = try Confirmation.parse(["y"])
        
        var mockFileManager = MockFileManager()
        mockFileManager.fileExistsHook = { _ in true }
        
        let expectation = expectation(description: "Directory should not be created (because it already exists!)")
        expectation.isInverted = true
        mockFileManager.createDirectoryHook = { _, _, _ in
            expectation.fulfill()
        }
        
        var logCommand = Log(fileManager: mockFileManager, prompt: mockPrompt)
        logCommand.entryType = .add
        logCommand.text = ["not used in this test but must be initialized to satisfy the ArgumentParser"]
        logCommand.options = Changelog.Options(unreleasedChangelogsDirectory: Changelog.Options.defaultUnreleasedChangelogDirectory)
        
        // This will swallow other errors thrown by the Log command, but these cases are handled by
        // the rest of the test suite. In the future, String.write() should be wrapped and mocked
        // in order to make this test better
        try? logCommand.run()
        
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
