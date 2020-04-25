//
//  Uninstall.swift
//  
//
//  Created by phimage on 26/04/2020.
//

import Foundation
import ArgumentParser

struct Uninstall: ParsableCommand {

    static let configuration = CommandConfiguration(abstract: "Uninstall dependencies")

    @Flag(name: [.customShort("g"), .long], help: "Uninstall from global storage.")
    var global: Bool

    @Argument(help: "The dependency path: <orga>/<repo>(@<version).")
    var path: String

    @Flag(help: "Show debug information.")
    var verbose: Bool

    var url: URL? {
        if global {
            let url: URL = .globalComponent
            if !url.isFileExists {
                log(.error, "\(url) does not exists. Nothing to uninstall.")
                return nil
            }
            return url
        } else {
            guard componentURL.isFileExists else {
                log(.error, "\(componentFileName) does not exists. Nothing to uninstall.")
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
        let dependency = Dependency(path: path)
        _ = dependency.uninstall(global: global)
        let count = component.allDependencies.count
        component.dependencies?.removeAll(where: { $0.path == path})
        component.devDependencies?.removeAll(where: { $0.path == path})
        component.optionalDependencies?.removeAll(where: { $0.path == path})
        if component.allDependencies.count < count { // write only if there is change
            component.write(to: componentURL)
        }
    }

}

extension Dependency {

    func uninstall(global: Bool) -> Bool {
        let componentsURL: URL
        if global {
            componentsURL = self.globalComponentsURL
        } else {
            componentsURL = self.componentsURL
        }
        let destinationURL = self.destinationURL(componentsURL: componentsURL)
        if destinationURL.isFileExists {
            do {
                try FileManager.default.removeItem(at: destinationURL)
                log(.info, "Removed: \(destinationURL.path)")
                return true
            } catch {
                log(.error, "\(error)")
            }
        } else {
            let destinationArchiveURL = componentsURL.appendingPathComponent(self.binaryName(withResources: false))
            if destinationArchiveURL.isFileExists {
                do {
                    try FileManager.default.removeItem(at: destinationArchiveURL)
                    log(.info, "Removed: \(destinationArchiveURL.path)")
                    return true
                } catch {
                    log(.error, "\(error)")
                }
            }
        }
        return false
    }
}
