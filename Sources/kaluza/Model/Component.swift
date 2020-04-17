//
//  Component.swift
//  kaluza
//
//  Created by phimage on 08/03/2020.
//  Copyright © 2020 phimage. All rights reserved.
//

import Foundation

struct Component {

    var name: String?
    var description: String?
    var keywords: [String]?
    var author: String?
    var repository: Repository?

    // dependencies for the component
    var dependencies: [Dependency]?
    // dependencies only useful for developing, not for final distribution
    var devDependencies: [Dependency]?
    // dependencies only useful for plugin
    var optionalDependencies: [Dependency]?
}

extension Component: Codable {

    enum CodingKeys: String, CodingKey {
        case name, description, keywords, author, repository, dependencies, devDependencies, optionalDependencies
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        self.name = try? values.decode(String.self, forKey: .name)
        self.description = try? values.decode(String.self, forKey: .description)
        self.author = try? values.decode(String.self, forKey: .author)
        self.keywords = try? values.decode([String].self, forKey: .keywords)
        self.repository = try? values.decode(Repository.self, forKey: .repository)

        do {
            let strings = try values.decode([String].self, forKey: .dependencies)
            self.dependencies = strings.map { Dependency(path: $0) }
        } catch {
            let map = try? values.decode([String: String?].self, forKey: .dependencies)
            self.dependencies = map?.map { key, value in Dependency(path: key, version: value) }
        }

        do {
            let strings = try values.decode([String].self, forKey: .devDependencies)
            self.devDependencies = strings.map { Dependency(path: $0) }
        } catch {
            let map = try? values.decode([String: String?].self, forKey: .devDependencies)
            self.devDependencies = map?.map { key, value in Dependency(path: key, version: value) }
        }

        do {
            let strings = try values.decode([String].self, forKey: .optionalDependencies)
            self.optionalDependencies = strings.map { Dependency(path: $0) }
        } catch {
            let map = try? values.decode([String: String?].self, forKey: .optionalDependencies)
            self.optionalDependencies = map?.map { key, value in Dependency(path: key, version: value) }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let name = name {
            try container.encode(name, forKey: .name)
        }
        if let description = description {
            try container.encode(description, forKey: .description)
        }
        if let author = author {
            try container.encode(author, forKey: .author)
        }
        if let keywords = keywords {
            try container.encode(keywords, forKey: .keywords)
        }
        if let repository = repository {
            try container.encode(repository, forKey: .repository)
        }
        if let dependencies = self.dependencies {
            if dependencies.filter({ $0.version != nil }).isEmpty {
                try container.encode(dependencies.map { $0.path }, forKey: .dependencies)
            } else {
                try container.encode(Dictionary(uniqueKeysWithValues: dependencies.map { ($0.path, $0.version)}), forKey: .dependencies)
            }
        }
        if let dependencies = self.devDependencies {
            if dependencies.filter({ $0.version != nil }).isEmpty {
                try container.encode(dependencies.map { $0.path }, forKey: .devDependencies)
            } else {
                try container.encode(Dictionary(uniqueKeysWithValues: dependencies.map { ($0.path, $0.version)}), forKey: .devDependencies)
            }
        }
        if let dependencies = self.optionalDependencies {
            if dependencies.filter({ $0.version != nil }).isEmpty {
                try container.encode(dependencies.map { $0.path }, forKey: .optionalDependencies)
            } else {
                try container.encode(Dictionary(uniqueKeysWithValues: dependencies.map { ($0.path, $0.version)}), forKey: .optionalDependencies)
            }
        }
    }

    func dependencies(for type: DependencyType) -> [Dependency] {
        switch type {
        case .standard:
            return self.dependencies ?? []
        case .dev:
            return self.devDependencies ?? []
        case .optional:
            return self.optionalDependencies ?? []
        }
    }

    mutating func setDependencies(_ dependencies: [Dependency]?, for type: DependencyType) {
        switch type {
        case .standard:
            self.dependencies = dependencies
        case .dev:
            self.devDependencies = dependencies
        case .optional:
            self.optionalDependencies = dependencies
        }
    }
}

extension Component {

    var allMandatoryDependencies: [Dependency] {
        var allDependencies: [Dependency] = []
        for type in DependencyType.allCases where type.isMandatory {
            allDependencies += dependencies(for: type)
        }
        return allDependencies
    }

    var allDependencies: [Dependency] {
        var allDependencies: [Dependency] = []
        for type in DependencyType.allCases {
            allDependencies += dependencies(for: type)
        }
        return allDependencies
    }
}

extension Component {
    func write(to url: URL) {
        do {
            try JSONEncoder.component.encode(self).write(to: url)
        } catch {
            log(.error, "\(error)")
        }
    }

    static func read(from url: URL) -> Component? {
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(Component.self, from: data)
        } catch {
            log(.error, "Cannot read \(url.path)")
            log(.error, "\(error)")
            return nil
        }
    }
}

extension Component {

    var gitRemote: String? {
        get {
            return self.repository?.url
        }
        set {
            if let newValue = newValue {
                self.repository = Repository(url: newValue, type: "git")
            } else {
                self.repository = nil
            }
        }
    }
}

struct Repository: Codable {
    var url: String
    var type: String
}
