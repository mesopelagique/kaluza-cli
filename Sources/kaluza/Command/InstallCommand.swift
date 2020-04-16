//
//  InstallCommand.swift
//  
//
//  Created by phimage on 14/03/2020.
//

import Foundation

struct InstallCommand: Command {

    static func run(args: [String]) {
        guard componentURL.isFileExists else {
            log(.error, "\(componentFileName) does not exists. Please init first.")
            return
        }
        guard var component = Component.read(from: componentURL) else {
            return
        }

        let binary = !args.contains("--skip-bin")
        var dependencies: [Dependency]

        var warnIfInstalled = false
        if args.count > 2 {
            let path = args[2]

            //let isGlobal = args.contains("--global") || args.contains("-g")

            let isDev = args.contains("--save-dev") || args.contains("-S")
            let isOptional = args.contains("--save-optional") || args.contains("-O")
            let type: DependencyType = isDev ? .dev: (isOptional ? .optional : .standard)

            let saveDependencies = !args.contains("--no-save") // Prevents saving to dependencies.
            if saveDependencies {
                dependencies = [component.addCommand(path: path, type: type)]
            } else {
                dependencies = [Dependency(path: path)]
            }
            warnIfInstalled = true // warn only if install one package
        } else {
            dependencies = component.allMandatoryDependencies  // XXX get dependencies according to option like dev or not
        }

        guard !dependencies.isEmpty else {
            log(.error, "No dependencies to install")
            return
        }

        for dependency in dependencies {
            dependency.install(binary: binary, warnIfInstalled: warnIfInstalled)
        }
    }

}

extension Dependency {

    var repository: String {
       return String(self.path.split(separator: "/").last!) // clean, remove !
    }

    var componentsURL: URL {
        let directory = componentURL.deletingLastPathComponent()
        return directory.appendingPathComponent("Components", isDirectory: true)
    }

    fileprivate var isGitRepo: Bool {
        let directory = componentURL.deletingLastPathComponent()
        return directory.appendingPathComponent(".git", isDirectory: true).isFileExists
    }

    var destinationURL: URL {
        let name = self.repository
        if name.lowercased().contains(".4dbase") {
            return componentsURL.appendingPathComponent(name)
        }
        return componentsURL.appendingPathComponent(name).appendingPathExtension("4dbase")
    }

    var isInstalled: Bool {
        return destinationURL.isFileExists
    }

    var githubURL: URL {
        return URL(string: "https://github.com/\(path)")!// clean, remove !
    }
    var gitURL: URL {
        return URL(string: "https://github.com/\(path).git")!// clean, remove !
      }

    var binaryName: String {
        return "\(repository).4DZ"
    }

    func binaryURL(version: String? = nil) -> URL {
        if let version = version {
            return githubURL.appendingPathComponent("/releases/download/\(version)/\(binaryName)")
        }
        return githubURL.appendingPathComponent("/releases/latest/download/\(binaryName)")
    }

    func install(binary: Bool = true, warnIfInstalled: Bool) {
        let destinationURL = self.destinationURL
        if destinationURL.isFileExists {
            log(warnIfInstalled ? .error:.debug, "\(path) already installed as 4dbase")
            return
        }

        var installed = false

        if binary {
            let binaryURL = self.binaryURL(version: version)

            let destinationArchiveURL = componentsURL.appendingPathComponent(self.binaryName)
            if destinationArchiveURL.isFileExists {
                log(warnIfInstalled ? .error:.debug, "\(path) already installed as 4DZ")
                return
            }
            installed = binaryURL.download(to: destinationArchiveURL)
        }

        if !installed {
            let submodule = self.isGitRepo
            let arguments: [String]
            if submodule {
                arguments = ["submodule", "-q", "add", "\(gitURL)", "Components/\(destinationURL.lastPathComponent)"] // must be relative
            } else {
                arguments = ["clone", "-q", "\(gitURL)", "\(destinationURL.path)"]
            }
            do {
                let output = try execute(command: gitPath(), arguments: arguments)
                log(.debug, output)
            } catch {
                log(.error, "\(error)")
            }
        }

    }
}

func gitPath() -> String {
    do {
        var output = try execute(command: "/usr/bin/which", arguments: ["git"])
        output.removeLast() // remove \n
        return output
    } catch {
        log(.error, "\(error)")
    }
    return "git"
}

private func execute(command: String, arguments: [String] = []) throws -> String {
    let process = Process()
    process.launchPath = command
    process.arguments = arguments
    process.currentDirectoryURL = componentURL.deletingLastPathComponent()

    let pipe = Pipe()
    process.standardOutput = pipe
    try process.run()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    let output = String(data: data, encoding: .utf8)
    return output ?? ""
}
