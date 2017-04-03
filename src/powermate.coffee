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
    @device.read @_onRead
    debug('done')
    callback()

  close: (callback) =>
    return callback null unless @device?
    @device.close()
    @device = null

  isConnected: =>
    return @device?

  _onRead: (error, data) =>
    return @_emitError error if error?
    @_emitClicked data
    return unless @device?
    @device.read @_onRead

  _emitClicked: (data) =>
    return unless @device?
    [clicked] = data
    debug('emit read', { clicked })
    return unless clicked
    @emit 'clicked'

  _emitError: (error) =>
    return unless @device?
    debug('on error', error)
    return unless error?
    @emit 'error', error

  _createError: (code, message) =>
    error = new Error message
    error.code = code
    return error

module.exports = Powermate
