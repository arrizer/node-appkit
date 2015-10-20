Express = require 'express'
Log     = require './Log'

module.exports = class ServerModule
  constructor: (@server) ->
    @log = Log.Module @constructor.name
    @router = Express.Router()
    @mount()
    @urlPrefix = '/'

  mount: ->
  
  toString: ->
    @constructor.name