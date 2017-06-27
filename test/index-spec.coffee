{afterEach, beforeEach, describe, it } = global
{ expect } = require 'chai'
{ EventEmitter } = require 'events'
_         = require 'lodash'
sinon     = require 'sinon'
Websocket = require 'ws'
Connector = require '../src/'

describe 'Connector', ->
  beforeEach (done) ->
    @powermate = new EventEmitter
    @powermate.connect = sinon.stub()
    @powermate.close = sinon.spy()
    @powermate.isConnected = sinon.stub()
    @powermate.config = sinon.spy()
    @sut = new Connector { @powermate, interval: 10 }
    @sut.start uuid: 'device-uuid', done

  describe 'powermate "error"', ->
    beforeEach ->
      @onError = sinon.spy()
      @sut.on 'error', @onError
      @powermate.emit 'error', new Error('whoops')

    it 'should proxy the powermate error', ->
      expect(@onError).to.have.been.called

  describe 'powermate "click"', ->
    beforeEach ->
      @onMessage = sinon.spy()
      @sut.on 'message', @onMessage
      @powermate.emit 'click'

    it 'should send a click message', ->
      expect(@onMessage).to.have.been.calledWith({
        devices: ['*']
        data:
          action: 'click'
          device:
            uuid: 'device-uuid'
      })

  describe '->start', ->
    describe 'when it starts and closes', ->
      beforeEach (done) ->
        @sut.die = sinon.stub()
        @powermate.connect.yields null
        @sut.start { uuid: true, options: { rotationThreshold: 3 } }, (@error) =>
          @sut.close (error) =>
            return done error if error?
            _.delay done, 100

      it 'should start without an error', ->
        expect(@error).to.not.exist

      it 'should call powermate config with the configuration', ->
        expect(@powermate.config).to.have.been.calledWith { rotationThreshold: 3 }

      it 'should call powermate connect', ->
        expect(@powermate.connect).to.have.been.called

      it 'should call ->die', ->
        expect(@sut.die).to.have.been.called

      it 'should be closed', ->
        expect(@sut.closed).to.be.true

    describe 'when it starts and errors on connect', ->
      beforeEach (done) ->
        done = _.once done
        @sut.die = sinon.stub()
        @powermate.connect.yields new Error 'oh-no'
        @sut.on 'error', (@error) => done()
        @sut.start { uuid: true }, (@startError) =>
          return done @startError if @startError?
          _.delay done, 500

      it 'should not return an error on start', ->
        expect(@startError).to.not.exist

      it 'should emit an error', ->
        expect(@error).to.exist

      it 'should call powermate connect', ->
        expect(@powermate.connect).to.have.been.called

      it 'should not call die', ->
        expect(@sut.die).to.not.have.been.called

  describe '->onConfig', ->
    describe 'when called with an object', ->
      beforeEach 'call onConfig', ->
        @sut.onConfig { uuid: 'yeso', options: { rotationThreshold: 9 } }

      it 'should set the device on the sut', ->
        expect(@sut.device).to.deep.equal { uuid: 'yeso', options: { rotationThreshold: 9 } }

      it 'should call powermate config with the configuration', ->
        expect(@powermate.config).to.have.been.calledWith { rotationThreshold: 9 }

    describe 'when called without an object', ->
      it 'should throw an error', ->
        expect(=>
          @sut.onConfig()
        ).to.not.throw

    describe 'when started', ->
      beforeEach 'start', (done) ->
        @sut.start {}, done

      afterEach 'close', (done) ->
        @sut.close done

      describe 'when called with websocketEnable: true and websocketPort: 23000', ->
        beforeEach 'call onConfig', ->
          @sut.onConfig {
            uuid: 'yeso',
            options: {
              websocketEnable: true
              websocketPort: 23000
            }
          }

        it 'should create a websocket server', (done) ->
          ws = new Websocket "ws://localhost:23000"
          ws.on 'open', ->
            ws.close()
            done()

        describe 'with a websocket connection', ->
          beforeEach 'connect websocket', (done) ->
            @ws = new Websocket "ws://localhost:23000"
            @ws.on 'open', done

          describe 'when a rotateLeft event is emitted', ->
            beforeEach ->
              @onMessage = sinon.spy()
              @ws.on 'message', @onMessage
              @powermate.emit 'rotateLeft'

            it 'should emit a rotateLeft message on the websocket', (done) ->
              _.delay =>
                expect(@onMessage).to.have.been.called
                done()
              , 100

      describe 'when called with websocketEnable: true and websocketPort: 23000...twice', ->
        beforeEach 'call onConfig', ->
          @sut.onConfig {
            uuid: 'yeso',
            options: {
              websocketEnable: true
              websocketPort: 23000
            }
          }
          @sut.onConfig {
            uuid: 'yeso',
            options: {
              websocketEnable: true
              websocketPort: 23000
            }
          }

        it 'should create a websocket server', (done) ->
          ws = new Websocket "ws://localhost:23000"
          ws.on 'open', ->
            ws.close()
            done()

  describe '->isOnline', ->
    describe 'when connected', ->
      beforeEach (done) ->
        @powermate.isConnected.returns true
        @sut.isOnline (error, @result) =>
          done error

      it 'should called isConnected on powermate', ->
        expect(@powermate.isConnected).to.have.been.called

      it 'should have running true', ->
        expect(@result.running).to.be.true

    describe 'when not connected', ->
      beforeEach (done) ->
        @powermate.isConnected.returns false
        @sut.isOnline (error, @result) =>
          done error

      it 'should called isConnected on powermate', ->
        expect(@powermate.isConnected).to.have.been.called

      it 'should have running true', ->
        expect(@result.running).to.be.false

  describe '->close', ->
    beforeEach (done) ->
      @sut.close done

    it 'should call close on powermate', ->
      expect(@powermate.close).to.have.been.called

    it 'should set the closed property', ->
      expect(@sut.closed).to.be.true

  describe '->_onError', ->
    describe 'when called without an error', ->
      it 'should not throw an error', ->
        expect(=>
          @sut._onError null
        ).to.not.throw

    describe 'when called with an error', ->
      beforeEach (done) ->
        @sut.on 'error', (@error) =>
          done()
        @sut._onError new Error 'oh-no'

      it 'should emit an error', ->
        expect(@error).to.exist
        expect(@error.message).to.equal 'oh-no'

  describe '->_onClick', ->
    describe 'when called with a device on the sut', ->
      beforeEach (done) ->
        @sut.device = { uuid: 'should-be-this' }
        @sut.on 'message', (@message) => done()
        @sut._onClick()

      it 'should emit a message', ->
        expect(@message).to.deep.equal {
          devices: ['*']
          data:
            device: { uuid: 'should-be-this' }
            action: 'click'
        }

    describe 'when called without a device on the sut', ->
      beforeEach (done) ->
        done = _.once done
        @sut.device = null
        @sut.on 'message', (@message) => done()
        @sut._onClick()
        _.delay done, 500

      it 'should not emit a message', ->
        expect(@message).to.not.exist
