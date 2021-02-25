//
//  Changelog.swift
//  changelog-generator
//
//  Created by Patrick Gatewood on 2/23/21.
//

import ArgumentParser
import Foundation
import TSCBasic

public enum Configuration {
    public static var unreleasedChangelogsDirectory = URL(fileURLWithPath: "changelogs/unreleased", isDirectory: true)
    public static var fileManager = FileManager.default
}

public struct Changelog: ParsableCommand {
    public static let configuration = CommandConfiguration(
        abstract: "Curbing Cumbersome Changelog Conflicts.",
        subcommands: [Log.self, Publish.self],
        defaultSubcommand: Log.self)
    
    public init() { }
}
