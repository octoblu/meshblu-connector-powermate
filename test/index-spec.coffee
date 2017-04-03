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
    @sut = new Connector { @powermate, interval: 10 }

  describe '->start', ->
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

  describe '->onConfig', ->
    describe 'when called with an object', ->
      it 'should not throw an error', ->
        expect(=>
          @sut.onConfig { uuid: true }
        ).to.not.throw

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
