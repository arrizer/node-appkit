#_require Core.EventEmitter

class UI.View extends Core.EventEmitter
  constructor: (args...) ->
    name = @constructor.name
    unless @el?
      template = $('#template_'+@constructor.name)
      if template.length > 0
        @el = $(template.html()) 
      else
        @el = $('<div></div>')
    proto = @
    while proto? and proto.constructor.name isnt 'EventEmitter'
      @el.addClass proto.constructor.name
      proto = proto.constructor.__super__
    @superview = null unless 'superview' of @
    @init(args...)
    
  init: ->
    
  my: (selector) ->
    @el.find '[data-my='+selector+']'
    
  add: (subview, selector, location = 'append') ->
    subview.superview = @
    container = @el
    container = @el.find(selector) if selector?
    container.append(subview.el) if location is 'append'
    container.prepend(subview.el) if location is 'prepend'
    container.before(subview.el) if location is 'before'
    container.after(subview.el) if location is 'after'
    
  destroy: ->
    @el.remove()
    
  bind: (entity, prefix = '') ->
    for property, value of entity
      do (property, value, entity) =>
        if value? and typeof(value) is 'object'
          @bind value, prefix+property+'.'
        else
          element = @el.find('[data-bind="'+prefix+property+'"]')
          if element?
            to = element.attr 'data-bind-to'
            to = 'text' unless to?
            def = element.attr 'data-bind-default'
            value = def if def? and !value?
            if to is 'text'
              element.text value 
            else if to is 'val'
              element.val value
            else if to is 'style'
              element.css element.attr('data-bind-to-style'), value 
            else if to is 'attr'
              element.attr element.attr('data-bind-to-attr'), value 
            else if to is 'visible'
              if value then element.show() else element.hide()
            else if to is 'prop'
              element.prop element.attr('data-bind-to-prop'), value if to is 'checked'
            from = element.attr 'data-bind-from'
            if from is 'textfield'
              element.bind 'keyup input paste change', =>
                value = element.val()
                entity[property] = value
                @emit 'bindchanged', property, value, prefix
            else if from is 'checkbox'
              element.change =>
                value = element.prop('checked')
                entity[property] = value
                @emit 'bindchanged', property, value, prefix
              
  
  @AnimateElement: (el, animation, duration, next) ->
    el.css 'animation', "#{animation} #{duration}s"
    setTimeout => 
      el.css 'animation', 'none'
      next() if next?
    , (duration * 1000)
  
  animate: (animation, duration, next) ->
    @constructor.AnimateElement @el, animation, duration, next
    
  setStyle: (style) ->
    @el.addClass 'style_' + @style if @style?
    @style = style
    @el.addClass 'style_' + style