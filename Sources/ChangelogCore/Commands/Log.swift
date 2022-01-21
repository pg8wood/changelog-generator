//
//  Log.swift
//  changelog-generator
//
//  Created by Patrick Gatewood on 2/23/21.
//

import Foundation
import ArgumentParser

struct Log: ParsableCommand {
    public static let configuration = CommandConfiguration(
        abstract: "Create a new changelog entry.")
    
    @OptionGroup var options: Changelog.Options
    
    @Argument(help: ArgumentHelp(
                "The type of changelog entry to create. ",
                discussion: "Valid entry types are \(EntryType.allCasesSentenceString).\n"),
                transform: EntryType.init)
    var entryType: EntryType
    
    @Option(name: .shortAndLong,
            help: "A terminal-based text editor executable in your $PATH used to write your changelog entry with more precision than the default bulleted list of changes.")
    var editor: String = "vim"
    
    @Argument(help: ArgumentHelp(
                "A list of quoted strings separated by spaces to be recorded as a bulleted changelog entry.",
                discussion: "If <text> is supplied, the --editor option is ignored and the changelog entry is created for you without opening an interactive text editor."))
    var text: [String] = []
    
    var unreleasedChangelogsDirectory: URL {
        options.unreleasedChangelogsDirectory
    }
    
    // Due to the way the ArgumentParser initializes its types, we can't easily inject a
    // ParsableCommand's dependencies when this type is initialized by the ArgumentParser. Instead,
    // we can set defaults and change them at runtime if needed. BUT, if we're creating the command
    // ourselves, we can depdencency-inject and enable testability with an extension 🥳
    // See: https://github.com/apple/swift-argument-parser/issues/359#issuecomment-991336822
    var fileManager: FileManaging = FileManager.default
    var diskWriter: DiskWriting = DiskWriter()
    var outputController: OutputControlling = OutputController()
    lazy var prompt: PromptProtocol = Prompt(outputController: outputController)
    
    enum CodingKeys: String, CodingKey {
        case options, entryType, editor, text
    }
    
    func validate() throws {
        guard text.first != "help" else {
            throw ValidationError(#""help" isn't a valid changelog entry. Did you mean `changelog log --help`?"#)
        }
    }
    
    public mutating func run() throws {
        let changelogPath = options.unreleasedChangelogsDirectory.path
        
        if !fileManager.fileExists(atPath: changelogPath) {
            try createChangelogDirectoryIfNeeded(path: changelogPath)
        }
        
        if text.isEmpty {
            try openEditor(editor, for: entryType)
        } else {
            try createEntry(with: text)
        }
    }
    
    private mutating func createChangelogDirectoryIfNeeded(path: String) throws {
        let directoryCreationPrompt = "The `\(path)` directory does not exist. Would you like to create it? [y|N]"
        let userConfirmation: Confirmation = try prompt.promptUser(with: directoryCreationPrompt)
        
        guard userConfirmation.value else {
            throw ChangelogError.changelogDirectoryNotFound(expectedPath: path)
        }
        
        try fileManager.createDirectory(
            at: options.unreleasedChangelogsDirectory,
            withIntermediateDirectories: true, attributes: nil
        )
    }
    
    private func createEntry(with text: [String]) throws {
        let bulletedEntryText = text.map { entry in
            "- \(entry)"
        }.joined(separator: "\n")
        
        try write(entryText: bulletedEntryText)
    }
    
    private func openEditor(_ editor: String, for entryType: EntryType) throws {
        let temporaryFilePath = options.unreleasedChangelogsDirectory
            .appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString)
            .appendingPathExtension("md")
        
        let hint = "<!-- Enter your changelog message below this line exactly how you want it to appear in the changelog. Lines surrounded in markdown (HTML) comments will be ignored.-->"
        try diskWriter.write(hint, toFile: temporaryFilePath.path)
        
        try InteractiveCommandRunner.runCommand("\(editor) \(temporaryFilePath.path)") {
            let handle = try FileHandle(forReadingFrom: temporaryFilePath)
            let fileContents = String(data: handle.readDataToEndOfFile(), encoding: .utf8)
            
            try handle.close()
            try fileManager.removeItem(at: temporaryFilePath)
            
            let uncommentedLines = fileContents?.split(separator: "\n")
                .filter { !$0.hasPrefix("<!--") && !$0.hasSuffix("-->") }
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard let enteredText = uncommentedLines,
                  !enteredText.isEmpty else {
                throw ChangelogError.noTextEntered
            }
            
            try write(entryText: enteredText)
        }
    }
    
    private func write(entryText: String) throws {
        let uniqueFilepath = options.unreleasedChangelogsDirectory
            .appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString)
            .appendingPathExtension("md")
        
        let entry = """
            ### \(entryType.title)
            \(entryText)

            """
        
        try diskWriter.write(entry, toFile: uniqueFilepath.path)
        
        let filePathString = outputController.tryWrap(uniqueFilepath.relativePath, inColor: .white, bold: true)
        let successString = outputController.tryWrap("🙌 Created changelog entry at \(filePathString)", inColor: .green, bold: true)
                
        outputController.write("""

            \(entry)
            \(successString)
            """, inColor: .cyan)
    }
}
