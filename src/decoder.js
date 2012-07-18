void function (global) {
	'use strict'

	var codecs = {}
	var decoder = Aurora.extend(Aurora.eventEmitter, 'Aurora::Decoder')

	decoder.constructor = function (demuxer, format) {
		Aurora.eventEmitter.constructor.apply(this)

		this.$.format = format

		var list = new Aurora.BufferList()

		this.$.stream = new Aurora.Stream(list)
		this.$.bitstream = new Aurora.BitStream(this.$.stream)

		this.receivedFinalBuffer = false

		demuxer.on('cookie', function (cookie) {
			this.setCookie(cookie)
		}.bind(this))

		demuxer.on('data', function (chunk, last) {
			this.receivedFinalBuffer = !!last

			list.push(chunk)

			setTimeout(function () {
				this.emit('available')
			}.bind(this), 0)
		}.bind(this))

		this.init() /* TODO: Why not use the constructor? */
	}

	decoder.constructor.probe = function (buffer) {
		return false
	}

	decoder.constructor.register = function (id, decoder) {
		codecs[id] = decoder
	}

	decoder.constructor.find = function (id) {
		return codecs[id]
	}

	decoder.init = function () { }
	decoder.setCookie = function (cookie) { }
	decoder.readChunk = function (chunk) { }
	decoder.seek = function (timestamp) { }

	Aurora.decoder = decoder
	Aurora.Decoder = decoder.constructor

	Aurora.Decoder.prototype = decoder
}(this)
