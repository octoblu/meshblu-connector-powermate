{describe,beforeEach,it,expect} = global
sinon     = require 'sinon'
Connector = require '../'

describe 'Connector', ->
  beforeEach ->
    @powermate =
      connect: sinon.stub()
      isConnected: sinon.stub()
    @sut = new Connector { @powermate }

  describe '->start', ->
    beforeEach (done) ->
      @powermate.connect.yields null
      @sut.start { uuid: true }, (@error) =>
        done()

    it 'should start without an error', ->
      expect(@error).to.not.exist

    it 'should call powermate connect', ->
      expect(@powermate.connect).to.have.been.called

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
