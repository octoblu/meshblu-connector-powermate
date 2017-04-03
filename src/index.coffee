# _               = require 'lodash'
{EventEmitter}  = require 'events'
Powermate       = require '../src/powermate'
debug           = require('debug')('meshblu-connector-powermate:index')

class Connector extends EventEmitter
  constructor: ({ @powermate } = {}) ->
    @powermate ?= new Powermate

  isOnline: (callback) =>
    callback null, running: @powermate.isConnected()

  close: (callback) =>
    debug 'on close'
    callback()

  onConfig: (@device={}) =>
    { @options } = @device
    debug 'on config', @options

  start: (@device, callback) =>
    debug 'started'
    @powermate.connect callback

module.exports = Connector
