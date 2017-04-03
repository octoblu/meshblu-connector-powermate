{describe,beforeEach,it,expect} = global
_         = require 'lodash'
sinon     = require 'sinon'
Powermate = require '../src/powermate'

describe 'Powermate', ->
  beforeEach ->
    @hid = {
      read: sinon.stub()
    }

    @HID = {
      devices: sinon.stub()
      HID: sinon.stub().returns @hid
    }

    @sut = new Powermate { @HID }

  it 'should be an eventemitter', ->
    expect(@sut.on).to.be.a 'function'

  describe '->connect', ->
    describe 'when called and it is already connected', ->
      beforeEach (done) ->
        @sut.device = {exists: true}
        @sut.connect (@error) =>
          done()

      it 'should not have an error', ->
        expect(@error).to.not.exist

      it 'should not get all of the devices', ->
        expect(@HID.devices).to.not.have.been.calledWith 1917, 1040

    describe 'when there are no devices', ->
      beforeEach (done) ->
        @HID.devices.returns []
        @sut.connect (@error) =>
          done()

      it 'should it have the correct error', ->
        expect(@error).to.exist
        expect(@error.code).to.equal 404
        expect(@error.message).to.equal 'Powermate device not found'

      it 'should get all of the devices', ->
        expect(@HID.devices).to.have.been.calledWith 1917, 1040

    describe 'when there is more than one device', ->
      beforeEach (done) ->
        @HID.devices.returns [{}, {}]
        @sut.connect (@error) =>
          done()

      it 'should it have the correct error', ->
        expect(@error).to.exist
        expect(@error.code).to.equal 412
        expect(@error.message).to.equal 'More than one Powermate device found'

      it 'should get all of the devices', ->
        expect(@HID.devices).to.have.been.calledWith 1917, 1040

    describe 'when there is a device', ->
      beforeEach (done) ->
        @device = {
          path: 'some-unique-path'
        }
        @HID.devices.returns [@device]
        @sut.connect (@error) =>
          done()

      it 'should not have an error', ->
        expect(@error).to.not.exist

      it 'should get all of the devices', ->
        expect(@HID.devices).to.have.been.calledWith 1917, 1040

      it 'should construct HID with the path', ->
        expect(@HID.HID).to.have.been.calledWith 'some-unique-path'

      it 'should call read', ->
        expect(@hid.read).to.have.been.called

  describe '->_emitClicked', ->
    describe 'when called with a button click', ->
      beforeEach (done) ->
        @sut.device = { exists: true }
        @clicked = false
        @sut.on 'clicked', =>
          @clicked = true
          done()
        @sut._emitClicked [1]

      it 'should emit the clicked', ->
        expect(@clicked).to.be.true

    describe 'when called with a button up', ->
      beforeEach (done) ->
        @sut.device = { exists: true }
        done = _.once done
        @clicked = false
        @sut.on 'clicked', =>
          @clicked = true
          done()
        @sut._emitClicked [0]
        _.delay done, 1000

      it 'should not emit the clicked', ->
        expect(@clicked).to.be.false

    describe 'when called without a device', ->
      beforeEach (done) ->
        @sut.device = null
        done = _.once done
        @clicked = false
        @sut.on 'clicked', =>
          @clicked = true
          done()
        @sut._emitClicked [0]
        _.delay done, 1000

      it 'should not emit the clicked', ->
        expect(@clicked).to.be.false

  describe '->_emitError', ->
    describe 'when called with an error', ->
      beforeEach (done) ->
        @sut.device = { exists: true }
        @sut.on 'error', (@error) => done()
        @sut._emitError new Error 'Oh no'

      it 'should emit the error', ->
        expect(@error).to.exist
        expect(@error.message).to.equal 'Oh no'

    describe 'when called without an error', ->
      beforeEach (done) ->
        @sut.device = { exists: true }
        done = _.once done
        @sut.on 'error', (@error) => done()
        @sut._emitError null
        _.delay done, 1000

      it 'should not emit the error', ->
        expect(@error).to.not.exist

    describe 'when called without a device', ->
      beforeEach (done) ->
        @sut.device = null
        done = _.once done
        @sut.on 'error', (@error) => done()
        @sut._emitError null
        _.delay done, 1000

      it 'should not emit the error', ->
        expect(@error).to.not.exist

  describe '->isConnected', ->
    describe 'when connected', ->
      beforeEach ->
        @sut.device = { exists: true }

      it 'should return true', ->
        expect(@sut.isConnected()).to.be.true

    describe 'when not connected', ->
      beforeEach ->
        @sut.device = null

      it 'should return false', ->
        expect(@sut.isConnected()).to.be.false
