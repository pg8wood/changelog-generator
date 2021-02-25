//
//  Log.swift
//  changelog-generator
//
//  Created by Patrick Gatewood on 2/23/21.
//

import Foundation
import ArgumentParser

public struct Log: ParsableCommand {
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
                "A list of strings separated by spaces to be recorded as a bulleted changelog entry.",
                discussion: "If <text> is supplied, the --editor option is ignored and the changelog entry is created for you without opening an interactive text editor."))
    var text: [String] = []
    
    var unreleasedChangelogsDirectory: URL {
        options.unreleasedChangelogsDirectory
    }
    var fileManager: FileManager = .default
    
    enum CodingKeys: String, CodingKey {
        case options, entryType, editor, text
    }
    
    public init() {}
    
    public func run() throws {
        if text.isEmpty {
            try openEditor(editor, for: entryType)
        } else {
            try createEntry(with: text)
        }
    }
    
    private func createEntry(with text: [String]) throws {
        let bulletedEntryText = text.map { entry in
            "- \(entry)"
        }.joined(separator: "\n")
        
        try write(entryText: bulletedEntryText)
    }
    
    private func openEditor(_ editor: String, for entryType: EntryType) throws {
        let temporaryFilePath = createUniqueChangelogFilepath()
        let hint = "<!-- Enter your changelog message below this line exactly how you want it to appear in the changelog. Lines surrounded in markdown (HTML) comments will be ignored.-->"
        
        try Data(hint.utf8)
            .write(to: temporaryFilePath)
        
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
        let entry = ChangelogEntry(type: entryType, text: entryText)
        let uniqueFilepath = createUniqueChangelogFilepath()
        let data = try JSONEncoder().encode(entry)
        try data.write(to: uniqueFilepath)
        
        let filePathString = OutputController.tryWrap(uniqueFilepath.relativePath, inColor: .white, bold: true)
        let successString = OutputController.tryWrap("🙌 Created changelog entry at \(filePathString)", inColor: .green, bold: true)
                
        OutputController.write(
            """

            ### \(entryType.title)
            \(entry.text)

            \(successString)
            """, inColor: .cyan)
    }
    
    private func createUniqueChangelogFilepath() -> URL {
        options.unreleasedChangelogsDirectory
            .appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString)
            .appendingPathExtension("md")
    }
}
