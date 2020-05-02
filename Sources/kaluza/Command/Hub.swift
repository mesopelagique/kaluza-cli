//
//  Hub.swift
//  
//
//  Created by phimage on 27/04/2020.
//

import Foundation
import ArgumentParser
import GitHubKit

struct Hub: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Github information", subcommands: [Info.self, Open.self], defaultSubcommand: Info.self)
}

extension Hub {
    struct Info: ParsableCommand {

        static let configuration = CommandConfiguration(abstract: "Install kaluza component")

        func run() throws {
            let component = Component.read(from: componentURL)
            guard let remoteURLString = component?.gitRemote ?? Init.findGitRemote(for: componentURL) else {
                return
            }

            let config = GitHub.Config(username: "", token: "")
            let github = try GitHub(config)
            defer {
                try? github.syncShutdown()
            }
            let repo = try Repo.query(on: github).get(url: remoteURLString).wait()

            let name = repo.name
            log(.info, "name: \(name)")
            if let description = repo.repoDescription {
                log(.info, "description: \(description)")
            }
            if let license = repo.license?.name {
                log(.info, "license: \(license)")
            }
            if let topics = repo.topics {
                log(.info, "topics: \(topics)")
            }
            if let count = repo.forksCount {
                log(.info, "forks: \(count)")
            }
            if let count = repo.stargazersCount {
                log(.info, "stargazers: \(count)")
            }
            if let count = repo.watchersCount {
                log(.info, "watchers: \(count)")
            }
        }
    }

    struct Open: ParsableCommand {

        static let configuration = CommandConfiguration(abstract: "Install kaluza component")

        func run() throws {
            let component = Component.read(from: componentURL)
            guard let remoteURLString = component?.gitRemote ?? Init.findGitRemote(for: componentURL)else {
                return
            }

            _ = try Bash.execute(commandName: "/usr/bin/open", arguments: [remoteURLString])
        }

    }
}

extension QueryableProperty where QueryableType == Repo {

    /// Get repo detail
    public func get(url: String) throws -> EventLoopFuture<Repo> {
        var path = URL(string: url)?.path ?? "" // TODO returned failed future instead
        if path.hasSuffix(".git") {
            path = String(path[path.startIndex..<path.index(path.endIndex, offsetBy: -4)])
        }
        if path.hasPrefix("/") {
            path = String(path.dropFirst())
        }
        let cuts = path.split(separator: "/")
        return try self.get(org: String(cuts[0]), repo: String(cuts[1]))
    }
}
