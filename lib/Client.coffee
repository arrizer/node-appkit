Path         = require 'path'
Express      = require 'express'
MountedServerModule = require './MountedServerModule'

ClientScriptCompiler     = require './ClientScriptCompiler'
ClientTemplatesCompiler  = require './ClientTemplatesCompiler'
ClientStylesheetCompiler = require './ClientStylesheetCompiler'

module.exports = class Client extends MountedServerModule
  constructor: (server) ->
    super(server)
    @scriptCompiler     = new ClientScriptCompiler(Path.join(@server.config.path, @server.config.clientScriptDir), yes)
    @templatesCompiler  = new ClientTemplatesCompiler(Path.join(@server.config.path, @server.config.clientTemplatesDir), yes)
    @stylesheetCompiler = new ClientStylesheetCompiler(Path.join(@server.config.path, @server.config.clientStylesDir), yes)
  
  mount: ->
    # Client HTML
    @router.get '/', (req,res) =>
      @templatesCompiler.compile (error) =>
        res.render 'client', 
          appname: @server.config.appname
          templates: @templatesCompiler.result
#         config: JSON.stringify(main.config)
          
    # Coffee Script
    @router.get '/client.coffee', (req,res) =>
      res.type 'application/javascript'
      @scriptCompiler.compile (error) =>
        if !error? and @scriptCompiler.originalScript?
          res.send @scriptCompiler.originalScript
        else
          res.send 500, "Original script not available"
  
    # JavaScript
    @router.get '/client.js', (req,res) =>
      res.set 'X-Source-Map', '/client.js.map'
      res.type 'application/javascript'
      @scriptCompiler.compile (error) =>
        if !error?
          res.send @scriptCompiler.result
        else
          res.send 500, "Client script compilation failed: #{error}"
    
    # Source Map
    @router.get '/client.js.map', (req,res) =>
      res.type 'application/json'
      @scriptCompiler.compile (error) =>
        if !error? and @scriptCompiler.sourceMap?
          res.send @scriptCompiler.sourceMap
        else
          res.send 500, "Client script source map not available"
          
    # Stylesheet
    @router.get '/style.css', (req,res) =>
      @stylesheetCompiler.compile (error) =>
        if error?
          res.send 404, "LESS stylesheet failed to compile: #{error}"
        else
          res.type 'text/css'
          res.send @stylesheetCompiler.result