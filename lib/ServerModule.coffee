Log = require './Log'

module.exports = class ServerModule
  constructor: (@server) ->
    @log = Log.Module @constructor.name
  
  init: (next) ->
    next()
  
  toString: ->
    @constructor.name