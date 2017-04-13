_              = require 'lodash'
{EventEmitter} = require 'events'
debug          = require('debug')('meshblu-connector-powermate:powermate')

class Powermate extends EventEmitter
  constructor: ({ @HID }={}) ->
    @HID ?= require 'node-hid'

  connect: (callback) =>
    return callback null if @device?
    devices = @HID.devices(1917, 1040)
    if _.isEmpty devices
      return callback @_createError 404, 'Powermate device not found'
    if _.size(devices) > 1
      return callback @_createError 412, 'More than one Powermate device found'
    { path } = _.first(devices)
    @device = new @HID.HID path
    @_throttledEmitClicked = _.throttle @_emitClicked, 1000, leading: true, trailing: false
    @device.on 'data', @_onData
    @device.once 'error', (error) =>
      @_emitError error
      @close()
    debug 'connected to device', { path }
    callback()

  close: =>
    return unless @isConnected()
    @device.close()
    @device.removeAllListeners()
    @device = null

  isConnected: =>
    return @device?

  _onData: (data) =>
    debug 'data', data
    return unless @isConnected()
    [clicked] = data
    return unless clicked
    @_throttledEmitClicked data

  _emitClicked: =>
    debug 'clicked'
    @emit 'clicked'

  _emitError: (error) =>
    return unless @isConnected()
    return unless error?
    debug 'emit error', error
    @emit 'error', error
    @close()

  _createError: (code, message) =>
    error = new Error message
    error.code = code
    return error

module.exports = Powermate
