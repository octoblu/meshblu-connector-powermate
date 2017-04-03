_               = require 'lodash'
async           = require 'async'
{EventEmitter}  = require 'events'
Powermate       = require '../src/powermate'
debug           = require('debug')('meshblu-connector-powermate:index')

class Connector extends EventEmitter
  constructor: ({ @powermate, @interval } = {}) ->
    @powermate ?= new Powermate
    @interval ?= 5000

  isOnline: (callback) =>
    callback null, running: @powermate.isConnected()

  close: (callback) =>
    debug 'on close'
    @powermate.close()
    @closed = true
    callback()

  onConfig: =>

  start: (device, callback) =>
    debug 'started'
    async.doUntil @_connectAndDelay, @_isClosed, @die
    callback()

  die: (error) =>
    return process.exit(0) unless error?
    console.error('Connector Error', error)
    process.exit(1)

  _isClosed: =>
    return @closed == true

  _connectAndDelay: (callback) =>
    @powermate.connect (error) =>
      return callback error if error?
      _.delay callback, @interval

module.exports = Connector
