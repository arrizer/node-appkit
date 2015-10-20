sprintf    = require('sprintf').sprintf
CLIColor   = require 'cli-color'
Path = require 'path'
FileSystem = require 'fs'

canonicalizeFilename = (name) ->
  name.toLowerCase().replace(/\s+/g, '_')

module.exports = class Log
  LEVELS =
    debug:
      level: 0
      colors: ['blue']
      textColors: ['blackBright']
    info:
      level: 1
      colors: ['cyan']
      textColors: []
    warn:
      level: 2
      colors: ['black','bgYellow']
      textColors: ['yellow']
    error:
      level: 3
      colors: ['red']
      textColors: ['red']
    fatal:
      level: 4
      colors: ['white','bgRedBright']
      textColors: ['red']
  
  DEFAULT = null
  LOG_PATH = null
  MODULE_LOGS = {}

  @Default: ->
    unless DEFAULT?
      log = new Log(process.stderr)
      log.pipe Log.File('main')
      log.timestamp = no
      log.colored = yes
      DEFAULT = log
    return DEFAULT
  
  @File: (filename, module) ->
    stream = null
    if LOG_PATH?
      filepath = Path.join(LOG_PATH, filename + '.log')
      stream = FileSystem.createWriteStream filepath, (flags: 'a')
    log = new Log stream, module
    log.timestamp = yes
    log.colored = no
    return log
    
  @Module: (name, filename) ->
    unless MODULE_LOGS[name]?
      log = Log.File (if filename? then canonicalizeFilename(filename) else canonicalizeFilename(name)), name
      log.pipe Log.Default()
      MODULE_LOGS[name] = log
    return MODULE_LOGS[name]
    
  @SetLogPath: (path) ->
    LOG_PATH = path
    
  constructor: (@stream, @module) ->
    @piped = []
    @colored = yes
    @timestamp = no
    @level = 0
    @paused = no
    for level of LEVELS
      do (level) =>
        @[level] = (message, parameters...) =>
          @log(@module, level, message, parameters...)

  colorize: (string, colors...) ->
    return string if !@colored or !colors? or colors.length == 0
    chain = CLIColor
    for color in colors
      chain = chain[color]
    return chain(string)

  log: (module, level, message, parameters...) ->
    log.log module, level, message, parameters... for log in @piped
    return unless LEVELS[level].level >= @level
    line = ''
    line += @colorize('[' + @now() + '] ', 'white') if @timestamp
    line += @colorize('[' + level.toUpperCase().substring(0,1) + ']', LEVELS[level].colors...)
    line += @colorize(' [' + module + ']', 'white') if module? and module isnt @module
    line += ' ' + @colorize(sprintf(message.toString(), parameters...), LEVELS[level].textColors...)
    @stream.write line + "\n", 'utf8' if @stream?
    
  now: ->
    new Date().toString()
    
  pipe: (log) ->
    @piped.push log
    return @

  bell: ->
    console.error '\u0007'