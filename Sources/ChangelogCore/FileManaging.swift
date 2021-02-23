//
//  FileManaging.swift
//  changelog-generator
//
//  Created by Patrick Gatewood on 2/21/21.
//

import Foundation

public protocol FileManaging {
    func contentsOfDirectory(at: URL) throws -> [URL]
    func removeItem(at: Foundation.URL) throws
}

extension FileManager: FileManaging {
    public func contentsOfDirectory(at url: URL) throws -> [URL] {
        try contentsOfDirectory(at: url, includingPropertiesForKeys: [], options: .skipsSubdirectoryDescendants)
    }
}
