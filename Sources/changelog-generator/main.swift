//
//  main.swift
//  changelog-generator
//
//  Created by Patrick Gatewood on 2/19/21.
//

import Foundation
//import TSCBasic
//import TSCUtility
import ArgumentParser

struct Changelog: ParsableCommand {
    func run() throws {
        let fileManager: FileManager = .default
        let unreleasedChangelogsPath = "changelog/unreleased"
        let unreleasedChangelogHandles: [FileHandle]
        
        do {
            unreleasedChangelogHandles = try fileManager.contentsOfDirectory(atPath: unreleasedChangelogsPath)
                .compactMap(FileHandle.init(forUpdatingAtPath:))
        } catch {
            Changelog.exit(withError: error)
        }
    }
}

Changelog.main()
