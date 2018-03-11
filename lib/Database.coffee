Path       = require 'path'
FileSystem = require 'fs'
Log        = require './Log'

filter = (objects, predicate) ->
  filtered = []
  for object in objects
    match = yes
    for property, value of predicate
      match = no if object[property].toString() isnt value.toString()
    filtered.push object if match
  return filtered
  
sort = (objects, descriptors) ->
  

module.exports = class Database
  constructor: (@filename, @modelClasses) ->
    @log = Log.Module(@constructor.name + ' ' + Path.basename(@filename, '.json'))
    @objects = {}
    @nextID = 1
  
  load: (next) ->
    FileSystem.exists @filename, (exists) =>
      if exists
        FileSystem.readFile @filename, (error, data) =>
          return next error if error?
          data = data.toString()
          try
            data = JSON.parse(data)
          catch error
            throw new Error("Failed to parse #{@filename}: #{error}")
          @deserialize(data)
          next()
      else
        @log.debug 'Database file not present'
        next()
        
  deserialize: (data) ->
    @objects = {}
    objectCount = 0
    for id,objectData of data
      className = objectData._class
      Class = null
      for ModelClass in @modelClasses
        if ModelClass.name is className
          Class = ModelClass
          break
      throw new Error('Unknown class in database: ' + className) unless Class?
      object = Class.deserialize objectData
      @objects[className] = {} unless @objects[className]?
      @objects[className][object.id] = object
      objectCount++
    for className, objects of @objects
      for id,object of objects
        @nextID = Math.max(@nextID, id) 
    @log.debug 'Database loaded. %f objects.', objectCount
  
  save: (next) ->
    return if @saving
    @saving = yes
    data = JSON.stringify(@serialize())
    FileSystem.writeFile @filename + '.atomic', data, (error) =>
      if !error?
        FileSystem.renameSync @filename + '.atomic', @filename
        @saving = no
        next() if next?
      else
        @log.error "Failed to save database: #{error}"
        @saving = no
        
  serialize: ->
    data = {}
    for className, objects of @objects
      for id,object of objects
        data[object.id] = object.serialize()
        data[object.id]._class = className
    return data
    
  get: (Class, predicate, order) ->
    className = Class.name
    result = []
    if @objects[className]?
      for id,object of @objects[className]
        result.push object
    result = filter(result, predicate) if predicate?
    return result
    
  getFirst: (Class, predicate, order) ->
    objects = @get Class, predicate, order
    if objects.length >= 1 then return objects[0] else return null

  add: (object) ->
    id = ++@nextID
    object.id = id
    className = object.constructor.name
    @objects[className] = {} unless @objects[className]?
    @objects[className][id] = object 
    object.awake()
    return object
    
  del: (object) ->
    className = object.constructor.name
    delete @objects[className][object.id]