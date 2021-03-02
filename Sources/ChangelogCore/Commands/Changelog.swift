//
//  Changelog.swift
//  changelog-generator
//
//  Created by Patrick Gatewood on 2/23/21.
//

import ArgumentParser
import Foundation

public struct Changelog: ParsableCommand {
    public static let configuration = CommandConfiguration(
        abstract: "Curbing Cumbersome Changelog Conflicts.",
        discussion: "Creates changelog entries and stores them as single files to avoid merge conflictss in version control. When it's time to release, `changelog publish` collects these files and appends them to your changelog file.",
        subcommands: [Log.self, Publish.self],
        defaultSubcommand: Log.self)
    
    @OptionGroup() var options: Options
    
    public init() { }
}

extension Changelog {
    struct Options: ParsableArguments {
        static var defaultUnreleasedChangelogDirectory: URL = makeDirectoryURL(from: "changelogs/unreleased")
        
        @Option(name: [.customShort("d"), .customLong("directory", withSingleDash: false)],
                help: ArgumentHelp(
                    "A directory where unpublished changelog entries will be written to / read from.",
                    valueName: "path"),
                transform: Options.makeDirectoryURL)
        var unreleasedChangelogsDirectory: URL = defaultUnreleasedChangelogDirectory
        
        // For some reason, the synthesized member-wise initializer doesn't set this property correctly.
        // I suspect the property wrapper is doing some trickery under the hood.
        init(unreleasedChangelogsDirectory: URL) {
            self.unreleasedChangelogsDirectory = unreleasedChangelogsDirectory
        }
        
        // Required by ParsableArguments. All the @Option-wrapped properties are initialized by the ArgumentParser.
        init() { }
        
        private static func makeDirectoryURL(from string: String) -> URL {
            URL(fileURLWithPath: string, isDirectory: true)
        }
    }
}
