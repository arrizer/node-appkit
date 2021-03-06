Express      = require 'express'
BodyParser   = require 'body-parser'
Static       = require 'serve-static'
HTTP         = require 'http'
Path         = require 'path'
FileSystem   = require 'fs'
Hogan        = require 'hogan-express'
Async        = require 'async'
Log          = require './Log'
Client       = require './Client'

defaultConfig =
  appname: 'App'
  serverModulesDir: 'server'
  clientScriptDir: 'client'
  clientTemplatesDir: 'client-templates'
  clientStylesDir: 'client-style'

module.exports = class Server  
  log = Log.Default()
  DEFAULT_PORT = 8888
  
  constructor: (@config) ->
    for key,value of defaultConfig
      unless @config[key]?
        @config[key] = value
    @config.libpath = Path.join(__dirname, '..')
  
    # Configure app
    app = Express()
    app.set "views", Path.join(@config.libpath, "views")
    app.set 'view engine', 'html'
    app.enable 'view cache'
    app.enable 'trust proxy'
    app.disable 'x-powered-by'
    app.engine 'html', Hogan
    app.set "port", (@config.port or DEFAULT_PORT)
    
    # Middleware
    app.use BodyParser.json()
    app.use Static(Path.join(@config.path, "public"))
    app.use Static(Path.join(@config.libpath, "public"))
    @app = app
    
  init: (next) ->
    # subclass uses this to initialize
    next()
    
  start: ->
    @init =>
      @startServer()
    
  loadModule: (module, next) ->
    log.debug "Loading module #{module}#{(if module.urlPrefix? then " -> #{module.urlPrefix}" else '')}" 
    module.init =>
      @app.use module.urlPrefix, module.router if module.router?
      next(module) if next?
    
  loadModules: (moduleMap, next) ->
    tasks = {}
    for key,module of moduleMap
      do (key,module) =>
        tasks[key] = (done) => 
          @loadModule module, (moduleRef) =>
            @[key] = moduleRef
            done()
    Async.series tasks, next
      
  registerErrorHandlingRoutes: ->
    @app.use (err, req, res, next) ->
      log.error 'Unhandled Exception: ', err
      log.error err.stack
      res.status(500).send('Internal server error')

  startServer: (next) ->
    @registerErrorHandlingRoutes()
    HTTP.createServer(@app).listen @app.get("port"), (error) =>
      log.info "Server ready on port #{@app.get("port")}"
      next error if next?