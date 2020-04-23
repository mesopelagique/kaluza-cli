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

    @Flag(name: [.customShort("g"), .long], help: "Install to a global storage.")
    var global: Bool

    @Flag(name: [.customShort("f"), .long], help: "Force (for git command).")
    var force: Bool

    @Argument(help: "The dependency path: <orga>/<repo>(@<version).")
    var path: String?

    @Flag(help: "Show debug information.")
    var verbose: Bool

    var dependencyType: DependencyType {
        return saveDev ? .dev: (self.saveOptional ? .optional : .standard)
    }

    var url: URL? {
        if global {
            let url: URL = .globalComponent
            if !url.isFileExists {
                Component().write(to: url)
            }
            return url
        } else {
            guard componentURL.isFileExists else {
                log(.error, "\(componentFileName) does not exists. Please init first.")
                return nil
            }
            return componentURL
        }
    }

    func run() {
        Level.isDebug = verbose
        guard let componentURL = self.url else {
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

                component.write(to: componentURL)
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
            dependency.install(binary: binary, warnIfInstalled: warnIfInstalled, global: global, force: force)
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

    // XXX Use 4d app as global, maye ind another wayN
    var globalComponentsURL: URL {
        let componentsURL = URL.appURL.appendingPathComponent("Contents", isDirectory: true).appendingPathComponent("Components", isDirectory: true)
        if !componentsURL.isFileExists {
            try? FileManager.default.createDirectory(at: componentsURL, withIntermediateDirectories: true, attributes: nil)
        }
        return componentsURL
    }

    fileprivate var isGitRepo: Bool {
        let directory = componentURL.deletingLastPathComponent()
        return directory.appendingPathComponent(".git", isDirectory: true).isFileExists
    }

    func destinationURL(componentsURL: URL) -> URL {
        let name = self.repository
        if name.lowercased().contains(".4dbase") {
            return componentsURL.appendingPathComponent(name)
        }
        return componentsURL.appendingPathComponent(name).appendingPathExtension("4dbase")
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

    func install(binary: Bool, warnIfInstalled: Bool, global: Bool, force: Bool) {
        let componentsURL: URL
        if global {
            componentsURL = self.globalComponentsURL
        } else {
            componentsURL = self.componentsURL
        }
        let destinationURL = self.destinationURL(componentsURL: componentsURL)
        if destinationURL.isFileExists {
            log(warnIfInstalled ? .error:.debug, "\(path) already installed as 4dbase") // XXX maybe if force redownload
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

            if installed {
                log(.info, "\(path) installed using release 4DZ")
            } else {
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
                        if installed {
                            log(.info, "\(path) installed using release archive")
                        }
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
                                log(.info, "\(path) installed using release \(version) archive")
                            } catch {
                                log(.error, "Failed to rename \(unzippedFolder) to \(destinationURL)")
                            }
                        }
                    }
                }
            } else {
                let submodule = self.isGitRepo && !global
                var arguments: [String]
                if submodule {
                    arguments = ["submodule", "-q", "add", "\(gitURL)", "Components/\(destinationURL.lastPathComponent)"] // must be relative
                } else {
                    arguments = ["clone", "-q", "\(gitURL)", "\(destinationURL.path)"]
                }
                if force {
                    arguments.insert("--force", at: 2)
                }
                do {
                    let output = try Bash.execute(commandName: gitPath(), arguments: arguments) ?? ""
                    log(.debug, output)
                    if submodule {
                        log(.info, "\(path) installed as gitsubmodule")
                    } else {
                        log(.info, "\(path) installed using git clone")
                    }
                } catch {
                    log(.error, "\(error)")
                }
            }
        }

    }
}

func gitPath() -> String {
    do {
        var output = try Bash.execute(commandName: "/usr/bin/which", arguments: ["git"]) ?? ""
        output.removeLast() // remove \n
        return output
    } catch {
        log(.error, "\(error)")
    }
    return "git"
}
