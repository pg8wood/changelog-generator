//
//  Publish.swift
//  changelog-generator
//
//  Created by Patrick Gatewood on 2/23/21.
//

import Foundation
import ArgumentParser

struct Publish: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Collects the changes in \(Changelog.Options.defaultUnreleasedChangelogDirectory.relativePath) and prepends them to the CHANGELOG as a new release version.")
    
    static func makeDefaultReleaseDateString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-YYYY"
        return dateFormatter.string(from: Date())
    }
    
    @OptionGroup var options: Changelog.Options
    
    @Argument(help: "The version number associated with the changelog entries to be published.")
    var version: String
    
    @Argument(help: "A string representing the date the version was published. Format MM-dd-YYYY.")
    var releaseDate: String = Publish.makeDefaultReleaseDateString()
    
    @Flag(help: "Prints the changelog entries that would have been appended to the CHANGELOG and doesn't delete any files in \(Changelog.Options.defaultUnreleasedChangelogDirectory.relativePath).")
    var dryRun: Bool = false
    
    @Option(help: "The CHANGELOG file to which the unreleased changelog entries will be prepended.")
    var changelogFilename: String = "CHANGELOG.md"
    
    @Option(name: [.customShort("h"), .customLong("header", withSingleDash: false)],
            help: ArgumentHelp(
                "A Markdown file containing optional header text that will be prepended to your changelog.",
                discussion: "If the supplied file does not exist or is not readable, no text will be prepended to the changelog.",
                valueName: "path"),
            transform: URL.init(fileURLWithPath:))
    var changelogHeaderFileURL: URL = URL(fileURLWithPath: "changelogs/header.md")
    
    var unreleasedChangelogsDirectory: URL {
        options.unreleasedChangelogsDirectory
    }
    
    private var fileManager: FileManager = .default
    
    enum CodingKeys: String, CodingKey {
        case options, version, releaseDate, dryRun, changelogFilename, changelogHeaderFile
    }
    
    func run() throws {
        let decoder = JSONDecoder()
        let changelogFilePaths = try fileManager.contentsOfDirectory(at: unreleasedChangelogsDirectory, includingPropertiesForKeys: nil)
        let uncategorizedEntries = try changelogFilePaths.map {
            try decoder.decode(ChangelogEntry.self, from: Data(contentsOf: $0))
        }
        
        guard !uncategorizedEntries.isEmpty else {
            throw ChangelogError.noEntriesFound
        }
        
        let groupedEntries: [EntryType: [ChangelogEntry]] = Dictionary(grouping: uncategorizedEntries, by: \.type)
        
        printChangelogSummary(groupedEntries: groupedEntries, changelogFilePaths: changelogFilePaths)
        
        if dryRun {
            OutputController.write("\n(Dry run) would have deleted \(changelogFilePaths.count) unreleased changelog entries.", inColor: .yellow)
            return
        }
        
        try record(groupedEntries: groupedEntries, changelogFilePaths: changelogFilePaths)
        
        OutputController.write("\nNice! \(changelogFilename) was updated. Congrats on the release! 🥳🍻", inColor: .green)
    }
    
    private func printChangelogSummary(groupedEntries: [EntryType: [ChangelogEntry]], changelogFilePaths: [URL]) {
        let newChangelogString = groupedEntries.keys.sorted().reduce(into: "", { changelongString, entryType in
            changelongString.append("\n### \(entryType.title)\n")
            
            groupedEntries[entryType]?.forEach { entry in
                changelongString.append("\(entry.text)\n")
            }
        })
        
        OutputController.write(
            """

            ## [\(version)] - \(releaseDate)
            \(newChangelogString)
            """, inColor: .cyan)
    }
    
    private func record(groupedEntries: [EntryType: [ChangelogEntry]], changelogFilePaths: [URL]) throws {
        guard let changelog = FileHandle(forUpdatingAtPath: changelogFilename) else {
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
