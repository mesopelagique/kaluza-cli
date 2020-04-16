//
//  Dependency.swift
//  kaluza
//
//  Created by phimage on 08/03/2020.
//  Copyright © 2020 phimage. All rights reserved.
//

import Foundation

struct Dependency {

    var path: String
    var version: String?

    init(path: String) {
        let split = path.components(separatedBy: "@")
        self.path = split.first!

        if split.count > 1 {
            self.version = split[1]
        }
    }

    init(path: String, version: String?) {
        self.path = path
        self.version = version
    }
}

enum DependencyType: CaseIterable {
    case standard
    case dev
    case optional
}

extension DependencyType {
    var isMandatory: Bool {
        switch self {
        case .optional:
            return false
        default:
            return true
        }
    }
}
