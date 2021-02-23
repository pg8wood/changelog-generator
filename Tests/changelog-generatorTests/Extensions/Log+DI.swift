//
//  File.swift
//  
//
//  Created by Patrick Gatewood on 2/23/21.
//

import Foundation
@testable import ChangelogCore

extension Log {
    init(entryType: EntryType = .addition,
         editor: String = "vim",
         fileManager: FileManaging,
         text: [String] = []) {
        self.init()
        self.entryType = entryType
        self.editor = editor
        self.fileManager = fileManager
        self.text = text
    }
}
