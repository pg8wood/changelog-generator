//
//  OutputController.swift
//  
//
//  Created by Patrick Gatewood on 2/25/21.
//

import Foundation
import TSCBasic

enum OutputController {
    static func write(_ text: String, inColor color: TerminalController.Color = .noColor) {
        guard let outTerminalController = TerminalController(stream: stdoutStream) else {
            print(text)
            return
        }
        
        outTerminalController.write(text, inColor: color)
    }
    
    static func tryWrap(_ text: String, inColor color: TerminalController.Color, bold: Bool) -> String {
        guard let outTerminalController = TerminalController(stream: stdoutStream) else {
            return text
        }
        
        return outTerminalController.wrap(text, inColor: color, bold: bold)
    }
}
