//
//  main.swift
//  changelog-generator
//
//  Created by Patrick Gatewood on 2/19/21.
//

import Foundation
import ArgumentParser

// TODO: create this directory if it doesn't exist
let unreleasedChangelogsDirectory = URL(fileURLWithPath: "changelogs/unreleased", isDirectory: true)

struct Changelog: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Curbing Cumbersome Changelog Conflicts.",
        subcommands: [Added.self, Changed.self, Fixed.self, Publish.self])
}

enum EntryType: String, Codable, Comparable, EnumerableFlag {
    static func < (lhs: EntryType, rhs: EntryType) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    case added
    case changed
    case fixed
}

struct ChangelogEntry: Codable {
    let type: EntryType
    let text: String
}

struct Added: Entry {
    static var configuration: CommandConfiguration {
        CommandConfiguration(abstract: "Creates a changelog entry for added functionality.")
    }
    
    @Argument(help: "The changelog entry describing the change.")
    var entryText: String
    
    func run() throws {
        let changelogEntry = ChangelogEntry(type: .added, text: entryText)
        write(entry: changelogEntry)
    }
}

struct Changed: Entry {
    static var configuration: CommandConfiguration {
        CommandConfiguration(abstract: "Creates a changelog entry for a change in functionality.")
    }
    
    @Argument(help: "The changelog entry describing the change.")
    var entryText: String
    
    func run() throws {
        let changelogEntry = ChangelogEntry(type: .changed, text: entryText)
        write(entry: changelogEntry)
    }
}

struct Fixed: Entry {
    static var configuration: CommandConfiguration {
        CommandConfiguration(abstract: "Creates a changelog entry for a bugfix.")
    }
    
    @Argument(help: "The changelog entry describing the change.")
    var entryText: String
    
    func run() throws {
        let changelogEntry = ChangelogEntry(type: .fixed, text: entryText)
        write(entry: changelogEntry)
    }
}

protocol Entry: ParsableCommand {
    func write(entry: ChangelogEntry)
}

extension Entry {
    func write(entry: ChangelogEntry) {
        do {
            let uniqueFilepath = unreleasedChangelogsDirectory.appendingPathComponent(ProcessInfo.processInfo.globallyUniqueString)
            let data = try JSONEncoder().encode(entry)
            try data.write(to: uniqueFilepath)
            print("Created changelog entry at \(uniqueFilepath) 🙌")
        } catch {
            Self.exit(withError: error)
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
            let groupedEntries: [EntryType: [ChangelogEntry]] = Dictionary(grouping: uncategorizedEntries, by: \.type)
            
            guard let changelog = FileHandle(forUpdatingAtPath: "CHANGELOG.md") else {
                // TODO create it
//                exit(1)
                fatalError("Couldn't find the changelog!")
            }
            
            let oldChangelogData = try changelog.readDataToEndOfFile()
            print(String(data: oldChangelogData, encoding: .utf8))
            
            try changelog.seek(toOffset: 0)
            
            // TODO need to seek past comments first. Need an anchor or something to denote where our changelog header stops and the
            // actual changelog entries should be start
            
            let versionHeader = "## [\(version)] - [TODO add date]\n"
            changelog.write(Data(versionHeader.utf8))
            print(versionHeader) // TODO write and log together?
            
            groupedEntries.keys.sorted().forEach { entryType in
                let header = "### \(entryType.rawValue.localizedCapitalized)\n"
                let headerData = Data("\(header)".utf8)
                changelog.write(headerData)
                print(header)
                
                groupedEntries[entryType]?.forEach { entryText in
                    let entry = "- \(entryText.text)"
                    changelog.write(Data("\(entry)\n".utf8))
                    print(entry)
                }
            }
            
            // This just feels a bit bad. See if there's a cleaner way to do it 
            changelog.write(oldChangelogData)
            changelog.closeFile()
            
            print()
            
            try fileManager.contentsOfDirectory(at: unreleasedChangelogsDirectory, includingPropertiesForKeys: [], options: .skipsSubdirectoryDescendants)
                .forEach { url in
                    print("(dry run) would have deleted \(url.lastPathComponent)")
                }
            // TODO enable dry run
//                .forEach(fileManager.removeItem(at:))
        } catch {
            Changelog.exit(withError: error)
        }
    }
}

Changelog.main()
