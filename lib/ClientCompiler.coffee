Async = require 'async'
Path = require 'path'
FileSystem = require 'fs'
Watcher = require 'fs-watch-tree'

module.exports = class ClientCompiler
  constructor: (@path, automcompile) ->
    @compile =>
      @watchDirectory() if automcompile
      
  readDirectory: (directory, next) ->
    files = []
    FileSystem.readdir directory, (error, items) =>
      Async.each items, (item, done) =>
        path = Path.join directory, item
        FileSystem.stat path, (error, stat) =>
          return done() if error?
          if stat.isDirectory()
            @readDirectory path, (subpaths) =>
              files.push subpath for subpath in subpaths
              done()
          else if stat.isFile()
            files.push path
            done()
          else
            done()
      , =>
        next files
  
  readDirectories: (directories, next) ->
    files = []
    Async.eachSeries directories, (directory, done) =>
      @readDirectory directory, (filesInDirectory) =>
        files.push file for file in filesInDirectory
        done()
    , =>
      next files
  
  watchDirectory: ->
    FileSystem.exists @path, (exists) =>
      if exists
        Watcher.watchTree @path, =>
          @result = null
          @compile()
      
  compile: (next) ->
    next()