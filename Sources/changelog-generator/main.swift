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
        subcommands: [Log.self, Publish.self])
}

struct Log: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Create a new changelog entry.")
    
    @Argument(help: "The type of changelog entry to create. Vaid types are addition, change, and fix.")
    var entryType: EntryType
    
    @Option(name: .shortAndLong, help: "A terminal-based text editor executable in your $PATH used to write your changelog entry.")
    var editor: String = "vim"
    
//    @Argument(help: "The changelog entry describing the change.")
//    var entryText: String
    
    func run() throws {
        try openEditor(editor, for: entryType)
    }
    
    func openEditor(_ editor: String, for entryType: EntryType) throws {
        let temporaryFilePath = unreleasedChangelogsDirectory
            .appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString)
//        let data = Data("\(EntryType.added.rawValue)\n-".utf8)
//        try data.write(to: uniqueFilepath)
        
        try InteractiveCommandRunner.runCommand("\(editor) \(temporaryFilePath.path)") {
            let handle = try FileHandle(forReadingFrom: temporaryFilePath)
            let fileContents = String(data: handle.readDataToEndOfFile(), encoding: .utf8)
            // TODO use DI file manager
            try handle.close()
            try FileManager.default.removeItem(at: temporaryFilePath)
            
            guard let enteredText = fileContents,
                  !enteredText.isEmpty else {
                throw ChangelogError.noTextEntered
                //            Added.exit(withError: ChangelogEntryError.noTextEntered)
            }
            
            let changelogEntry = ChangelogEntry(type: entryType, text: enteredText)
            write(entry: changelogEntry)
        }
    }
    
    private func write(entry: ChangelogEntry) {
        do {
            let uniqueFilepath = unreleasedChangelogsDirectory.appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString)
            let data = try JSONEncoder().encode(entry)
            try data.write(to: uniqueFilepath)
            print("Created changelog entry at \(uniqueFilepath) with text: \(entry.text) 🙌")
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
}

struct ChangelogEntry: Codable {
    let type: EntryType
    let text: String
}

enum ChangelogError: Error {
    case noEntriesFound
    case noTextEntered
    
    var localizedDescription: String {
        switch self {
        case .noEntriesFound:
            return "No unreleased changelog entries were found."
        case .noTextEntered:
            return "The changelog entry was empty."
        }
    }
}

// TODO: dry-run option
struct Publish: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Collects the changes in \(unreleasedChangelogsDirectory) and adds them to CHANGELOG.md")
    
    @Argument(help: "The version number associated with the changelog entries to be published.")
    var version: String
    
    // TODO: add date
//    @Argument(help: "The date the version was published.")
    
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
                // TODO create it
//                exit(1)
                fatalError("Couldn't find the changelog!")
            }
            
            let oldChangelogData = changelog.readDataToEndOfFile()
            
            try changelog.seek(toOffset: 0)
            
            // TODO need to seek past comments first. Need an anchor or something to denote where our changelog header stops and the
            // actual changelog entries should be start
            
            let versionHeader = "## [\(version)] - [TODO add date]\n\n"
            changelog.write(Data("\(versionHeader)".utf8))
            print(versionHeader.dropLast()) // TODO write and log together?
            
            groupedEntries.keys.sorted().forEach { entryType in
                let header = "### \(entryType.rawValue.localizedCapitalized)"
                let headerData = Data("\(header)\n".utf8)
                changelog.write(headerData)
                print(header)
                
                groupedEntries[entryType]?.forEach { entry in
                    changelog.write(Data(entry.text.utf8))
                    print(entry.text)
                }
            }
            
            changelog.write(Data("\n".utf8))
            
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
