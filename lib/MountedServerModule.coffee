Express = require 'express'
ServerModule = require './ServerModule'

module.exports = class MountedServerModule extends ServerModule
  constructor: (@server) ->
    super
    @router = Express.Router()
    @mount()
    @urlPrefix = '/'

  mount: ->
  
  toString: ->
    @constructor.name