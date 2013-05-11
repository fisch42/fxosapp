###
This Source Code Form is subject to the terms of the Mozilla Public
License, v. 2.0. If a copy of the MPL was not distributed with this
file, You can obtain one at http://mozilla.org/MPL/2.0/.
###

fs             = require 'fs'
fspath         = require 'path'
parents        = require 'parents'
{EventEmitter} = require 'events'
{EasyZip}      = require 'easy-zip'
ls             = require 'ls'
dotignore      = require 'dotignore'
{exec}         = require 'child_process'
fstools        = require 'fs-tools'

class App extends EventEmitter
	
	constructor: (@dir = process.cwd()) ->
		@manifest = null
	
	findManifest: ->
		dirs = parents @dir
		paths = dirs.map (x) ->
			if x isnt '/'
				x += '/'
			x += 'manifest.webapp'
		for path in paths
			if fs.existsSync path
				return path
		return null
	
	requireManifest: ->
		if @manifest is null
			@emit 'error', Error 'Manifest not loaded. Use loadManifest(path) first to load a manifest file'
			return false
		true
	
	loadManifest: (path) ->
		fs.exists path, (exists) =>
			if not exists
				@emit 'error', Error "Manifest file '#{path}' not found"
				return
			fs.readFile path, {encoding: 'utf8'}, (err, data) =>
				if err?
					@emit 'error', Error "Error reading manifest '#{path}'"
					return
				try
					@manifest = JSON.parse data
				catch ex
					@emit 'error', Error "Error parsing manifest JSON of '#{path}'\n" + ex
					return
				@projectdir = fspath.dirname path
				@emit 'manifest', @manifest
	
	getAppId: ->
		if not @requireManifest()
			return
		if @manifest.name?
			name = @manifest.name
			id   = name.replace /\W/g, ''
			return id
		else
			@emit 'error', new Error 'name attribute missing in manifest.webapp'
	
	getProjectFiles: ->
		if not @requireManifest()
			return
		ignorefile = '.fxosignore'
		ignore = 'dist/application.zip\n' + ignorefile
		ignorepath = @projectdir + '/' + ignorefile
		if fs.existsSync ignorepath
			ignore += '\n' + fs.readFileSync ignorepath
		files = ls @projectdir,
			type: 'file'
			recurse: true
		matcher = dotignore.createMatcher ignore
		pathlen = @projectdir.length
		files = files.filter (f) ->
			relpath = f.full.substr pathlen
			not matcher.shouldIgnore relpath
		files = files.map (f) ->
			source: f.full
			target: f.full.substr pathlen + 1
		return files
	
	package: (zippath = @projectdir + '/dist/application.zip') ->
		files = @getProjectFiles()
		zipdirname = fspath.dirname zippath
		fstools.mkdir zipdirname, (err) =>
			if err?
				@emit 'error', err
				return
			zip = new EasyZip()
			zip.batchAdd files, =>
				zip.writeToFile zippath, (err) =>
					if err?
						@emit 'error', err
						return
					@emit 'packaged', zippath
	
	copy: (path = @projectdir + '/dist/hosted/') ->
		files = @getProjectFiles()
		files = files.map (f) ->
			f.target = fspath.resolve path, f.target
			f
		for file in files
			fstools.copy file.source, file.target, (err) =>
				if err?
					@emit 'error', err
		@emit 'copied'
		return
	
	push: (zippath = @projectdir + '/dist/application.zip') ->
		appid = @getAppId()
		if appid is undefined
			return
		installjs = __dirname + '/../bin/install.js'
		adbpush = "adb push #{zippath} /data/local/tmp/b2g/#{appid}/application.zip"
		adbport = 'adb forward tcp:6000 tcp:6000'
		install = "xpcshell #{installjs} #{appid} 6000"
		exec adbpush, (err) =>
			if err?
				@emit 'error', err
				return
			exec adbport, (err) =>
				if err?
					@emit 'error', err
					return
				exec install, {timeout: 10000}, (err) =>
					if err?
						if err.killed is true
							@emit 'error', new Error 'Device did not respond or remote debugging request was canceled'
							return
						else
							@emit 'error', err
							return
					@emit 'pushed'
		
module.exports = App

