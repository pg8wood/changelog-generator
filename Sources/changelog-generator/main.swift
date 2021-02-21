//
//  main.swift
//  changelog-generator
//
//  Created by Patrick Gatewood on 2/19/21.
//

import Foundation
import ArgumentParser
import TSCUtility

// TODO: TerminalController for enhanced output

// TODO: create this directory if it doesn't exist
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
    
    @Argument(help: "The type of changelog entry to create. Vaid types are addition, change, and fix.")
    var entryType: EntryType
    
    @Option(name: .shortAndLong, help: "A terminal-based text editor executable in your $PATH used to write your changelog entry.")
    var editor: String = "vim"
    
    @Argument(help:
        """
        A list of strings separated by spaces to be recorded as a bulletted changelog entry, skipping the interactive text editor.
        
        If the --text option is suplied, the --editor option is ignored and the changelog entry is created for you.
        """)
    var text: [String] = []
    
    func run() throws {
        if !text.isEmpty {
            let bullettedEntryText = text.map { entry in
                "- \(entry)"
            }.joined(separator: "\n")
            
            write(entryText: bullettedEntryText)
            return
        }
        
        try openEditor(editor, for: entryType)
    }
    
    private func openEditor(_ editor: String, for entryType: EntryType) throws {
        let temporaryFilePath = unreleasedChangelogsDirectory
            .appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString)
            .appendingPathExtension("md")
        let hint = "<!-- Enter your changelog message below this line exactly how you want it to appear in the changelog. Lines surrounded in markdown (HTML) comments will be ignored.-->"
        
        try Data(hint.utf8)
            .write(to: temporaryFilePath)
        
        try InteractiveCommandRunner.runCommand("\(editor) \(temporaryFilePath.path)") {
            let handle = try FileHandle(forUpdating: temporaryFilePath)
            let fileContents = String(data: handle.readDataToEndOfFile(), encoding: .utf8)
            
            try handle.close()
            try FileManager.default.removeItem(at: temporaryFilePath) // TODO use DI file manager
            
            let uncommentedLines = fileContents?.split(separator: "\n")
                .filter { !$0.hasPrefix("<!--") && !$0.hasSuffix("-->") }
                .joined(separator: "\n")
            
            guard let enteredText = uncommentedLines,
                  !enteredText.isEmpty else {
                throw ChangelogError.noTextEntered
            }
            
            write(entryText: enteredText)
        }
    }
    
    private func write(entryText: String) {
        do {
            let entry = ChangelogEntry(type: entryType, text: entryText)
            let uniqueFilepath = unreleasedChangelogsDirectory.appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString)
            let data = try JSONEncoder().encode(entry)
            try data.write(to: uniqueFilepath)
            
            print("""
                  🙌 Created changelog entry at \(uniqueFilepath.relativePath)

                 ### \(entryType.title)
                 \(entry.text)
                 """)
        } catch {
            Self.exit(withError: error)
        }
    }
}

enum EntryType: String, Codable, Comparable, ExpressibleByArgument {
    static func < (lhs: EntryType, rhs: EntryType) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    case addition
    case change
    case fix
    
    var title: String {
        switch self {
        case .addition: return "Added"
        case .change: return "Changed"
        case .fix: return "Fixed"
        }
    }
}

struct ChangelogEntry: Codable {
    let type: EntryType
    let text: String
}

enum ChangelogError: Error {
    case noEntriesFound
    case noTextEntered
    case changelogNotFound
    
    var localizedDescription: String {
        switch self {
        case .noEntriesFound:
            return "No unreleased changelog entries were found."
        case .noTextEntered:
            return "The changelog entry was empty."
        case .changelogNotFound:
            return "Couldn't find the changelog."
        }
    }
}

// TODO: dry-run option
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
    
    func run() throws {
        // TODO: test
        let fileManager: FileManager = .default
        
        do {
            let decoder = JSONDecoder()
            let uncategorizedEntries = try fileManager.contentsOfDirectory(at: unreleasedChangelogsDirectory, includingPropertiesForKeys: [], options: .skipsSubdirectoryDescendants)
                .map {
                    try decoder.decode(ChangelogEntry.self, from: Data(contentsOf: $0))
                }
            
            guard !uncategorizedEntries.isEmpty else {
                throw ChangelogError.noEntriesFound
            }
            
            let groupedEntries: [EntryType: [ChangelogEntry]] = Dictionary(grouping: uncategorizedEntries, by: \.type)
            
            guard let changelog = FileHandle(forUpdatingAtPath: "CHANGELOG.md") else {
                throw ChangelogError.changelogNotFound
            }
            
            let oldChangelogData = changelog.readDataToEndOfFile()
            
            try changelog.seek(toOffset: 0)
            
            // TODO need to seek past comments first. Need an anchor or something to denote where our changelog header stops and the
            // actual changelog entries should be start
            
            let versionHeader = "## [\(version)] - \(releaseDate)"
            changelog.write(Data("\(versionHeader)".utf8))
            print("\n\(versionHeader)") // TODO write and log together?
            
            groupedEntries.keys.sorted().forEach { entryType in
                let header = "\n\n### \(entryType.title)"
                let headerData = Data(header.utf8)
                changelog.write(headerData)
                print(header.dropFirst())
                
                groupedEntries[entryType]?.forEach { entry in
                    changelog.write(Data("\n\(entry.text)".utf8))
                    print(entry.text)
                }
            }
            
            changelog.write(Data("\n\n".utf8))
            
            // This just feels a bit bad. See if there's a cleaner way to do it
            changelog.write(oldChangelogData)
            changelog.closeFile()
            
            try fileManager.contentsOfDirectory(at: unreleasedChangelogsDirectory, includingPropertiesForKeys: [], options: .skipsSubdirectoryDescendants)
                // TODO enable dry run
                
                //                .forEach { url in
                //                    print("(dry run) would have deleted \(url.lastPathComponent)")
                //                }
                .forEach(fileManager.removeItem(at:))
        } catch {
            Changelog.exit(withError: error)
        }
    }
}

Changelog.main()
