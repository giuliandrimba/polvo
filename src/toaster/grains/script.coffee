fs = require "coffee-script"
cs = require "coffee-script"

#<< FsUtil, ArrayUtil, StringUtil

class Script
	
	constructor:(@config)->
		@src = @config.src
		@release = @config.release
		@compile( @watch )
	
	watch:=>
		FsUtil.watch_folder @src, (info)=>
			type = StringUtil.titleize info.type
			
			switch info.action
				when "created"
					msg = "#{('New ' + info.type + ' created:').green}"
					console.log "#{msg} #{info.path}"
					@compile()
				
				when "deleted"
					msg = "#{(type + ' deleted, stop watching: ').red}"
					console.log "#{msg} #{info.path}"
					@compile()
				
				when "updated"
					msg = "#{(type + ' changed').yellow}"
					console.log "#{msg} #{info.path}"
					@compile()
				
				when "watching"
					msg = "#{('Watching ' + info.type).cyan}"
					console.log "#{msg} #{info.path}"
	
	compile:(fn)->
		@collect (files)=>
			ordered = @reorder( files )
			
			linenum = 1
			for file, i in ordered
				file.start = linenum
				file.length = file.raw.split("\n").length
				file.end = file.start + ( file.length - 1 )
				linenum = file.end + 1
			
			contents = @merge( ordered )
			
			try
				# compile production file
				contents = cs.compile( contents )
				fs.writeFileSync @release, contents
				# console.log "#{'Toasted with love:'.bold} #{@release}"
				
				# compiling test files
				toaster = "#{@release.split("/").slice(0,-1).join '/'}/toaster"
				classes = "#{toaster}/classes"
				
				FsUtil.rmdir_rf toaster if path.existsSync toaster
				FsUtil.mkdir_p classes
				
				tmpl = "document.write('<scri'+'pt src=\"%SRC%\"></scr'+'ipt>')"
				buffer = ""
				
				for file, index in ordered
					relative = file.path.replace @src, ""
					relative = relative.replace ".coffee", ".js"
					
					filepath = classes + relative
					folderpath = filepath.split('/').slice(0,-1).join "/"
					
					if !path.existsSync folderpath
						FsUtil.mkdir_p folderpath
					
					relative = "./toaster/classes#{relative}"
					fs.writeFileSync filepath, cs.compile file.raw, {bare:1}
					buffer += tmpl.replace( "%SRC%", relative ) + "\n"
					
				# write toaster loader
				toaster = "#{toaster}/toaster.js"
				fs.writeFileSync toaster, cs.compile buffer, {bare:1}
			
			catch err
				msg = err.message
				line = msg.match( /(line\s)([0-9]+)/ )[2]
				for file in ordered
					if line >= file.start && line <= file.end
						line = (line - file.start) + 1
						msg = msg.replace /line\s[0-9]+/, "line #{line}"
						msg = StringUtil.ucasef msg
						console.log "ERROR!".bold.red, msg,
							"\n\t#{file.path.red}"
			
			fn?()
	
	collect:(fn)->
		FsUtil.find @src, "*.coffee", (files)=>
			buffer = []
			for file in files
				
				raw = fs.readFileSync file, "utf-8"
				dependencies = []
				
				# class name
				if /(class\s)([\S]+)/g.test raw
					name = /(class\s)([\S]+)/g.exec( raw )[ 2 ]
				
				if name && ArrayUtil.find buffer, name
					continue
				
				# class dependencies
				if /(extends\s)([\S]+)/g.test raw
					dependencies.push /(extends\s)([\S]+)/g.exec( raw )[ 2 ]
				
				if /(#<<\s)(.*)/g.test raw
					requirements = raw.match /(#<<\s)(.*)/g
					for item in requirements
						item = /(#<<\s)(.*)/.exec( item )[ 2 ]
						item = item.replace /\s/g, ""
						item = [].concat item.split ","
						dependencies = dependencies.concat item
				
				buffer.push {
					path: file
					name:name,
					dependencies:dependencies,
					raw:raw
				}
			fn buffer
	
	missing: {},
	reorder:(classes, cycling = false)->
		@missing = {} if !cycling
		initd = {}
		
		for klass, i in classes
			initd["#{klass.name}"] = 1
			continue if !klass.dependencies.length
			
			index = 0
			while index < klass.dependencies.length
				dependency = klass.dependencies[index]
				
				if initd[dependency]
					index++
					continue
				
				found = ArrayUtil.find classes, dependency, "name"
				if found?
					if ArrayUtil.has found.item.dependencies, klass.name, "name"
						klass.dependencies.splice( index, 1 )
						console.log "WARNING! ".bold.yellow,
							"You have a circular loop between classes",
							"#{dependency.yellow.bold} and",
							"#{klass.name.yellow.bold}."
						continue
					else
						classes.splice( index, 0, found.item )
						classes.splice( found.index + 1, 1 )
						classes = @reorder classes, true
				
				else if !@missing[dependency]
					@missing[dependency] = 1
					klass.dependencies.push dependency
					klass.dependencies.splice index, 1
					console.log "WARNING! ".bold.yellow,
						"Dependence #{dependency.yellow.bold} not found",
						"for class #{klass.name.yellow.bold}."
				index++
				
		classes
	
	merge:(input)->
		(klass.raw for klass in input).join "\n"