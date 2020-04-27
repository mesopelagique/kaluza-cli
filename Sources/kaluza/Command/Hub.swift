//
//  Hub.swift
//  
//
//  Created by phimage on 27/04/2020.
//

import Foundation
import ArgumentParser
import GithubAPI

struct Hub: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Github information",
                                                    subcommands: [Info.self, Open.self], defaultSubcommand: Info.self)
}

extension Hub {
    struct Info: ParsableCommand {

        static let configuration = CommandConfiguration(abstract: "Install kaluza component")

        func run() {
            let component = Component.read(from: componentURL)
            guard let remoteURLString = component?.gitRemote ?? Init.findGitRemote(for: componentURL), let remoteURL = URL(string: remoteURLString) else {
                return
            }
            let semaphore = DispatchSemaphore(value: 0)
            RepositoriesAPI().get(url: remoteURL) { (response, error) in
                if let response = response {
                    if let name = response.name {
                        log(.info, "name: \(name)")
                    }
                    if let description = response.descriptionField {
                        log(.info, "description: \(description)")
                    }
                    if let license = response.license?.name {
                        log(.info, "license: \(license)")
                    }
                    if let topics = response.topics {
                        log(.info, "topics: \(topics)")
                    }
                    if let count = response.forksCount {
                        log(.info, "forks: \(count)")
                    }
                    if let count = response.stargazersCount {
                        log(.info, "stargazers: \(count)")
                    }
                    if let count = response.watchersCount {
                        log(.info, "watchers: \(count)")
                    }
                } else if let error = error {
                    log(.error, "\(error)")
                }
                semaphore.signal()
            }
            semaphore.wait()
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

extension RepositoriesAPI {
    public func get(url: URL, completion: @escaping(RepositoryResponse?, Error?) -> Void) {
        let path = "/repos\(url.path.replacingOccurrences(of: ".git", with: ""))"
        self.get(path: path, completion: completion)
    }
}
