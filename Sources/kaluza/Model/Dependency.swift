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
    var resolved: String?

    init(path: String) {
        let split = path.components(separatedBy: "@")
        if path.hasPrefix("git@") { // ignore version for git url
            self.path = path
        } else {
            self.path = split.first!
            if split.count > 1 {
                self.version = split[1]
            }
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

extension Dependency {
    private func usePath() -> Bool {
        return version == nil && !useValues()
    }
    private func useVersion() -> Bool {
        return version != nil && !useValues()
    }
    private func useValues() -> Bool {
        return resolved != nil
    }
    func useVersionOrValues() -> Bool {
        return version != nil || useValues()
    }
    mutating func setValues(_ values: [String: String]) {
        self.version = values["version"]
        self.resolved = values["resolved"]
    }
    var values: Any? {
        if useValues() {
            return ["version": version, "resolved": resolved]
        } else {
            return version
        }
    }
}
