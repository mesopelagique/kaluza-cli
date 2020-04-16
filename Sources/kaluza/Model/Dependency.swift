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
