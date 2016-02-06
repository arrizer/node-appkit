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
  
  LIB_CLIENT_SCRIPT_DIR = Path.join(__dirname, '..', 'client')
  
  readUnits: (directories, next) ->
    units = []
    Async.each directories, (directory, done) =>
      @readDirectory directory, (filesInDirectory) =>
        for file in filesInDirectory when Path.extname(file) is '.coffee'
          units.push
            name: Path.relative(directory, file).replace('.coffee', '').replace('/', '.')
            path: file
        done()
    , =>
      next units
    
  resolveDependencies: (next) ->
    @readUnits [@path, LIB_CLIENT_SCRIPT_DIR], (units) =>
      return next error if error?
      graph = DependencyGraph.create()
      unitsByName = {}
      orphans = {}
      Async.map units, (unit, done) =>
        unitname = unit.name
        file = unit.path
        return next new Error('Duplicate client unit ' + unitname) if unitsByName[unitname]?
        unitsByName[unitname] = unit
        orphans[unitname] = 1
        FileSystem.readFile file, (error, data) =>
          if error?
            log.error "Could not read file %s: %s", file, error
            return next error 
          dependencies = []
          re = /^\s*#_require\s+(.+)\s*$/gim
          while (match = re.exec data.toString())?            
            dependencies.push match[1]
            delete orphans[match[1]]
          graph unitname, dependencies
          done()
      , =>
        graph '_', (orphan for orphan of orphans)
        unitnamesOrdered = null
        try
          unitnamesOrdered = graph.resolve '_'
        catch error
          log.error "Failed to resolve dependency graph: %s", error
          return next error
        unitnamesOrdered.pop()
        resolvedUnits = unitnamesOrdered.map (unitname) => unitsByName[unitname]
        next null, resolvedUnits
        
  synthesizePackageDeclarations: (units) ->
    lines = []
    for unit in units
      components = unit.name.split '.'
      parts = []
      while components.length >= 2
        parts.push components.shift()
        varname = parts.join('.')
        lines.push(varname + ' = {}')
    lines = lines.filter (value, index, self) -> self.indexOf(value) is index
    return lines.join("\n")
    
        
  compile: (next) ->
    return next() if @result?
    @resolveDependencies (error, units) =>
      return next error if error?
      Async.map units, (unit, done) =>    
        FileSystem.readFile unit.path, (error, data) =>
          return done(error) if error?
          data = data.toString()
          try
            CoffeeScript.compile data
          catch error
            log.error "Compilation of #{unit.path} failed:\n%s", error.toString()
            log.bell()
            error.handled = yes
            return done error
          preamble = "# *** " + unit.name + " *** \n\n"
          done null, preamble + data
      , (error, contents) =>
        if error?
          return next error if next?
        content = "$ ->\n"
        contents.unshift @synthesizePackageDeclarations(units)
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