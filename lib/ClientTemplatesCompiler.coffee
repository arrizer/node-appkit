Path            = require 'path'
FileSystem      = require 'fs'
Async           = require 'async'
Log             = require './Log'
ClientCompiler  = require './ClientCompiler'

module.exports = class ClientTemplatesCompiler extends ClientCompiler
  log = Log.Module 'ClientTemplatesCompiler'
  
  filesInDirectory = (directory, recursive, extension, next) ->
    FileSystem.readdir directory, (error, files) =>
      return next error if error?
      results = []
      Async.each files, (file, done) =>
        filepath = Path.join path, file
        FileSystem.stat filepath, (error, stats) =>
          return next error if error?
          if stats.isDirectory() and recursive
            @filesInDirectory Path.join(directory, file), recursive, extension, (error, recResults) =>
              results = results.concat recResults unless error?
              done()
          else if stats.isFile() and (!extension? or Path.extname(filepath) is '.' + extension)
            results.push filepath
            done()
          else
            done()
      , =>
        next null, results
    
  compile: (next) ->
    return next() if @result?
    FileSystem.readdir @path, (error, files) =>
      files = files.filter (file) => Path.extname(file) is '.html'
      files = files.map (file) => Path.join(@path, file)
      @result = []
      Async.each files, (file, done) =>
        FileSystem.readFile file, (error, data) =>
          done(error) if error?
          @result.push 
            name: Path.basename(file, '.html')
            content: data.toString()
          done()
      , (error) => 
        return next error if error?
        log.debug 'Client template compilation successful'
        next() if next?