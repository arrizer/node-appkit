FileSystem = require 'fs'
Watcher = require 'fs-watch-tree'

module.exports = class ClientCompiler
  constructor: (@path, automcompile) ->
    @compile =>
      @watchDirectory() if automcompile
  
  watchDirectory: ->
    FileSystem.exists @path, (exists) =>
      if exists
        Watcher.watchTree @path, =>
          @result = null
          @compile()
      
  compile: (next) ->
    next()