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
    static let configuration = CommandConfiguration(abstract: "Github information", subcommands: [Info.self, Open.self, Push.self], defaultSubcommand: Info.self)
}

extension Hub {
    struct Info: ParsableCommand {

        static let configuration = CommandConfiguration(abstract: "Provide info about repository on github.")

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

        static let configuration = CommandConfiguration(abstract: "Open project github url in your default web browser.")

        func run() throws {
            let component = Component.read(from: componentURL)
            guard let remoteURLString = component?.gitRemote ?? Init.findGitRemote(for: componentURL) else {
                return
            }

            _ = try Bash.execute(commandName: "/usr/bin/open", arguments: [remoteURLString])
        }

    }

    struct Push: ParsableCommand {

        static let configuration = CommandConfiguration(abstract: "Open project github url in your default web browser.")

        @Flag(name: [.customShort("y"), .long], help: "Automatically repond yes to all interactive quetion.")
        var yes: Bool = false

        @Argument(help: "The remote name (origin).")
        var remote: String = "origin"

        func run() throws {
            let component = Component.read(from: componentURL)
            var remoteURLString = component?.gitRemote
            
            // CHECK GIT
            if !(try Bash.run(commandName: "git", arguments: ["status"]).isSuccess) {
                if !self.yes {
                    print("Not a git repository yet. Create one? (yes, no)")
                    if let confirm = readLine() {
                        if confirm != "yes" && confirm != "y" && !confirm.isEmpty {
                            print("Aborted")
                            return
                        }
                    }
                    let status = try Bash.execute(commandName: "git", arguments: ["init"])
                    log(.debug, "\(status ?? "")")
                }
            }
            // CHECK GIT file
            // TODO there is no gitignore, no gitattribute, wnt to create ?
            
            // CHECK REMOTE
            var remote = self.remote
            if let remotes = try Bash.execute(commandName: "git", arguments: ["remote", "-v"]) {
                if remotes.isEmpty {
                    if let remoteURLString = remoteURLString {
                        _ = try Bash.execute(commandName: "git", arguments: ["remote", "add", remote, remoteURLString])
                    }
                    // TODO we need to create remote
                } else {
                    // look for github in priority
                    let remoteLines = remotes.split(separator: "\n")
                    for remoteLine in remoteLines {
                        if remoteLine.contains("github.com"), let tab = remoteLine.firstIndex(of: "\t") {
                            remote = String(remoteLine[remoteLine.startIndex..<tab])
                            remoteURLString = String(remoteLine[remoteLine.index(tab, offsetBy: 1)..<remoteLine.lastIndex(of: " ")!])
                            log(.debug, "Remote name for github: \(remote)")
                            break
                        }
                    }  // maybe if no github create even if there is other ?
                }
            }

            // CHECK GITHUB
            let config = GitHub.Config(username: "", token: "")
            let github = try GitHub(config)
            defer {
                try? github.syncShutdown()
            }
            do {
                let repo = try Repo.query(on: github).get(url: remoteURLString!).wait()
                log(.debug, "Remote repo found: \(repo)")
            } catch GitHub.Error.notFound(_) {
                if !self.yes {
                    log(.info, "Remote repository not available. Create it? (yes, no)")
                    if let confirm = readLine() {
                        if confirm != "yes" && confirm != "y" && !confirm.isEmpty {
                            print("Aborted")
                            return
                        }
                    }
                }
                log(.error, "Not yet implemented")
                
            } catch {
                log(.error, "Remote name for github: \(error)")
                print("Aborted")
                return
            }

            // PUSH
            _ = try Bash.execute(commandName: "git", arguments: ["push", remote])
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
