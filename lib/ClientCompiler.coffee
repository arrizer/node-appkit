Watcher = require 'fs-watch-tree'

module.exports = class ClientCompiler
  constructor: (@path, automcompile) ->
    @compile =>
      @watchDirectory() if automcompile
  
  watchDirectory: ->
    Watcher.watchTree @path, =>
      @result = null
      @compile()
      
  compile: (next) ->
    next()