//
//  Config.swift
//  
//
//  Created by phimage on 26/04/2020.
//

import Foundation
import ArgumentParser

struct Config: ParsableCommand {

    static let configuration = CommandConfiguration(abstract: "Manage the configuration",
                                                    subcommands: [Config.Set.self, Config.Get.self, Config.Delete.self, Config.List.self, Config.Edit.self])

    static func url(global: Bool) -> URL? {
        if global {
            let url: URL = .globalComponent
            if !url.isFileExists {
                Component().write(to: url)
            }
            return url
        } else {
            guard componentURL.isFileExists else {
                let url: URL = .globalComponent
                if !url.isFileExists {
                    Component().write(to: url)
                }
                return url
            }
            return componentURL
        }
    }

}

extension Config {

    struct Set: ConfigSubCommand {

        static let configuration = CommandConfiguration(abstract: "Sets the config key to the value.")

        @Flag(name: [.customShort("g"), .long], help: "Edit global configuration.")
        var global: Bool = false

        @Argument(help: "The key")
        var key: String

        @Argument(help: "The value")
        var value: String

        func doRun(componentURL: URL) {
            if global {
                if !FileManager.default.fileExists(atPath: componentURL.path) {
                    Component().write(to: componentURL)
                }
            }
            guard var component = Component.read(from: componentURL) else {
                return
            }
            var value: Any
            switch self.value {
            case "true":
                value = true
            case "false":
                value = false
            default:
                if let doubleValue = Double(self.value) {
                    value = doubleValue
                } else {
                    value = self.value
                }
            }
            component.setConfig(key: key, value: value)
            component.write(to: componentURL)
        }

    }

    struct Get: ConfigSubCommand {

        static let configuration = CommandConfiguration(abstract: "Echo the config value to stdout.")

        @Flag(name: [.customShort("g"), .long], help: "Show value rom global configuration.")
        var global: Bool = false

        @Argument(help: "The key")
        var key: String

        func doRun(componentURL: URL) {
            guard let component = Component.read(from: componentURL) else {
                return
            }
            log(.info, "\(component.getConfig(key: key) ?? "undefined")")
        }

    }

    struct Delete: ConfigSubCommand {

        static let configuration = CommandConfiguration(abstract: "Deletes the key from configuration file.")

        @Flag(name: [.customShort("g"), .long], help: "Show value rom global configuration.")
        var global: Bool = false

        @Argument(help: "The key")
        var key: String

        func doRun(componentURL: URL) {
            guard var component = Component.read(from: componentURL) else {
                return
            }
            component.deleteConfig(key: key)
            component.write(to: componentURL)
        }

    }

    struct List: ConfigSubCommand {

        static let configuration = CommandConfiguration(abstract: "Echo the config value to stdout.")

        @Flag(name: [.customShort("g"), .long], help: "Show value from global configuration.")
        var global: Bool = false

        @Flag(help: "Display in JSON format.")
        var json: Bool = false

        func doRun(componentURL: URL) {
            guard let component = Component.read(from: componentURL) else {
                return
            }

            if json {
                if let config = component.config, !config.isEmpty {
                    let encoder: JSONEncoder = .component
                    do {
                        log(.info, String(data: try encoder.encode(config), encoding: .utf8) ?? "{ \"error\": \"failed to encode\" }")
                    } catch {
                        log(.error, "{ \"error\": \"failed to encode \(error)\" }")
                    }
                } else {
                    log(.info, "{}")
                }
            } else {
                if let config = component.config, !config.isEmpty {
                    for (key, value) in config {
                        if value.value is String {
                            log(.info, "\(key) = \"\(value)\"")
                        } else {
                            log(.info, "\(key) = \(value)")
                        }
                    }

                } else {
                    log(.info, "<empty>")
                }
            }
        }

    }

    struct Edit: ConfigSubCommand {

        static let configuration = CommandConfiguration(abstract: "Edit with system editor.")

        @Flag(name: [.customShort("g"), .long], help: "Edit global configuration.")
        var global: Bool = false

        func doRun(componentURL: URL) throws {
            _ = try Bash.execute(commandName: "/usr/bin/open", arguments: [componentURL.path])
        }

    }
}

protocol ConfigSubCommand: ParsableCommand {
    var global: Bool { get }
    func doRun(componentURL: URL) throws
}

extension ConfigSubCommand {

    func run() throws {
        guard let componentURL = Config.url(global: global) else {
            return
        }
        try doRun(componentURL: componentURL)
    }
}

extension Component {

    mutating func setConfig(key: String, value: Any) {
        if self.config == nil {
            self.config = [key: AnyCodable(value)]
        } else {
            self.config?[key] = AnyCodable(value)
        }
    }

    func getConfig(key: String) -> Any? {
        return self.config?[key]?.value
    }

    mutating func deleteConfig(key: String) {
        self.config?.removeValue(forKey: key)
    }

}
