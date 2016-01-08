module.exports = class Model
  @deserialize: (data) ->
    object = new @()
    for property,value of data
      unless property is '_class'
        object[property] = value 
    object.awake()
    return object
    
  create: ->
    
  awake: ->
  
  destroy: ->
    
  serialize: ->
    data = {}
    data[property] = value for property,value of @
    return data