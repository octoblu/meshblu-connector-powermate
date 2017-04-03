{EventEmitter}  = require 'events'
debug           = require('debug')('meshblu-connector-powermate:index')
PowerMate       = require 'node-powermate'
_               = require 'lodash'

class Connector extends EventEmitter
  constructor: ->
    @_initialize()

  _initialize: ->
    try
      @powermate = new PowerMate
    catch error
      @emit 'error', error
      return

    @powermate.on 'buttonDown', () => @_handleButtonEvent 'down'
    @powermate.on 'buttonUp', () => @_handleButtonEvent 'up'
    # @powermate.on 'wheelTurn', @_handleWheel
    @powermate.on 'disconnected', @_disconnected


  _handleButtonEvent: (state) =>
    debug 'Button Event: ', state
    data = {
      action: 'click'
      state
    }
    data.device = @device if state == 'up'
    @emit 'message', {devices: ['*'], data}

  _handleWheel: (delta) =>
    debug 'Wheel Change', delta


  # _setBrightness: () =>
  #   brightness = _.get @options, 'brightness', 255
  #   @powermate.setBrightness brightness, (error) =>
  #     @emit 'error', error if error?

  _disconnected: () =>
    debug 'Disconnected'
    @_initialize()

  isOnline: (callback) =>
    callback null, running: true

  close: (callback) =>
    debug 'on close'

  onConfig: (@device={}) =>
    { @options } = @device
    debug 'on config', @options
    # @_setBrightness()

  start: (device, callback) =>
    debug 'started'
    @onConfig device
    callback()

module.exports = Connector
