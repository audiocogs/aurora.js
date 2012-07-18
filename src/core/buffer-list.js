void function (global) {
	'use strict'

	var bufferList = Aurora.extend(Aurora.object, 'Aurora::BufferList')

	bufferList.constructor = function (data, offset, byteLength) {
		Aurora.object.constructor.apply(this)

		this.buffers = [], this.availableBytes = 0, this.availableBuffers = 0

		this.first = null
	}

	bufferList.shift = function () {
		var result = this.buffers.shift()

		this.availableBytes -= result.length
		this.availableBuffers -= 1

		this.first = this.buffers[0]

		return result
	}

	bufferList.unshift = function (buffer) {
		this.buffers.unshift(buffer)

		this.availableBytes += buffer.length
		this.availableBuffers += 1

		this.first = buffer

		return this
	}

	bufferList.push = function (buffer) {
		this.buffers.push(buffer)

		this.availableBytes += buffer.length
		this.availableBuffers += 1

		this.first = this.first || buffer

		return this
	}

	Aurora.bufferList = bufferList
	Aurora.BufferList = bufferList.constructor

	Aurora.BufferList.prototype = bufferList
}(this)
