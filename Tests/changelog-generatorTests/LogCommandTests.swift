//
//  LogCommandTests.swift
//  
//
//  Created by Patrick Gatewood on 2/23/21.
//

import XCTest
import ArgumentParser
@testable import ChangelogCore

class LogCommandTests: ChangelogTestCase {
    func test_givenInvalidArguments_thenThrowValidationError() {
        var logCommand = Log(
            diskWriter: mockDiskWriter,
            fileManager: mockFileManager,
            prompt: mockPrompt
        )
        logCommand.text = ["help"]
        
        do {
            try logCommand.validate()
            XCTFail("Validation error should be thrown")
        } catch {
            switch error {
            case is ValidationError:
                break
            default:
                XCTFail("Wrong error type")
            }
        }
    }
    
    func test_givenChangelogDirectoryDoesNotExist_whenPromptIsConfirmed_thenCreateChangelogDirectory() throws {
        mockPrompt.mockPromptResponse = try Confirmation.parse(["y"])
        
        mockFileManager.fileExistsHook = { _ in false }
        let expectation = expectation(description: "Directory created")
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
        
        let expectation = expectation(description: "Text written to disk matches format")
        mockDiskWriter.writeHook = { text, _ in
            let entry = try ChangelogEntry(text: text)
            XCTAssertEqual(entry.type, .add)
            
            let formattedSampleText = "- \(sampleAdditionText)\n"
            XCTAssertEqual(formattedSampleText, entry.text)
            expectation.fulfill()
        }
        
        var logCommand = Log(
            entryType: .add,
            text: [sampleAdditionText],
            diskWriter: mockDiskWriter,
            fileManager: mockFileManager,
            prompt: mockPrompt
        )
        
        try logCommand.run()
        waitForExpectations(timeout: 0.1)
    }
    
    func test_giveFixOption_whenMultipleEntriesAreProvided_thenBulletedTextIsWrittenToDisk() throws {
        let sampleFixBullets = ["Fix-it Felix vs.", "Wreck-It Ralph"]

        let expectation = expectation(description: "Text written to disk matches format")
        mockDiskWriter.writeHook = { text, _ in
            let entry = try ChangelogEntry(text: text)
            
            let formattedSampleText =
                """
                - \(sampleFixBullets[0])
                - \(sampleFixBullets[1])

                """
            XCTAssertEqual(formattedSampleText, entry.text)
            XCTAssertEqual(entry.type, .fix)
            expectation.fulfill()
        }
        
        var logCommand = Log(
            entryType: .fix,
            text: sampleFixBullets,
            diskWriter: mockDiskWriter,
            fileManager: mockFileManager,
            prompt: mockPrompt
        )
        
        try logCommand.run()
        waitForExpectations(timeout: 0.1)
    }
}

/// https://github.com/apple/swift-argument-parser/issues/359#issuecomment-991336822
private extension Log {
    init(
        entryType: EntryType = .add,
        text: [String] = ["Not used in this test but must be initialized to satisfy the ArgumentParser"],
        diskWriter: DiskWriting,
        fileManager: FileManaging,
        prompt: PromptProtocol,
        options: Changelog.Options = Changelog.Options(unreleasedChangelogsDirectory: Changelog.Options.defaultUnreleasedChangelogDirectory)
    ) {
        self.init()
        self.text = text
        self.entryType = entryType
        self.diskWriter = diskWriter
        self.fileManager = fileManager
        self.prompt = prompt
        self.options = options
    }
}
