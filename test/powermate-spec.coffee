{describe,beforeEach,it,expect} = global
_         = require 'lodash'
sinon     = require 'sinon'
Powermate = require '../src/powermate'

describe 'Powermate', ->
  beforeEach ->
    @hid = {
      on: sinon.stub()
    }

    @HID = {
      devices: sinon.stub()
      HID: sinon.stub().returns @hid
    }

    @powermate = new Powermate { @HID }

  it 'should be an eventemitter', ->
    expect(@powermate.on).to.be.a 'function'

  describe '->connect', ->
    describe 'when there are no devices', ->
      beforeEach (done) ->
        @HID.devices.returns []
        @powermate.connect (@error) =>
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
        @powermate.connect (@error) =>
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
        @powermate.connect (@error) =>
          done()

      it 'should not have an error', ->
        expect(@error).to.not.exist

      it 'should get all of the devices', ->
        expect(@HID.devices).to.have.been.calledWith 1917, 1040

      it 'should construct HID with the path', ->
        expect(@HID.HID).to.have.been.calledWith 'some-unique-path'

      it 'should call on with read', ->
        expect(@hid.on).to.have.been.calledWith 'read'

      it 'should call on with error', ->
        expect(@hid.on).to.have.been.calledWith 'error'

  describe '->_onRead', ->
    describe 'when called with a button click', ->
      beforeEach (done) ->
        @clicked = false
        @powermate.on 'clicked', =>
          @clicked = true
          done()
        @powermate._onRead [1]

      it 'should emit the clicked', ->
        expect(@clicked).to.be.true

    describe 'when called with a button up', ->
      beforeEach (done) ->
        done = _.once done
        @clicked = false
        @powermate.on 'clicked', =>
          @clicked = true
          done()
        @powermate._onRead [0]
        _.delay done, 1000

      it 'should not emit the clicked', ->
        expect(@clicked).to.be.false

  describe '->_onError', ->
    describe 'when called with an error', ->
      beforeEach (done) ->
        @powermate.on 'error', (@error) => done()
        @powermate._onError new Error 'Oh no'

      it 'should emit the error', ->
        expect(@error).to.exist
        expect(@error.message).to.equal 'Oh no'

    describe 'when called without an error', ->
      beforeEach (done) ->
        done = _.once done
        @powermate.on 'error', (@error) => done()
        @powermate._onError null
        _.delay done, 1000

      it 'should not emit the error', ->
        expect(@error).to.not.exist
