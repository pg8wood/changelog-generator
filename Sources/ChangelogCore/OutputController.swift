//
//  OutputController.swift
//  
//
//  Created by Patrick Gatewood on 2/25/21.
//

import Foundation
import TSCBasic

protocol OutputControlling {
    func write(_ text: String, inColor color: TerminalController.Color)
    func tryWrap(_ text: String, inColor color: TerminalController.Color, bold: Bool) -> String
}

extension OutputControlling {
    func write(_ text: String) {
        write(text, inColor: .noColor)
    }
}

struct OutputController: OutputControlling {
    func write(_ text: String, inColor color: TerminalController.Color) {
        guard let outTerminalController = TerminalController(stream: stdoutStream) else {
            print(text)
            return
        }
        
        outTerminalController.write(text, inColor: color)
    }
    
    func tryWrap(_ text: String, inColor color: TerminalController.Color, bold: Bool) -> String {
        guard let outTerminalController = TerminalController(stream: stdoutStream) else {
            return text
        }
        
        return outTerminalController.wrap(text, inColor: color, bold: bold)
    }
}
