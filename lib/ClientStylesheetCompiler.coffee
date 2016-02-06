FileSystem     = require 'fs'
Path           = require 'path'
LESS           = require 'less'
Async          = require 'async'
Log            = require './Log'
ClientCompiler = require './ClientCompiler'

module.exports = class ClientStylesheetCompiler extends ClientCompiler
  log = Log.Module 'ClientStylesheetCompiler'
  
  LIB_CLIENT_STYLE_DIR = Path.join(__dirname, '..', 'client-style')

  compile: (next) ->
    return next() if @result?
    @readDirectories [LIB_CLIENT_STYLE_DIR, @path], (files) =>
      files = files.filter (file) -> Path.extname(file,'.less') is '.less'
      Async.map files, (file, done) =>
        FileSystem.readFile file, (error, data) =>
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
