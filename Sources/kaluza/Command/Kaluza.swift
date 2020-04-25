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
}
