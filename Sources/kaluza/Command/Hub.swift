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
    static let configuration = CommandConfiguration(abstract: "Github information", subcommands: [Info.self, Login.self, Open.self, Push.self], defaultSubcommand: Info.self)
}

extension Hub {
    struct Info: ParsableCommand {

        static let configuration = CommandConfiguration(abstract: "Provide info about repository on github.")

        @Argument(help: "The GitHub user to connect.")
        var user: String?
        
        @Argument(help: "The GitHub token or password to connect.")
        var token: String?

        func run() throws {
            let component = Component.read(from: componentURL)
            guard let remoteURLString = component?.gitRemote ?? Init.findGitRemote(for: componentURL) else {
                return
            }

            let config = GitHub.Config.with(user: self.user, token: self.token)
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
    
    struct Login: ParsableCommand {
        
        static let configuration = CommandConfiguration(abstract: "Save user and token for other commands.")
        
        @Argument(help: "The GitHub user to connect.")
        var user: String?
        
        @Argument(help: "The GitHub token or password to connect.")
        var token: String?
        
        func run() throws {
            guard let componentURL = Config.url(global: true) else {
                return
            }
            if !FileManager.default.fileExists(atPath: componentURL.absoluteString) {
                Component().write(to: componentURL)
            }
            guard var component = Component.read(from: componentURL) else {
                return
            }
            var hubUser = user
            if user == nil {
                print("Username:")
                if let input = readLine() {
                    hubUser = input
                }
            }
            var hubToken = token
            if hubToken == nil {
                print("Token or password:")
                if let input = readLine() {
                    hubToken = input
                }
            }
            if let hubUser = hubUser {
                component.setConfig(key: "hub.user", value: hubUser)
            }
            if let hubToken = hubToken {
                component.setConfig(key: "hub.token", value: hubToken)
            }
            component.write(to: componentURL)
        }
    }

    struct Push: ParsableCommand {
        
        static let configuration = CommandConfiguration(abstract: "Push project to github.")

        @Flag(name: [.customShort("y"), .long], help: "Automatically respond yes to all interactive questions.")
        var yes: Bool = false
        
        @Argument(help: "The remote name (by default origin if no remote defied).")
        var remote: String = "origin"
        
        @Argument(help: "The GitHub hostname to default to instead of github.com.")
        var host: String = "github.com"

        @Argument(help: "The GitHub user to connect.")
        var user: String?
        
        @Argument(help: "The GitHub token or password to connect.")
        var token: String?

        //--access <public|private>

        func run() throws {
            guard let component = Component.read(from: componentURL) else {
                log(.error, "Please do a kaluza init before.")
                return
            }
            var remoteURLString = component.gitRemote
            
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
                        if remoteLine.contains(self.host), let tab = remoteLine.firstIndex(of: "\t") {
                            remote = String(remoteLine[remoteLine.startIndex..<tab])
                            remoteURLString = String(remoteLine[remoteLine.index(tab, offsetBy: 1)..<remoteLine.lastIndex(of: " ")!])
                            log(.debug, "Remote name for github: \(remote)")
                            break
                        }
                    }  // maybe if no github create even if there is other ?
                }
            }

            // CHECK GITHUB
            let config = GitHub.Config.with(user: self.user, token: self.token)
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

extension GitHub.Config {
    
    static fileprivate func with(user: String?, token: String?) -> GitHub.Config {
        let env = ProcessInfo.processInfo.environment
        var username = user ?? ""
        var token = token ?? ""

        // try with env var
        if username.isEmpty, let user = env["GITHUB_USER"] {
            username = user
        }
        if token.isEmpty, let pass = env["GITHUB_TOKEN"] ?? env["GITHUB_PASSWORD"] {
            token = pass
        }
 
        // try global config from login
        if token.isEmpty || username.isEmpty {
            if let componentURL = Config.url(global: true),
                FileManager.default.fileExists(atPath: componentURL.absoluteString),
                let component = Component.read(from: componentURL) {
                if username.isEmpty {
                    username = component.getConfig(key: "hub.user") as? String ?? ""
                }
                if token.isEmpty {
                    token = component.getConfig(key: "hub.token") as? String ?? ""
                }
            }
        }

        return GitHub.Config(username: username, token: token)
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

    /*public func create(name: String) throws -> EventLoopFuture<Repo?> {
        let message = Repo.Post(name: name)
        return try self.post(path: "/user/repos", post: message)
    }
    
    public func create(name: String, org: String) throws -> EventLoopFuture<Repo?> {
        let message = Repo.Post(name: name, owner: Owner.Post(name: org))
         return try self.post(path: " /orgs/\(org)/repos", post: message)
     }*/

}
/*
extension Repo {
    public struct Post: Codable {
        public internal(set) var name: String
        public internal(set) var owner: Owner.Post?
    }
}

extension Owner {
    public struct Post: Codable {
        public internal(set) var name: String
    }
}
*/
