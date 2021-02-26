# changelog-generator
> Curbing Cumbersome Changelog Conflicts

A tool that creates changelog entries and stores them as unique files to avoid merge conflictss in version control. When it's time to release, `changelog publish` collects these files and appends them to your changelog file.

## Installation

### [Mint](https://github.com/yonaskolb/Mint) (system-wide installation)


```sh
$ mint install pg8wood/changelog-generator
```

## Usage
### Help
To view all the available options, run `$ changelog help`

### Log a New Change
Changelog entries may be added interactively with your favorite text editor, or quick entries can be passed as command-line arguments.

```sh
$ changelog log addition "I added something cool" "And something boring"

### Added
- I added something cool
- And something boring

🙌 Created changelog entry at changelogs/unreleased/<uniqueFilename>.md
```

#### Arguments
```
  <entry-type>            The type of changelog entry to create.  
        Valid entry types are addition, change, and fix.

  <text>                  A list of strings separated by spaces to be recorded as a bulleted changelog entry. 
        If <text> is supplied, the --editor option is ignored and the changelog entry is created for you without opening an interactive text editor.
```

#### Options
```
  -d, --directory <path>  A directory where unpublished changelog entries will be written to / read from as Markdown files. (default: changelogs/unreleased/)
  -e, --editor <editor>   A terminal-based text editor executable in your $PATH used to write your changelog entry with more precision than the default bulleted list of changes. (default: vim)
  -h, --help              Show help information.
```

### Publish a Release
```
$ changelog publish 1.0.1 

## [1.0.1] - 02-26-2021

### Added
- help
- I added something cool

Nice! CHANGELOG.md was updated. Congrats on the release! 🥳🍻
```

#### Arguments
```
  <version>               The version number associated with the changelog entries to be published. 
  <release-date>          A string representing the date the version was published. Format MM-dd-YYYY. (default: <today>)
```

#### Options
```
  -d, --directory <path>  A directory where unpublished changelog entries will be written to / read from as Markdown files. (default: changelogs/unreleased/)
  --dry-run               Prints the changelog entries that would have been appended to the CHANGELOG and doesn't delete any files in changelogs/unreleased. 
  --changelog-filename <changelog-filename>
                          The CHANGELOG file to which the unreleased changelog entries will be prepended. (default: CHANGELOG.md)
  -h, --header <path>     A Markdown file containing optional header text that will be prepended to your changelog. (default: changelogs/header.md)
        If the supplied file does not exist or is not readable, no text will be prepended to the changelog.
  --help              Show help information.
```
