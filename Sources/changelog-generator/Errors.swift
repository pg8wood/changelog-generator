//
//  Errors.swift
//  changelog-generator
//
//  Created by Patrick Gatewood on 2/21/21.
//

import Foundation

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
