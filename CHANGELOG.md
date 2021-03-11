# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

> This file is generated. To add a new changelog entry, run the `changelog` tool. For more info, run `changelog help`.

<!--Latest Release-->
## [0.2.0] - 03-11-2021

### Added
- Add all changelog entry types from the [Keep a Changelog spec](https://keepachangelog.com/en/1.0.0/)
    - Types of changes are `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, and `Security`
- Add versioning information to the tool
    - Run `changelog --version`
- Improve error messaging when a corrupted file is encountered

### Changed
- Save changelog entries as Markdown files to facilitate easier code review
- Use imperative mood for changelog commands. This feels better when executing a command and will feel more familiar to git users

### Fixed
- Fix a few typos in the tool's output
- Use `yyyy` date formatting to avoid [weird, sneaky bugs](https://stackoverflow.com/q/15133549/1181439)

## [0.1.1] - 02-26-2021

### Fixed
- Bundle `SwiftToolsSupport` [correctly](https://developer.apple.com/forums/thread/655937) when building for release

## [0.1.0] - 02-26-2021

### Added
- Initial release
    - Create the Swift package
    - Add `help`, `log`, and `publish` commands
    - Set up unit test suite

[0.2.0]: https://github.com/pg8wood/changelog-generator/compare/0.1.1...0.2.0
[0.1.1]: https://github.com/pg8wood/changelog-generator/compare/0.1.0...0.1.1
[0.1.0]: https://github.com/pg8wood/changelog-generator/releases/tag/0.1.0
