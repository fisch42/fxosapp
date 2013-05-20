# fxosapp

`fxosapp` is a Firefox OS App build tool.

## Installation

```bash
npm install -g fxosapp
```

### Push to Device

If you want to use the push to device feature with `fxosapp push`, you need
`adb` and `xpcshell` in your path and `Remote Debugging`
[enabled on your device](https://developer.mozilla.org/en-US/docs/Mozilla/Firefox_OS/Debugging/Developer_settings#The_Developer_panel).

On my Fedora 18 I installed for `adb` `android-tools` and for `xpcshell` `xulrunner-devel`.
Then I created a symlink pointing from `.local/bin/xpcshell` to `/usr/lib64/xpcshell`.

## Usage

```
Usage: fxosapp <action> [options]

Known actions:

    package [file]      Create app package zip as [file]. The default is
                        /dist/application.zip.
    push                Push to device.
    copy [path]         Copy app files to [path]. The default is /dist/hosted.

Known options:

    -p [path]           The path to use as project directory, instead of the
    --path [path]       current working directory.
```

### Ignoring Files

Create a `.fxosignore` file in your project directory next to the `manifest.webapp`
to ignore files, that you don't want in your app.

For example

```
*.swp
*.swo
*~
*.appcache
*.log
.git
.gitignore
dist
```

## Usage Programmatically

### Initialization

```coffeescript
App = require 'fxosapp'
app = new App()
```

The App constructor takes an optional path to the directory containing the
`manifest.webapp`.

```coffeescript
app = new App '/tmp/testproject/'
```

### Events

The `App` extends `EventEmitter` and emits the following events:

#### `error`

If there is an error, this event will be emitted together with an `Error`
object.

#### `manifest`

If a `manifest.webapp` file was loaded, this event will be emitted.

#### `packaged`

If an app was successfully packaged as a zip file, this event will be emitted.

#### `pushed`

If an app was successfully pushed to a phone, this event will be emitted.

#### `copied`

If an app was successfully copied to another path, this event will be emitted.

### Finding the Manifest

It is possible to search the directory tree upwards (i.e. all parent
directories) for a `manifest.webapp` by calling `findManifest`.

```coffeescript
file = app.findManifest()
```

`findManifest` will return `null` if it could not find a manifest file.

### Loading the Manifest

The manifest file needs to be loaded explicitely by calling `loadManifest`.
If the manifest has been loaded the `manifest` event will be emitted.

```coffee
path = app.findManifest()
app.loadManifest path
app.on 'manifest', ->
	console.log 'manifest loaded!'
```

### Packaging

The `package` method will package the app as zip file. It optionally takes an
filepath to store the zip to.

```coffee
app.on 'manifest', ->
	app.package()
	app.on 'packaged', ->
		console.log 'app packaged!'
```

### Push

The `push` method will package the app and push it to a connected device. It
optionally takes an filepath to store the zip to.

```coffee
app.on 'manifest', ->
	app.push()
	app.on 'pushed', ->
		console.log 'app pushed!'
```

### Copy

The `copy` method will copy the project files to another directory (for
distribution as hosted app). It optionally takes an filepath to copy the files
to.

```coffee
app.on 'manifest', ->
	app.copy '/tmp/hosted'
	app.on 'copied', ->
		console.log 'app copied!'
```

## License

MPL see [LICENSE file](https://github.com/fisch42/fxosapp/blob/master/LICENSE).

The [`/bin/install.js` file](https://github.com/fisch42/fxosapp/blob/master/bin/install.js) was taken from
[make-fxos-install](https://github.com/digitarald/make-fxos-install)
and also published under MPL, as discussed
[here](https://github.com/digitarald/make-fxos-install/issues/4#issuecomment-17766315).
