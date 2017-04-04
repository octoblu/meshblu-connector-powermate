{describe,beforeEach,it,expect} = global
_         = require 'lodash'
sinon     = require 'sinon'
Connector = require '../'

describe 'Connector', ->
  beforeEach ->
    @powermate =
      connect: sinon.stub()
      close: sinon.spy()
      isConnected: sinon.stub()
      on: sinon.stub()
    @sut = new Connector { @powermate, interval: 10 }

  it 'should listen on powermate error', ->
    expect(@powermate.on).to.have.been.calledWith 'error'

  it 'should listen on powermate clicked', ->
    expect(@powermate.on).to.have.been.calledWith 'clicked'

  describe '->start', ->
    describe 'when it starts and closes', ->
      beforeEach (done) ->
        @sut.die = sinon.stub()
        @powermate.connect.yields null
        @sut.start { uuid: true }, (@error) =>
          @sut.close (error) =>
            return done error if error?
            _.delay done, 100

      it 'should start without an error', ->
        expect(@error).to.not.exist

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
      it 'should not throw an error', ->
        expect(=>
          @sut.onConfig { uuid: true }
        ).to.not.throw

      it 'should set the device on the sut', ->
        @sut.onConfig { uuid: 'yeso' }
        expect(@sut.device).to.deep.equal { uuid: 'yeso' }

    describe 'when called without an object', ->
      it 'should throw an error', ->
        expect(=>
          @sut.onConfig()
        ).to.not.throw

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

  describe '->_onClicked', ->
    describe 'when called with a device on the sut', ->
      beforeEach (done) ->
        @sut.device = { uuid: 'should-be-this' }
        @sut.on 'message', (@message) => done()
        @sut._onClicked()

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
        @sut._onClicked()
        _.delay done, 500

      it 'should not emit a message', ->
        expect(@message).to.not.exist
