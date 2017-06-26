{describe,beforeEach,it,expect} = global
_         = require 'lodash'
sinon     = require 'sinon'
Powermate = require '../src/powermate'
{EventEmitter} = require 'events'

describe 'Powermate', ->
  beforeEach ->
    @hid = new EventEmitter
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
        @device = new EventEmitter
        @device.path = 'some-unique-path'
        @HID.devices.returns [@device]
        @sut.connect (@error) =>
          done()

      it 'should not have an error', ->
        expect(@error).to.not.exist

      it 'should get all of the devices', ->
        expect(@HID.devices).to.have.been.calledWith 1917, 1040

      it 'should construct HID with the path', ->
        expect(@HID.HID).to.have.been.calledWith 'some-unique-path'

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

  describe '->close', ->
    describe 'when called with a connected device', ->
      beforeEach ->
        @device = {
          close: sinon.spy()
          removeAllListeners: sinon.spy()
        }
        @sut.device = @device
        @sut.close()

      it 'should call device.close', ->
        expect(@device.close).to.have.been.called

      it 'should call device.removeAllListeners', ->
        expect(@device.removeAllListeners).to.have.been.called

      it 'should not be connected', ->
        expect(@sut.isConnected()).to.be.false

    describe 'when called without a device', ->
      it 'should not throw an error', ->
        expect( =>
          @sut.close()
        ).to.not.throw

  describe 'event: "data"', ->
    beforeEach (done) ->
      @HID.devices.returns [{path: '/path/to/powermate'}]
      @sut.connect done

    describe 'when a non-button event is emitted', ->
      beforeEach ->
        @onClicked = sinon.spy()
        @sut.on 'clicked', @onClicked
        @hid.emit 'data', [0x00, 0xff, 0x00, 0x00, 0x00, 0x00]

      it 'should not emit a "clicked" event', (done) ->
        _.delay =>
          expect(@onClicked).not.to.have.been.called
          done()
        , 100

    describe 'when a button event is emitted', ->
      beforeEach ->
        @onClicked = sinon.spy()
        @sut.on 'clicked', @onClicked
        @hid.emit 'data', [0x01, 0x00, 0x00, 0x00, 0x00, 0x00]

      it 'should emit a "clicked" event', (done) ->
        _.delay =>
          expect(@onClicked).to.have.been.called
          done()
        , 100

    describe 'when a defective button click event is emitted', ->
      beforeEach ->
        @onClicked = sinon.spy()
        @sut.on 'clicked', @onClicked
        @hid.emit 'data', [0x00, 0x00, 0x00, 0x00, 0x00, 0x00]

      it 'should emit a "clicked" event', (done) ->
        _.delay =>
          expect(@onClicked).to.have.been.called
          done()
        , 100

    describe 'when a button event is emitted twice', ->
      beforeEach ->
        @onClicked = sinon.spy()
        @sut.on 'clicked', @onClicked
        @hid.emit 'data', [0x01, 0x00, 0x00, 0x00, 0x00, 0x00]
        @hid.emit 'data', [0x01, 0x00, 0x00, 0x00, 0x00, 0x00]

      it 'should emit only one "clicked" event', (done) ->
        _.delay =>
          expect(@onClicked).to.have.been.calledOnce
          done()
        , 100

    describe 'when a configured to rotate on 2 events', ->
      beforeEach ->
        @sut.config rotationThreshold: 2
        @onRotateLeft = sinon.spy()
        @sut.on 'rotateLeft', @onRotateLeft

      describe 'when one rotate event is emitted', ->
        beforeEach ->
          @hid.emit 'data', [0x00, 0xff, 0x00, 0x00, 0x00, 0x00]

        it 'should not emit a "rotateLeft" event', (done) ->
          _.delay =>
            expect(@onRotateLeft).not.to.have.been.called
            done()
          , 100

      describe 'when two rotate event are emitted', ->
        beforeEach ->
          @hid.emit 'data', [0x00, 0xff, 0x00, 0x00, 0x00, 0x00]
          @hid.emit 'data', [0x00, 0xff, 0x00, 0x00, 0x00, 0x00]

        it 'should emit a "rotateLeft" event', (done) ->
          _.delay =>
            expect(@onRotateLeft).to.have.been.called
            done()
          , 100

      describe 'when three rotate event are emitted', ->
        beforeEach ->
          @hid.emit 'data', [0x00, 0xff, 0x00, 0x00, 0x00, 0x00]
          @hid.emit 'data', [0x00, 0xff, 0x00, 0x00, 0x00, 0x00]
          @hid.emit 'data', [0x00, 0xff, 0x00, 0x00, 0x00, 0x00]

        it 'should emit exactly one "rotateLeft" event', (done) ->
          _.delay =>
            expect(@onRotateLeft).to.have.been.calledOnce
            done()
          , 100

    describe 'when a configured to rotate on 3 events', ->
      beforeEach ->
        @sut.config rotationThreshold: 3
        @onRotateLeft = sinon.spy()
        @sut.on 'rotateLeft', @onRotateLeft

      describe 'when two rotate event are emitted', ->
        beforeEach ->
          @hid.emit 'data', [0x00, 0xff, 0x00, 0x00, 0x00, 0x00]
          @hid.emit 'data', [0x00, 0xff, 0x00, 0x00, 0x00, 0x00]

        it 'should not emit a "rotateLeft" event', (done) ->
          _.delay =>
            expect(@onRotateLeft).not.to.have.been.called
            done()
          , 100

      describe 'when three rotate event are emitted', ->
        beforeEach ->
          @hid.emit 'data', [0x00, 0xff, 0x00, 0x00, 0x00, 0x00]
          @hid.emit 'data', [0x00, 0xff, 0x00, 0x00, 0x00, 0x00]
          @hid.emit 'data', [0x00, 0xff, 0x00, 0x00, 0x00, 0x00]

        it 'should emit a "rotateLeft" event', (done) ->
          _.delay =>
            expect(@onRotateLeft).to.have.been.calledOnce
            done()
          , 100

    describe 'when a configured to rotate on 2 events', ->
      beforeEach ->
        @sut.config rotationThreshold: 2
        @onRotateRight = sinon.spy()
        @sut.on 'rotateRight', @onRotateRight

      describe 'when one rotate event is emitted', ->
        beforeEach ->
          @hid.emit 'data', [0x00, 0x01, 0x00, 0x00, 0x00, 0x00]

        it 'should not emit a "rotateRight" event', (done) ->
          _.delay =>
            expect(@onRotateRight).not.to.have.been.called
            done()
          , 100

      describe 'when two rotate event are emitted', ->
        beforeEach ->
          @hid.emit 'data', [0x00, 0x01, 0x00, 0x00, 0x00, 0x00]
          @hid.emit 'data', [0x00, 0x01, 0x00, 0x00, 0x00, 0x00]

        it 'should emit a "rotateRight" event', (done) ->
          _.delay =>
            expect(@onRotateRight).to.have.been.called
            done()
          , 100

      describe 'when three rotate event are emitted', ->
        beforeEach ->
          @hid.emit 'data', [0x00, 0x01, 0x00, 0x00, 0x00, 0x00]
          @hid.emit 'data', [0x00, 0x01, 0x00, 0x00, 0x00, 0x00]
          @hid.emit 'data', [0x00, 0x01, 0x00, 0x00, 0x00, 0x00]

        it 'should emit exactly one "rotateRight" event', (done) ->
          _.delay =>
            expect(@onRotateRight).to.have.been.calledOnce
            done()
          , 100

    describe 'when a configured to rotate on 3 events', ->
      beforeEach ->
        @sut.config rotationThreshold: 3
        @onRotateRight = sinon.spy()
        @sut.on 'rotateRight', @onRotateRight

      describe 'when two rotate event are emitted', ->
        beforeEach ->
          @hid.emit 'data', [0x00, 0x01, 0x00, 0x00, 0x00, 0x00]
          @hid.emit 'data', [0x00, 0x01, 0x00, 0x00, 0x00, 0x00]

        it 'should not emit a "rotateRight" event', (done) ->
          _.delay =>
            expect(@onRotateRight).not.to.have.been.called
            done()
          , 100

      describe 'when three rotate event are emitted', ->
        beforeEach ->
          @hid.emit 'data', [0x00, 0x01, 0x00, 0x00, 0x00, 0x00]
          @hid.emit 'data', [0x00, 0x01, 0x00, 0x00, 0x00, 0x00]
          @hid.emit 'data', [0x00, 0x01, 0x00, 0x00, 0x00, 0x00]

        it 'should emit a "rotateRight" event', (done) ->
          _.delay =>
            expect(@onRotateRight).to.have.been.calledOnce
            done()
          , 100
