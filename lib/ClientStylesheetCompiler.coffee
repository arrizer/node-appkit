FileSystem     = require 'fs'
Path           = require 'path'
LESS           = require 'less'
Async          = require 'async'
Log            = require './Log'
ClientCompiler = require './ClientCompiler'

module.exports = class ClientStylesheetCompiler extends ClientCompiler
  log = Log.Module 'ClientStylesheetCompiler'

  compile: (next) ->
    return next() if @result?
    FileSystem.readdir @path, (error, files) =>
      return next error if error?
      Async.filter files, 
        (file, done) => done(Path.extname(file,'.less') is '.less')
      , (files) =>
        Async.map files, (file, done) =>
          FileSystem.readFile Path.join(@path,file), (error, data) =>
            if error?
              done error
            else
              done null, data.toString()
        , (error, results) =>
          unless error?
            content = results.join("\n")
            LESS.render content , (error, output) =>
              if error?
                error = "Error in LESS stylesheet: #{error.line} : #{error.message}"
                log.error error
                log.bell()
                next error
              else
                @result = output.css
                log.debug 'LESS stylesheet compilation successful'
                next null if next?
          else
            next error if next?
