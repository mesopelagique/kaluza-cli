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
        version: Version.current,
        subcommands: [Init.self, Install.self, Add.self, Uninstall.self, List.self, Upgrade.self, Klein.self, Config.self, Shell.self, Hub.self])

}
