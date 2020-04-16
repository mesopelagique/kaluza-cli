//
//  Command.swift
//  kaluza
//
//  Created by phimage on 08/03/2020.
//  Copyright © 2020 phimage. All rights reserved.
//

import Foundation

enum CommandType: String, CaseIterable {
    case `init`
    case add
    case install
}

protocol Command {
    static func run(args: [String])
}

extension CommandType {

    var command: Command.Type {
        switch self {
        case .`init`:
            return InitCommand.self
        case .add:
            return AddCommand.self
        case .install:
            return InstallCommand.self
        }
    }
}
