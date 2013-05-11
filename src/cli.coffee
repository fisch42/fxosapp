###
This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
###

os      = require 'os'
nopt    = require 'nopt'
path    = require 'path'
fstools = require 'fs-tools'
App     = require './fxosapp'

knownOpts =
	path: path

shortHands =
	p: ['--path']

printUsage = ->
	console.log "\n
Usage: fxosapp <action> [options]\n
\n
Known actions:\n
\n
    package [file]      Create app package zip as [file]. The default is\n
                        /dist/application.zip.\n
    push                Push to device.\n
    copy [path]         Copy app files to [path]. The default is /dist/hosted.\n
\n
Known options:\n
\n
    -p [path]           The path to use as project directory, instead of the\n
    --path [path]       current working directory.\n
\n
"
	process.exit 42

loadManifest = (app) ->
	mfpath = app.findManifest()
	if mfpath is null
		console.error 'manifest.webapp not found'
		process.exit 1
	app.loadManifest mfpath
	return

addTempDir = ->
	tmp = os.tmpdir()
	template = path.resolve tmp, 'fxosapp-XXXXX'
	dir = fstools.tmpdir template
	fstools.mkdirSync dir
	return dir

actions =
	push: (app) ->
		loadManifest app
		app.on 'manifest', ->
			tmp = addTempDir()
			file = path.resolve tmp, './application.zip'
			app.on 'packaged', ->
				console.log 'Please accept the remote debugging request on your device (waiting 10 seconds)'
				app.push file
			app.on 'pushed', ->
				fstools.removeSync tmp
			app.on 'error', ->
				fstools.removeSync tmp
			app.package file
		return
	package: (app, args) ->
		loadManifest app
		app.on 'manifest', ->
			if args.argv.remain[1]?
				zip = path.resolve app.projectdir, args.argv.remain[1]
				app.package zip
			else
				do app.package
		return
	copy: (app, args) ->
		loadManifest app
		app.on 'manifest', ->
			if args.argv.remain[1]?
				cpath = path.resolve app.projectdir, args.argv.remain[1]
				app.copy cpath
			else
				do app.copy
		return

module.exports = ->
	errflag = false
	parsed = nopt knownOpts, shortHands, process.argv, 2
	action = parsed.argv.remain[0]
	if not action? or parsed.help or action is 'help' or (action? and not actions[action]?)
		do printUsage
	if parsed.path?
		app = new App parsed.path
	else
		app = new App()
	app.on 'error', (err) ->
		console.error err.message.trim()
		errflag = true
	process.on 'exit', ->
		if errflag
			process.exit 1
	actions[action](app, parsed)


