void function (global) {
	'use strict'

	var formats = []
	var demuxer = Aurora.extend(Aurora.eventEmitter, 'Aurora::Demuxer')

	demuxer.constructor = function (source, chunk) {
		Aurora.eventEmitter.constructor.apply(this)

		var list = new Aurora.BufferList()
		list.push(chunk)

		this.$.stream = new Aurora.Stream(list)

		var received = false, self = this

		source.on('data', function (chunk) {
			received = true, list.push(chunk), this.readChunk(chunk)
		}.bind(this))

		source.on('error', function (err) {
			this.emit('error', err)
		}.bind(this))

		source.on('end', function () {
			if (!received) { this.readChunk() }

			this.emit('end')
		}.bind(this))

		this.init() /* TODO: Why not use the constructor? */
	}

	demuxer.constructor.probe = function (buffer) {
		return false
	}

	demuxer.constructor.register = function (demuxer) {
		formats.push(demuxer)
	}

	demuxer.constructor.find = function (buffer) {
		var stream = Aurora.Stream.fromBuffer(buffer)

		for (var i = 0; i < formats.length; i++) {
			if (formats[i].probe(stream)) {
				return formats[i]
			}
		}

		return null
	}

	demuxer.init = function () { }
	demuxer.readChunk = function (chunk) { }
	demuxer.seek = function (timestamp) { }

	Aurora.demuxer = demuxer
	Aurora.Demuxer = demuxer.constructor

	Aurora.Demuxer.prototype = demuxer
}(this)
