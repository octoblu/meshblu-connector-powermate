_              = require 'lodash'
{EventEmitter} = require 'events'
debug          = require('debug')('meshblu-connector-powermate:powermate')

class Powermate extends EventEmitter
  constructor: ({ @HID }={}) ->
    @HID ?= require 'node-hid'
    @_emitClicked = _.throttle @_unthrottledEmitClicked, 500, leading: true, trailing: false
    @_emitRotateLeft = _.noop
    @_emitRotateRight = _.noop

  connect: (callback) =>
    return callback null if @device?
    devices = @HID.devices(1917, 1040)
    if _.isEmpty devices
      return callback @_createError 404, 'Powermate device not found'
    if _.size(devices) > 1
      return callback @_createError 412, 'More than one Powermate device found'
    { path } = _.first(devices)
    @device = new @HID.HID path
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

  config: ({ @rotationThreshold }) =>
    @_emitRotateLeft = _.after @rotationThreshold, @_unthrottledEmitRotateLeft
    @_emitRotateRight = _.after @rotationThreshold, @_unthrottledEmitRotateRight

  isConnected: =>
    return @device?

  _createError: (code, message) =>
    error = new Error message
    error.code = code
    return error

  _emitError: (error) =>
    return unless @isConnected()
    return unless error?
    debug 'emit error', error
    @emit 'error', error
    @close()

  _onData: (data) =>
    debug '_onData', data
    @_emitClicked() if data[0] || (0x00 == data[1])
    @_emitRotateLeft() if data[1] == 0xff
    @_emitRotateRight() if data[1] == 0x01

  _unthrottledEmitClicked: =>
    debug 'clicked'
    @emit 'clicked'

  _unthrottledEmitRotateLeft: =>
    @_emitRotateLeft = _.after @rotationThreshold, @_unthrottledEmitRotateLeft
    debug 'rotateLeft'
    @emit 'rotateLeft'

  _unthrottledEmitRotateRight: =>
    @_emitRotateRight = _.after @rotationThreshold, @_unthrottledEmitRotateRight
    debug 'rotateRight'
    @emit 'rotateRight'

module.exports = Powermate
