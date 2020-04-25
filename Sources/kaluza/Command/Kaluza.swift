//
//  File.swift
//  
//
//  Created by phimage on 17/04/2020.
//

import Foundation
import ArgumentParser

struct Kaluza: ParsableCommand {

    static let configuration = CommandConfiguration(
        abstract: "Package manager for 4D.",
        subcommands: [Init.self, Install.self, Add.self, List.self, Klein.self])

    @Flag(name: [.customShort("v"), .long], help: "Show version.")
    var version: Bool

    func validate() throws {
        if !version { // no option show help
            throw CleanExit.helpRequest()
        }
    }

    func run() {
        if version {
            log(.info, Version.current)
        }
    }
}

enum KaluzaError: Error {
    case invalid
}
