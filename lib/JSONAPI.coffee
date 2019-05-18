MountedServerModule = require './MountedServerModule'

module.exports = class JSONAPI extends MountedServerModule
  constructor: (server) ->
    super(server)
    @urlPrefix = '/api'
    @router.all '/*', (req,res) =>
      res.fail 404, "API endpoint #{req.path} does not exist"
  
  mount: ->
    @router.use (req, res, next) =>
      @log.info "#{req.method} #{req.url}"
      res.locals = {}
      res.fail = (status, error) =>
        error = 'Unknown error' unless error?
        error = error.toString()
        @log.error "Failed: #{error}"
        res.status(status).json (success: no, error: error)
      res.respond = (response) =>
        res.type 'application/json; charset=utf-8'
        res.status(200).json (success: yes, response: response)
      next()