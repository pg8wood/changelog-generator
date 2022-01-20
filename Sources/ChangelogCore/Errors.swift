//
//  Errors.swift
//  changelog-generator
//
//  Created by Patrick Gatewood on 2/21/21.
//

import Foundation

enum ChangelogError: LocalizedError, Equatable {
    case malformattedEntry(atPath: String)
    case noEntriesFound
    case noTextEntered
    case changelogNotFound
    case changelogReleaseAnchorNotFound
    
    var errorDescription: String? {
        switch self {
        case .malformattedEntry(let path):
            return "The changelog entry at \(path) is malformatted. Please fix or remove the file and try again."
        case .noEntriesFound:
            return "No unreleased changelog entries were found."
        case .noTextEntered:
            return "The changelog entry was empty."
        case .changelogNotFound:
            return "Couldn't find the changelog."
        case .changelogReleaseAnchorNotFound:
            // TODO: make bug report issue template and ask user to report the bug.
            return #"The changelog did not contain a release anchor. This is necessary for the changelog parser to collect your past entries. Please add `\#(Publish.latestReleaseAnchor)` to the line before your latest changelog release."#
        }
    }
}
