//
//  InstallCommand.swift
//  
//
//  Created by phimage on 14/03/2020.
//

import Foundation
import ArgumentParser

struct Install: ParsableCommand {

    static let configuration = CommandConfiguration(abstract: "Install dependencies")

    @Flag(help: "Prevents using 4dz binaries.")
    var noBin: Bool
    @Flag(help: "Prevents saving to dependencies.")
    var noSave: Bool

    @Flag(name: [.customShort("D"), .long], help: "Save as dev dependencies.")
    var saveDev: Bool
    @Flag(name: [.customShort("O"), .long], help: "Save as optional dependencies.")
    var saveOptional: Bool

    //@Flag(help: "Install to global storage.")
    //var global: Bool

    @Argument(help: "The dependency path: <orga>/<repo>(@<version).")
    var path: String?

    var dependencyType: DependencyType {
        return saveDev ? .dev: (self.saveOptional ? .optional : .standard)
    }

    func run() {
        guard componentURL.isFileExists else {
            log(.error, "\(componentFileName) does not exists. Please init first.")
            return
        }
        guard var component = Component.read(from: componentURL) else {
            return
        }

        let binary = !noBin
        var dependencies: [Dependency]

        var warnIfInstalled = false
        if let path = path {
            if noSave {
                dependencies = [Dependency(path: path)]
            } else {
                dependencies = [component.addCommand(path: path, type: dependencyType)]
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
        let componentsURL = directory.appendingPathComponent("Components", isDirectory: true)
        if !componentsURL.isFileExists {
            try? FileManager.default.createDirectory(at: componentsURL, withIntermediateDirectories: true, attributes: nil)
        }
        return componentsURL
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

    func binaryName(withResources: Bool, withVersion: String? = nil) -> String {
        if withResources {
            if let version = withVersion {
                return "\(repository).\(version).zip"
            }
            return "\(repository).4dbase.zip"
        }
        return "\(repository).4DZ"
    }

    func binaryURL(version: String? = nil, withResources: Bool, withVersion: String? = nil) -> URL {
        let binaryName = self.binaryName(withResources: withResources, withVersion: withVersion)
        if let version = version {
            return githubURL.appendingPathComponent("/releases/download/\(version)/\(binaryName)")
        }
        return githubURL.appendingPathComponent("/releases/latest/download/\(binaryName)")
    }

    func versionSourceURL(version: String) -> URL {
        return githubURL.appendingPathComponent("/archive/v\(version).zip")
    }

    func install(binary: Bool = true, warnIfInstalled: Bool) {
        let destinationURL = self.destinationURL
        if destinationURL.isFileExists {
            log(warnIfInstalled ? .error:.debug, "\(path) already installed as 4dbase")
            return
        }

        var installed = false

        if binary {
            let binaryURL = self.binaryURL(version: version, withResources: false)
            let destinationArchiveURL = componentsURL.appendingPathComponent(self.binaryName(withResources: false))
            if destinationArchiveURL.isFileExists {
                log(warnIfInstalled ? .error:.debug, "\(path) already installed as 4DZ")
                return
            }
            installed = binaryURL.download(to: destinationArchiveURL)

            if !installed {
                let binaryURL = self.binaryURL(version: version, withResources: true)
                let destinationArchiveURL = componentsURL.appendingPathComponent(self.binaryName(withResources: true))
                // info: already warn if installed as 4dbase
                installed = binaryURL.download(to: destinationArchiveURL)
                if installed {
                    installed = destinationArchiveURL.unzip(to: destinationURL.deletingLastPathComponent(), delete: true)
                }

                if !installed, self.version != nil {
                    let binaryURL = self.binaryURL(version: version, withResources: true, withVersion: self.version)
                    let destinationArchiveURL = componentsURL.appendingPathComponent(self.binaryName(withResources: true))
                    // info: already warn if installed as 4dbase
                    installed = binaryURL.download(to: destinationArchiveURL)
                    if installed {
                        installed = destinationArchiveURL.unzip(to: destinationURL.deletingLastPathComponent(), delete: true)
                    }
                }
            }
        }

        if !installed {
            if let version = self.version {
                let versionSourceURL = self.versionSourceURL(version: version)
                let destinationArchiveURL = componentsURL.appendingPathComponent(self.binaryName(withResources: true))

                installed = versionSourceURL.download(to: destinationArchiveURL)
                if installed {
                    let parent = destinationURL.deletingLastPathComponent()
                    installed = destinationArchiveURL.unzip(to: parent, delete: true)
                    if installed {
                        installed = false
                        let unzippedFolder = parent.appendingPathComponent(destinationURL.deletingPathExtension().lastPathComponent+"-\(version)") // folder name by github
                        if unzippedFolder.isFileExists {
                            do {
                                try FileManager.default.moveItem(at: unzippedFolder, to: destinationURL)
                                installed = true
                            } catch {
                                log(.error, "Failed to rename \(unzippedFolder) to \(destinationURL)")
                            }
                        }
                    }
                }
            } else {
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

func execute(command: String, arguments: [String] = []) throws -> String {
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
