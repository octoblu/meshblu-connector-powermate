_               = require 'lodash'
async           = require 'async'
{EventEmitter}  = require 'events'
Powermate       = require './powermate'
WebSocket              = require('ws')
debug           = require('debug')('meshblu-connector-powermate:index')

class Connector extends EventEmitter
  constructor: ({ @powermate, @interval } = {}) ->
    @interval ?= 5000
    @powermate ?= new Powermate
    @powermate.on 'error', @_onError
    @powermate.on 'click', @_onClick
    @powermate.on 'rotateLeft', @_onRotateLeft
    @powermate.on 'rotateRight', @_onRotateRight

  close: (callback) =>
    debug 'closing'
    @powermate.close()
    @wss?.close()
    @closed = true
    callback()

  die: (error) =>
    return process.exit(0) unless error?
    console.error('Powermate Connector Error', error)
    process.exit(1)

  isOnline: (callback) =>
    callback null, running: @powermate.isConnected()

  onConfig: (@device={}, callback=->) =>
    @powermate.config { rotationThreshold: _.get(@device, 'options.rotationThreshold') }
    @_restartWebsockets()
    return callback null unless _.get(@device, 'options.websocketEnable')

  start: (device, callback) =>
    debug '->start'
    @onConfig device
    async.doUntil @_connectAndDelay, @_isClosed, @die
    @_startWebsockets()
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

  _onClick: =>
    @_sendMessage 'click'

  _onRotateLeft: =>
    @_sendMessage 'rotateLeft'

  _onRotateRight: =>
    @_sendMessage 'rotateRight'

  _restartWebsockets: =>
    return unless @wss?
    @wss.close()
    @_startWebsockets()

  _sendMessage: (action) =>
    return debug "received '#{action}' but no device on scope" if _.isEmpty @device

    debug 'emitting message with action', action
    @emit 'message', {
      devices: ['*']
      data: { action, @device }
    }

    return unless @wss? && @wss.clients?

    @wss.clients.forEach (client) ->
      return unless client.readyState == WebSocket.OPEN
      client.send 'message', { data: { action } }

  _startWebsockets: =>
    { websocketEnable, websocketPort } = _.get @device, 'options', {}
    return @wss = { close: -> } unless websocketEnable && websocketPort?
    @wss = new WebSocket.Server { port: websocketPort }

module.exports = Connector
