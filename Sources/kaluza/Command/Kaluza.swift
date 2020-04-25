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
        subcommands: [Init.self, Install.self, Add.self, List.self, Upgrade.self, Klein.self])

    @Flag(name: [.customShort("v"), .long], help: "Show version.")
    var version: Bool

    func run() throws {
        if version {
            log(.info, Version.current)
        } else {
            throw CleanExit.helpRequest()
        }
    }
}

enum KaluzaError: Error {
    case invalid
}
