_               = require 'lodash'
{EventEmitter}  = require 'events'
PowerMate       = require 'node-powermate'
debug           = require('debug')('meshblu-connector-powermate:index')

class Connector extends EventEmitter
  constructor: ->

  isOnline: (callback) =>
    callback null, running: true

  close: (callback) =>
    debug 'on close'
    callback()

  onConfig: (@device={}) =>
    { @options } = @device
    debug 'on config', @options

  start: (@device, callback) =>
    debug 'started'
    callback()

module.exports = Connector
