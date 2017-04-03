_              = require 'lodash'
{EventEmitter} = require 'events'

class Powermate extends EventEmitter
  constructor: ({ @HID }) ->
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
    @device.on 'read', @_onRead
    @device.on 'error', @_onError
    callback()

  close: (callback) =>
    return callback null unless @device?
    @device.close()
    @device = null

  isConnected: =>
    return @device?

  _onRead: (data) =>
    [clicked] = data
    return unless clicked
    @emit 'clicked'

  _onError: (error) =>
    return unless error?
    @emit 'error', error

  _createError: (code, message) =>
    error = new Error message
    error.code = code
    return error

module.exports = Powermate
