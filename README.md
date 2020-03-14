# kaluza-cli

[![build][build-shield]][build-url] [![release][release-shield]][release-url]

Command line interface for [Kaluza](https://github.com/mesopelagique/Kaluza), inspired by [npm](https://www.npmjs.com/) 

## Install

```bash
curl -sL https://mesopelagique.github.io/kaluza-cli/install.sh | sh
```

## Usage

### Init a project

```
kaluza init
```

A `component.json` file will be created in current folder (with name of the project)

### Add a dependency

```
kaluza add mesopelagique/formula_compose
```

A dependency will be added to your `component.json`

#### Add a developpement dependency

```
kaluza add mesopelagique/formula_compose -D
```

> Development dependencies, or devDependencies are components that are consumed by requiring them in files or run as binaries, during the development phase. These are components that are only necessary during development and not necessary for the production build

## TODO

- [X] release workflow
- [ ] `install` command
- [ ] `uninstall` command
- [ ] better argument parsing (manage order etc...)
- [ ] doc about version
- [ ] interactive init like npm

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[build-shield]: https://github.com/mesopelagique/kaluza-cli/workflows/build/badge.svg
[build-url]: https://github.com/mesopelagique/kaluza-cli/actions?workflow=build
[release-shield]: https://img.shields.io/github/v/release/mesopelagique/kaluza-cli
[release-url]: https://github.com/mesopelagique/kaluza-cli/releases/latest/download/kaluza.zip
