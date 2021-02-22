//
//  main.swift
//  changelog-generator
//
//  Created by Patrick Gatewood on 2/19/21.
//

import Foundation
import ArgumentParser
import TSCBasic

let outTerminalController = TerminalController(stream: stdoutStream)!
let errorTerminalController = TerminalController(stream: stderrStream)!
let unreleasedChangelogsDirectory = URL(fileURLWithPath: "changelogs/unreleased", isDirectory: true)

struct Changelog: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Curbing Cumbersome Changelog Conflicts.",
        subcommands: [Log.self, Publish.self],
        defaultSubcommand: Log.self)
}

struct Log: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Create a new changelog entry.")
    
    @Argument(help: ArgumentHelp(
                "The type of changelog entry to create. ",
                discussion: "Vaid entry types are \(EntryType.allCasesSentenceString).\n"),
                transform: EntryType.init)
    var entryType: EntryType
    
    @Option(name: .shortAndLong,
            help: "A terminal-based text editor executable in your $PATH used to write your changelog entry with more precision than the default bulletted list of changes.")
    var editor: String = "vim"
    
    @Argument(help: ArgumentHelp(
                "A list of strings separated by spaces to be recorded as a bulletted changelog entry.",
                discussion: "If <text> is suplied, the --editor option is ignored and the changelog entry is created for you without opening an interactive text editor."))
    var text: [String] = []
    
    func run() throws {
        if text.isEmpty {
            try openEditor(editor, for: entryType)
        } else {
            try createEntry(with: text)
        }
    }
    
    private func createEntry(with text: [String]) throws {
        let bullettedEntryText = text.map { entry in
            "- \(entry)"
        }.joined(separator: "\n")
        
        try write(entryText: bullettedEntryText)
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
            try FileManager.default.removeItem(at: temporaryFilePath) // TODO use DI file manager
            
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
        
        let filePathString = outTerminalController.wrap(uniqueFilepath.relativePath, inColor: .white, bold: true)
        let successString = outTerminalController.wrap("🙌 Created changelog entry at \(filePathString)", inColor: .green, bold: true)
                
        outTerminalController.write(
            """

            ### \(entryType.title)
            \(entry.text)

            \(successString)
            """, inColor: .cyan)
    }
    
    private func createUniqueChangelogFilepath() -> Foundation.URL {
        
        unreleasedChangelogsDirectory
            .appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString)
            .appendingPathExtension("md")
    }
}

struct Publish: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Collects the changes in \(unreleasedChangelogsDirectory.relativePath) and prepends them to CHANGELOG.md as a new release version.")
    
    @Argument(help: "The version number associated with the changelog entries to be published.")
    var version: String
    
    // TODO: add date
    @Argument(help: "A string representing the date the version was published. Format MM-dd-YYYY.")
    var releaseDate: String = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-YYYY"
        return dateFormatter.string(from: Date())
    }()
    
    @Flag(help: "Prints the changelog entries that would have been appended to CHANGELOG.md and doesn't delete any files in \(unreleasedChangelogsDirectory.relativePath).")
    var dryRun: Bool = false
    
    let fileManager: FileManaging = FileManager.default
    
    enum CodingKeys: String, CodingKey {
        case version, releaseDate, dryRun
    }
    
    func run() throws {
        let decoder = JSONDecoder()
        let changelogFilePaths = try fileManager.contentsOfDirectory(at: unreleasedChangelogsDirectory)
        let uncategorizedEntries = try changelogFilePaths.map {
            try decoder.decode(ChangelogEntry.self, from: Data(contentsOf: $0))
        }
        
        guard !uncategorizedEntries.isEmpty else {
            throw ChangelogError.noEntriesFound
        }
        
        let groupedEntries: [EntryType: [ChangelogEntry]] = Dictionary(grouping: uncategorizedEntries, by: \.type)
        
        printChangelogSummary(groupedEntries: groupedEntries, changelogFilePaths: changelogFilePaths)
        
        if dryRun {
            outTerminalController.write("\n(Dry run) would have deleted \(changelogFilePaths.count) unreleased changelog entries.", inColor: .yellow)
            return
        }
        
        try record(groupedEntries: groupedEntries, changelogFilePaths: changelogFilePaths)
        
        outTerminalController.write("\nNice! CHANGELOG.md was updated. Congrats on the release! 🥳🍻", inColor: .green)
    }
    
    private func printChangelogSummary(groupedEntries: [EntryType: [ChangelogEntry]], changelogFilePaths: [Foundation.URL]) {
        let newChangelogString = groupedEntries.keys.sorted().reduce(into: "", { changelongString, entryType in
            changelongString.append("\n### \(entryType.title)\n")
            
            groupedEntries[entryType]?.forEach { entry in
                changelongString.append("\(entry.text)\n")
            }
        })
        
        outTerminalController.write(
            """

            ## [\(version)] - \(releaseDate)
            \(newChangelogString)
            """, inColor: .cyan)
    }
    
    private func record(groupedEntries: [EntryType: [ChangelogEntry]], changelogFilePaths: [Foundation.URL]) throws {
        guard let changelog = FileHandle(forUpdatingAtPath: "CHANGELOG.md") else {
            throw ChangelogError.changelogNotFound
        }
        
        let oldChangelogData = changelog.readDataToEndOfFile()
        
        try changelog.seek(toOffset: 0)
        
        // TODO need to seek past comments first. Need an anchor or something to denote where our changelog header stops and the
        // actual changelog entries should be start
        let versionHeader = "## [\(version)] - \(releaseDate)"
        changelog.write(Data("\(versionHeader)".utf8))
        
        groupedEntries.keys.sorted().forEach { entryType in
            let header = "\n\n### \(entryType.title)"
            let headerData = Data(header.utf8)
            changelog.write(headerData)
            
            groupedEntries[entryType]?.forEach { entry in
                changelog.write(Data("\n\(entry.text)".utf8))
            }
        }
        
        changelog.write(Data("\n\n".utf8))
        changelog.write(oldChangelogData)
        changelog.closeFile()
        
        try changelogFilePaths.forEach(fileManager.removeItem(at:))
    }
}

Changelog.main()
