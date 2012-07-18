void function (global) {
	'use strict'

	var queue = Aurora.extend(Aurora.eventEmitter, 'Aurora::Queue', {
		buffers: { value: [] }
	})

	queue.constructor = function (decoder) {
		Aurora.eventEmitter.constructor.apply(this)

		this.$.decoder = decoder

		this.readyMark = 64
		this.finished = false
		this.buffering = true

		decoder.on('data', this.write.bind(this))

		decoder.readChunk()
	}

	queue.write = function (buffer) {
		if (buffer) { this.$.buffers.push(buffer) }

		if (this.buffering) {
			if ((this.$.buffers.length >= this.readyMark) || this.$.decoder.receivedFinalBuffer) {
				this.buffering = false

				this.emit('ready')
			} else {
				this.$.decoder.readChunk()
			}
		}
	}

	queue.read = function () {
		if (this.$.buffers.length == 0) { return null }

		this.$.decoder.readChunk()

		return this.$.buffers.shift()
	}

	Aurora.queue = queue
	Aurora.Queue = queue.constructor

	Aurora.Queue.prototype = queue
}(this)
