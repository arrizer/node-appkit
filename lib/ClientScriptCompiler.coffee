Path            = require 'path'
FileSystem      = require 'fs'
CoffeeScript    = require 'coffee-script'
Async           = require 'async'
Watcher         = require 'fs-watch-tree'
DependencyGraph = require 'deppy'
Log             = require './Log'
ClientCompiler  = require './ClientCompiler'

module.exports = class ClientScriptCompiler extends ClientCompiler
  log = Log.Module 'ClientScriptCompiler'
    
  resolveDependencies: (next) ->
    FileSystem.readdir @path, (error, files) =>
      files = files.filter (file) -> Path.extname(file) is '.coffee'
      graph = DependencyGraph.create()
      classFiles = {}
      orphans = {}
      Async.map files, (file, done) =>
        file = Path.join(@path, file)
        classname = Path.basename(file, '.coffee')
        return next new Error('Duplicate client class name ' + classname) if classFiles[classname]?
        classFiles[classname] = file
        orphans[classname] = 1
        FileSystem.readFile file, (error, data) =>
          if error?
            log.error "Could not read file %s: %s", file, error
            return next error 
          dependencies = []
          re = /^\s*#_require\s+(.+)\s*$/gim
          while (match = re.exec data.toString())?
            dependencies.push match[1]
            delete orphans[match[1]]
          graph classname, dependencies
          done()
      , =>
        graph '_', (orphan for orphan of orphans)
        filenames = []
        classnames = null
        try
          classnames = graph.resolve '_'
        catch error
          log.error "Failed to resolve dependency graph: %s", error
          return next error
        classnames.pop()
        filenames.push classFiles[classname] for classname in classnames
        next null, filenames

  compile: (next) ->
    return next() if @result?
    @resolveDependencies (error, files) =>
      return next error if error?
      Async.map files, (file, done) =>    
        FileSystem.readFile file, (error, data) =>
          return done(error) if error?
          data = data.toString()
          try
            CoffeeScript.compile data
          catch error
            log.error "Compilation of #{file} failed:\n%s", error.toString()
            log.bell()
            error.handled = yes
            return done error
          data = "# *** " + Path.basename(file,'.coffee') + " *** \n\n" + data
          done null, data
      , (error, contents) =>
        if error?
          return next error if next?
        content = "$ ->\n"
        for data in contents
          content += ('  '+line for line in data.split("\n")).join("\n")+"\n\n"
        content +="  new Main()"
        @originalScript = content
        # Compile client coffee script
        compilation = CoffeeScript.compile @originalScript, 
          header:no, 
          bare:yes, 
          sourceMap:yes, 
          sourceRoot:'/js', 
          sourceFiles:['client.coffee'],
          generatedFile:'client.js'
        @result = compilation.js #+ "\n//@ sourceMappingURL=/js/app.js.map"
        #@sourceMap = compilation.v3SourceMap
        log.debug 'Client script compilation successful'
        next() if next?