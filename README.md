[![Maintainability](https://api.codeclimate.com/v1/badges/355d543c76280628d326/maintainability)](https://codeclimate.com/github/aladac/create_bundle/maintainability)
# create_bundle 

Tool for creating MacOS application bundles containing an icon and launch command copied from the source application.

## Example

![example](https://i.imgur.com/FwpYr8Q.gif)

## Why?
- Can't you just create a link? _Yes I can but I can't add commands to be run before an app is started_
- Can't you just do it all using a bash one liner? _Yes I can but I'm lazy and the gem exec provides some basic error handling_
- To create bare bundles to edit later

## Installation

    $ gem install create_bundle

## Usage

```
Usage: cb [OPTIONS] SOURCE_APP [DESTINATION_APP]
Usage: cb -i ICON -s SCRIPT -b DESTINATION_APP
    -v, --[no-]verbose               Run verbosely
    -i, --icon PATH                  Use a custom icon
    -s, --script PATH                Use a custom executable
    -b, --bare                       Create a bare bundle
```

	$ cb -v /Applications/iTerm.app ~/Desktop/iTerm.app
	$ cb -b -i Icon.icns -s start.sh New.app
	
## What does it actually do?
The script when run for a source app bundle copies the icon file from the bundle (trying to parse the Info.plist, falling back to AppIcon.icns when failed), creates a new app bundle with this icon and a script to open the original app bundle.
You may say the end result is kind of like creating a filesystem link.

You can create a _"bare"_ bundle with a custom script and icon

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
