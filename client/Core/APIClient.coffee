class Core.APIClient
  BASE = '/api'
  
  request: (method, endpoint, data, next) ->
    unless next?
      next = data
      data = null
    options = 
      type: method
      url: BASE+endpoint
      success: (message, status) =>
        if message.success
          next null, message.response
        else
          next new Error(message.error) if next?
      error: (xhr, status, error) =>
        message = 'Unknown error'
        response = null
        response = JSON.parse(xhr.responseText) if xhr.responseText?
        if xhr.status is 0
          message = 'Could not connect to the server'
        else if xhr.status > 0
          message = 'HTTP Error ' + xhr.status + (if response? then ': ' + response.error else '')
        else if error is 'parsererror'
          message = 'Failed to parse server response'
        else if error is 'timeout'
          message = 'Request timed out'
        next message if next?
      dataType: 'json'
    if method is 'PUT' or method is 'POST'
      options.data = JSON.stringify(data)
      options.processData = no
      options.contentType = 'application/json'
    else
      options.data = data
    $.ajax options