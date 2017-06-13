_               = require 'lodash'
async           = require 'async'
{EventEmitter}  = require 'events'
Powermate       = require './powermate'
debug           = require('debug')('meshblu-connector-powermate:index')

class Connector extends EventEmitter
  constructor: ({ @powermate, @interval } = {}) ->
    @interval ?= 5000
    @powermate ?= new Powermate
    @powermate.on 'error', @_onError
    @powermate.on 'clicked', @_onClicked

  close: (callback) =>
    debug 'closing'
    @powermate.close()
    @closed = true
    callback()

  die: (error) =>
    return process.exit(0) unless error?
    console.error('Powermate Connector Error', error)
    process.exit(1)

  isOnline: (callback) =>
    callback null, running: @powermate.isConnected()

  onConfig: (@device={}, callback=->) =>
    callback null

  start: (@device, callback) =>
    debug 'started'
    async.doUntil @_connectAndDelay, @_isClosed, @die
    callback()

  _connectAndDelay: (callback) =>
    @powermate.connect (error) =>
      @_onError error if error?
      _.delay callback, @interval

  _isClosed: =>
    return @closed == true

  _onError: (error) =>
    debug 'on error', error?.toString() ? error
    @emit 'error', error

  _onClicked: =>
    return debug 'clicked but no device on scope' if _.isEmpty @device
    debug 'emitting clicked message'
    @emit 'message', {
      devices: ['*']
      data: {
        action: 'click'
        @device
      }
    }

module.exports = Connector
