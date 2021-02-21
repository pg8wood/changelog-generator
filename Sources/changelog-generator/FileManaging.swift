//
//  FileManaging.swift
//  changelog-generator
//
//  Created by Patrick Gatewood on 2/21/21.
//

import Foundation

protocol FileManaging {
    func contentsOfDirectory(at: URL) throws -> [URL]
    func removeItem(at: Foundation.URL) throws
}

extension FileManager: FileManaging {
    func contentsOfDirectory(at: URL) throws -> [URL] {
        try contentsOfDirectory(at: unreleasedChangelogsDirectory, includingPropertiesForKeys: [], options: .skipsSubdirectoryDescendants)
    }
}
