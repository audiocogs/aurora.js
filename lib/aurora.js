/*
 * Copyright (c) 2012, Jens Nockert, Devon Govett
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

void function (global) {
	"use strict";

	global.Aurora = {}
}(this)

void function (global) {
	'use strict'

	Aurora.object = Object.create({}, {
		$: { value: {}, configurable: true },
		typename: { value: 'Aurora::Object', enumerable: true, configurable: true },
		prototype: {
			get: function () {
				return Object.getPrototypeOf(this)
			},
			enumerable: true
		}
	})

	Aurora.object.constructor = function () {
		Object.defineProperty(this, '$', { value: this.prototype.$.__cs_clone(2) })
	}

	Aurora.object.clone = function (depth) {
		var result = Object.create(Object.getPrototypeOf(this))

		var keys = Object.getOwnPropertyNames(this), remaining = depth ? depth - 1 : 0

		if (remaining > 0) {
			for (var i = 0; i < keys.length; i++) {
				var descriptor = Object.getOwnPropertyDescriptor(this, keys[i])

				if (descriptor.value && descriptor.value.__cs_clone) {
					descriptor.value = descriptor.value.__cs_clone(remaining)
				}

				Object.defineProperty(result, keys[i], descriptor)
			}
		} else {
			for (var i = 0; i < keys.length; i++) {
				Object.defineProperty(result, keys[i], Object.getOwnPropertyDescriptor(this, keys[i]))
			}
		}

		/* TODO: Check for Frozen, Sealed, Non-Extensible? */

		return result
	}

	Object.defineProperty(Object.prototype, '__cs_clone', { value: Aurora.object.clone })
	Object.defineProperty(Array.prototype, '__cs_clone', { value: Array.prototype.slice })

	var cloneTypedArray = function (depth) {
		if (depth > 1) {
			var result = new this.constructor(this.length)
			
			result.set(this)
			
			return result
		} else {
			return this.subarray(0)
		}
	}

	Object.defineProperty(Uint8Array.prototype, '__cs_clone', { value: cloneTypedArray })
	Object.defineProperty(Uint8ClampedArray.prototype, '__cs_clone', { value: cloneTypedArray })
	Object.defineProperty(Uint16Array.prototype, '__cs_clone', { value: cloneTypedArray })
	Object.defineProperty(Uint32Array.prototype, '__cs_clone', { value: cloneTypedArray })

	Object.defineProperty(Int8Array.prototype, '__cs_clone', { value: cloneTypedArray })
	Object.defineProperty(Int16Array.prototype, '__cs_clone', { value: cloneTypedArray })
	Object.defineProperty(Int32Array.prototype, '__cs_clone', { value: cloneTypedArray })

	Object.defineProperty(Float32Array.prototype, '__cs_clone', { value: cloneTypedArray })
	Object.defineProperty(Float64Array.prototype, '__cs_clone', { value: cloneTypedArray })

	Object.defineProperty(Date.prototype, '__cs_clone', { value: function () {
		return new Date(this)
	}})

	Aurora.extend = function (type, name, privateProperties, properties) {
		var result = Object.create(Object.getPrototypeOf(type), properties || {})
		var keys = Object.getOwnPropertyNames(type), dollar = type.$.__cs_clone(2)

		for (var i = 0; i < keys.length; i++) {
			if (keys[i] != '$' && keys[i] != 'typename') {
				Object.defineProperty(result, keys[i], Object.getOwnPropertyDescriptor(type, keys[i]))
			}
		}

		Object.defineProperties(dollar, privateProperties || {})

		Object.defineProperty(result, '$', { value: dollar })
		Object.defineProperty(result, 'typename', { value: name, enumerable: true })

		return result
	}
}(this)

void function (global) {
	'use strict'

	var buffer = Aurora.extend(Aurora.object, 'Aurora::Buffer')

	buffer.constructor = function (data, offset, byteLength) {
		Aurora.object.constructor.apply(this)

		var off = offset ? offset : 0

		if (!byteLength || byteLength > data.byteLength - off) {
			this.view = new DataView(data, off)
		} else {
			this.view = new DataView(data, off, byteLength)
		}

		this.$.data = data

		this.length = this.view.byteLength
	}

	buffer.constructor.allocate = function (n) {
		return new Aurora.Buffer(new ArrayBuffer(n))
	}

	buffer.slice = function (position, length) {
		if (position == 0 && length >= this.length) {
			return new Aurora.Buffer(this.$.data)
		} else {
			return new Aurora.Buffer(this.$.data, position, length)
		}
	}

	/* TODO: Is this really the right place for blob work? */
	buffer.constructor.makeBlobURL = function (data) {
		return URL.createObjectURL(new Blob([data]))
	}

	buffer.constructor.revokeBlobURL = function (url) {
		URL.revokeBlobURL(url)
	}

	Aurora.buffer = buffer
	Aurora.Buffer = buffer.constructor

	Aurora.Buffer.prototype = buffer
}(this)

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


void function (global) {
	'use strict'

	var unalignedBuffer = new ArrayBuffer(16)
	var unalignedBytes = new Uint8Array(unalignedBuffer)
	var unalignedView = new DataView(unalignedBuffer)

	var stream = Aurora.extend(Aurora.object, 'Aurora::Stream', {
		offset: { value: 0, writable: true },
		localOffset: { value: 0, writable: true }
	})

	stream.constructor = function (list) {
		Aurora.object.constructor.apply(this)

		this.$.list = list
	}

	stream.constructor.fromBuffer = function (buffer) {
		var list = new Aurora.BufferList()

		list.push(buffer)

		return new Aurora.Stream(list)
	}
	
	stream.available = function (n) {
		return n <= this.$.list.availableBytes - this.$.localOffset
	}

	stream.remainingBytes = function () {
		return this.$.list.availableBytes
	}

	stream.advance = function (n) {
		this.$.offset += n; this.$.localOffset += n

		while (this.$.list.first && (this.$.localOffset >= this.$.list.first.length)) {
			this.$.localOffset -= this.$.list.shift().length
		}

		return this
	}

	stream.read = function (n) {
		for (var i = 0; i < n; i++) {
			unalignedBytes[i] = this.readUInt8()
		}
	}

	stream.readUInt8 = function () {
		var a = this.$.list.first.view.getUint8(this.$.localOffset)

		this.$.offset += 1; this.$.localOffset += 1

		if (this.$.localOffset == this.$.list.first.length) {
			this.$.localOffset = 0; this.$.list.shift()
		}

		return a
	}

	stream.readUInt16 = function (littleEndian) {
		if (2 < this.$.list.first.length - this.$.localOffset) {
			var a = this.$.list.first.view.getUint16(this.$.localOffset, littleEndian)

			this.$.offset += 2; this.$.localOffset += 2

			if (this.$.localOffset == this.$.list.first.length) {
				this.$.localOffset = 0; this.$.list.shift()
			}

			return a
		} else {
			this.read(2); return unalignedView.getUint16(0, littleEndian)
		}
	}

	stream.readUInt24 = function (littleEndian) {
		if (3 < this.$.list.first.length - this.$.localOffset) {
			var a = this.$.list.first.view.getUint8(this.$.localOffset + 0)
			var b = this.$.list.first.view.getUint8(this.$.localOffset + 1)
			var c = this.$.list.first.view.getUint8(this.$.localOffset + 2)

			this.$.offset += 3; this.$.localOffset += 3

			if (this.$.localOffset == this.$.list.first.length) {
				this.$.localOffset = 0; this.$.list.shift()
			}
		} else {
			this.read(3);
			
			var a = unalignedView.getUint8(0)
			var a = unalignedView.getUint8(1)
			var a = unalignedView.getUint8(2)
		}
		
		if (littleEndian) {
			return (a << 0) | (b << 8) | (c << 16)
		} else {
			return (c << 0) | (b << 8) | (a << 16)
		}
	}

	stream.readUInt32 = function (littleEndian) {
		if (4 < this.$.list.first.length - this.$.localOffset) {
			var a = this.$.list.first.view.getUint32(this.$.localOffset, littleEndian)

			this.$.offset += 4; this.$.localOffset += 4

			if (this.$.localOffset == this.$.list.first.length) {
				this.$.localOffset = 0; this.$.list.shift()
			}

			return a
		} else {
			this.read(4); return unalignedView.getUint32(0, littleEndian)
		}
	}

	stream.readInt8 = function () {
		var a = this.$.list.first.view.getInt8(this.$.localOffset)

		this.$.offset += 1; this.$.localOffset += 1

		if (this.$.localOffset == this.$.list.first.length) {
			this.$.localOffset = 0; this.$.list.shift()
		}

		return a
	}

	stream.readInt16 = function (littleEndian) {
		if (2 < this.$.list.first.length - this.$.localOffset) {
			var a = this.$.list.first.view.getInt16(this.$.localOffset, littleEndian)

			this.$.offset += 2; this.$.localOffset += 2

			if (this.$.localOffset == this.$.list.first.length) {
				this.$.localOffset = 0; this.$.list.shift()
			}

			return a
		} else {
			this.read(2); return unalignedView.getInt16(0, littleEndian)
		}
	}

	stream.readInt24 = function (littleEndian) {
		if (3 < this.$.list.first.length - this.$.localOffset) {
			var a = this.$.list.first.view.getUint8(this.$.localOffset + 0)
			var b = this.$.list.first.view.getUint8(this.$.localOffset + 1)
			var c = this.$.list.first.view.getUint8(this.$.localOffset + 2)

			this.$.offset += 3; this.$.localOffset += 3

			if (this.$.localOffset == this.$.list.first.length) {
				this.$.localOffset = 0; this.$.list.shift()
			}
		} else {
			this.read(3);
			
			var a = unalignedView.getUint8(0)
			var a = unalignedView.getUint8(1)
			var a = unalignedView.getUint8(2)
		}
		
		if (littleEndian) {
			return (a << 0) | (b << 8) | ((c << 24) >> 8)
		} else {
			return (c << 0) | (b << 8) | ((a << 24) >> 8)
		}
	}

	stream.readInt32 = function (littleEndian) {
		if (4 < this.$.list.first.length - this.$.localOffset) {
			var a = this.$.list.first.view.getInt32(this.$.localOffset, littleEndian)

			this.$.offset += 4; this.$.localOffset += 4

			if (this.$.localOffset == this.$.list.first.length) {
				this.$.localOffset = 0; this.$.list.shift()
			}

			return a
		} else {
			this.read(4); return unalignedView.getInt32(0, littleEndian)
		}
	}

	stream.readFloat32 = function (littleEndian) {
		if (4 < this.$.list.first.length - this.$.localOffset) {
			var a = this.$.list.first.view.getFloat32(this.$.localOffset, littleEndian)

			this.$.offset += 4; this.$.localOffset += 4

			if (this.$.localOffset == this.$.list.first.length) {
				this.$.localOffset = 0; this.$.list.shift()
			}

			return a
		} else {
			this.read(4); return unalignedView.getFloat32(0, littleEndian)
		}
	}

	stream.readFloat64 = function (littleEndian) {
		if (8 < this.$.list.first.length - this.$.localOffset) {
			var a = this.$.list.first.view.getFloat64(this.$.localOffset, littleEndian)

			this.$.offset += 8; this.$.localOffset += 8

			if (this.$.localOffset == this.$.list.first.length) {
				this.$.localOffset = 0; this.$.list.shift()
			}

			return a
		} else {
			this.read(8); return unalignedView.getFloat64(0, littleEndian)
		}
	}

	stream.readString = function (n) {
		var result = []

		for (var i = 0; i < n; i++) {
			result.push(String.fromCharCode(this.readUInt8()))
		}

		return result.join('')
	}

	stream.readUTF8 = function (n) {
		/* TODO: Does this always work? */
		return decodeURIComponent(escape(this.readString(length)))
	}

	stream.readBuffer = function (n) {
		var result = new Aurora.Buffer.allocate(n)

		for (var i = 0; i < n; i++) {
			result.view.setUint8(i, this.readUInt8())
		}

		return result
	}

	stream.readSingleBuffer = function (n) {
		var result = this.$.list.first.slice(this.$.localOffset, n)

		this.advance(result.length)

		return result
	}

	stream.peek = function (offset, n) {
		for (var i = 0; i < n; i++) {
			unalignedBytes[i] = this.peekUInt8(offset + i)
		}
	}

	stream.peekUInt8 = function (offset) {
		var offset = this.$.localOffset + offset
		var list = this.$.list.buffers

		for (var i = 0; i < list.length; i++) {
			if (list[i].length > offset) {
				return list[i].view.getUint8(offset)
			}

			offset -= list[i].length
		}
		
		return 0 /* TODO: Semantics Unclear? */
	}

	stream.peekString = function (offset, n) {
		var result = []

		for (var i = 0; i < n; i++) {
			result.push(String.fromCharCode(this.peekUInt8(offset + i)))
		}

		return result.join('')
	}
//    peekInt8: (offset = 0) ->
//        @peek(1, offset)
//        return int8[0]
//        
//    peekUInt16: (offset = 0, littleEndian) ->
//        @peek(2, offset, littleEndian)
//        return uint16[0]
//
//    peekInt16: (offset = 0, littleEndian) ->
//        @peek(2, offset, littleEndian)
//        return int16[0]
//
//    peekUInt24: (offset = 0, littleEndian) ->
//        if littleEndian
//            return @peekUInt16(offset, true) + (@peekUInt8(offset + 2) << 16)
//        else
//            return (@peekUInt16(offset) << 8) + @peekUInt8(offset + 2)
//
//    peekInt24: (offset = 0, littleEndian) ->
//        if littleEndian
//            return @peekUInt16(offset, true) + (@peekInt8(offset + 2) << 16)
//        else
//            return (@peekInt16(offset) << 8) + @peekUInt8(offset + 2)
//    
//    peekUInt32: (offset = 0, littleEndian) ->
//        @peek(4, offset, littleEndian)
//        return uint32[0]
//    
//    peekInt32: (offset = 0, littleEndian) ->
//        @peek(4, offset, littleEndian)
//        return int32[0]
//    
//    peekFloat32: (offset = 0, littleEndian) ->
//        @peek(4, offset, littleEndian)
//        return float32[0]
//    
//    peekFloat64: (offset = 0, littleEndian) ->
//        @peek(8, offset, littleEndian)
//        
//        # use Float64Array if available
//        if float64
//            return float64[0]
//        else
//            return float64Fallback()
//        
//    # IEEE 80 bit extended float
//    readFloat80: (littleEndian) ->
//        @read(10, littleEndian)
//        return float80()
//        
//    float80 = ->
//        [high, low] = uint32
//        a0 = uint8[9]
//        a1 = uint8[8]
//        
//        sign = 1 - (a0 >>> 7) * 2 # -1 or +1
//        exp = ((a0 & 0x7F) << 8) | a1
//        
//        if exp is 0 and low is 0 and high is 0
//            return 0
//            
//        if exp is 0x7fff
//            if low is 0 and high is 0
//                return sign * Infinity
//                
//            return NaN
//        
//        exp -= 16383
//        out = low * Math.pow(2, exp - 31)
//        out += high * Math.pow(2, exp - 63)
//        
//        return sign * out
//        
//    peekFloat80: (offset = 0, littleEndian) ->
//        @peek(10, offset, littleEndian)
//        return float80()
//    
//    peekUTF8: (offset, length) ->
//        return decodeURIComponent escape @peekString(offset, length)
//    
//    peekBuffer: (offset = 0, length) ->
//        result = Buffer.allocate(length)
//        to = result.data
//        
//        for i in [0...length] by 1
//            to[i] = @peekUInt8(offset + i)
//        
//        return result
//    
//    peekSingleBuffer: (length) ->
//        result = @list.first.slice(@localOffset, length)
//        return result

	Aurora.stream = stream
	Aurora.Stream = stream.constructor

	Aurora.Stream.prototype = stream
}(this)

void function (global) {
	'use strict'

	var bitMask = [
		0x00000000, 0x00000001, 0x00000003, 0x00000007,
		0x0000000f, 0x0000001f, 0x0000003f, 0x0000007f,
		0x000000ff, 0x000001ff, 0x000003ff, 0x000007ff,
		0x00000fff, 0x00001fff, 0x00003fff, 0x00007fff,
		0x0000ffff, 0x0001ffff, 0x0003ffff, 0x0007ffff,
		0x000fffff, 0x001fffff, 0x003fffff, 0x007fffff,
		0x00ffffff, 0x01ffffff, 0x03ffffff, 0x07ffffff,
		0x0fffffff, 0x1fffffff, 0x3fffffff, 0x7fffffff,
		0xffffffff
	]

	var bitStream = Aurora.extend(Aurora.object, 'Aurora::BitStream', {
		bitPosition: { value: 0, writable: true },
		offset: { get: function () { return 8 * this.stream.offset + this.bitPosition } }
	})

	bitStream.constructor = function (stream) {
		Aurora.object.constructor.apply(this)

		this.$.stream = stream
	}
	
	bitStream.available = function (n) {
		return this.$.stream.available((n + 8 - this.$.bitPosition) / 8)
	}

	bitStream.advance = function (n) {
		this.$.bitPosition += n

		this.$.stream.advance(this.$.bitPosition >> 3)
		this.$.bitPosition &= 7

		return this
	}

	bitStream.align = function () {
		if (this.$.bitPosition != 0) {
			this.$.bitPosition = 0; this.$.stream.advance(1)
		}

		return this
	}

	bitStream.peekBig = function (n) {
		if (n == 0) { return 0 }

		var a0 = this.$.stream.peekUInt8(0) * 0x0100000000
		var a1 = this.$.stream.peekUInt8(1) * 0x0001000000
		var a2 = this.$.stream.peekUInt8(2) * 0x0000010000
		var a3 = this.$.stream.peekUInt8(3) * 0x0000000100
		var a4 = this.$.stream.peekUInt8(4) * 0x0000000001

		var a = a0 + a1 + a2 + a3 + a4
		a = a % Math.pow(2, 40 - this.$.bitPosition)
		a = a / Math.pow(2, 40 - this.$.bitPosition - n)
		
		return a << 0
	}

	bitStream.peek = function (n) {
		if (n == 0) { return 0 }

		var a = this.$.stream.peekUInt32(0)

		return (a << this.$.bitPosition) >>> (32 - n)
	}

	bitStream.peekSmall = function (n) {
		if (n == 0) { return 0 }

		var a = this.$.stream.peekUInt16(0)

		return ((a << this.$.bitPosition) & 0xFFFF) >>> (16 - n)
	}

	bitStream.peekOne = function (n) {
		var a = this.$.stream.peekUInt8(0)

		return ((a << this.$.bitPosition) & 0xFF) >>> 7
	}

	bitStream.readBig = function (n) {
		var value = this.peekBig(bits)

		this.advance(n)

		return value
	}

	bitStream.readSigned = function (n) {
		if (n == 0) { return 0 }

		var a = this.$.stream.peekUInt32(0)

		a = (a << this.$.bitPosition) >> (32 - n)

		this.advance(bits)

		return a
	}

	bitStream.read = function (n) {
		if (n == 0) { return 0 }

		var a = this.$.stream.peekUInt32(0)

		a = (a << this.$.bitPosition) >>> (32 - n)

		this.advance(bits)

		return a
	}

	bitStream.readSmall = function (n) {
		if (n == 0) { return 0 }

		var a = this.$.stream.peekUInt16(0)
		a = ((a << this.$.bitPosition) & 0xFFFF) >>> (32 - n)

		this.advance(bits)

		return a
	}

	bitStream.readOne = function () {
		var a = this.$.stream.peekUInt8(0)
		a = ((a << this.$.bitPosition) & 0xFF) >>> 7
	}

	bitStream.readLSB = function (n) {
		if (n == 0) { return 0 }

		var modBits = n + this.$.bitPosition

		var a = this.$.stream.peekUInt8(0) >>> this.$.bitPosition

		if (modBits > 8) {
			a = a | (this.$.stream.peekUInt8(1) << (8  - this.$.bitPosition))
		}

		if (modBits > 16) {
			a = a | (this.$.stream.peekUInt8(2) << (16 - this.$.bitPosition))
		}

		if (modBits > 24) {
			a = a | (this.$.stream.peekUInt8(3) << (24 - this.$.bitPosition))
		}

		if (modBits > 32) {
			a = a | (this.$.stream.peekUInt8(4) << (32 - this.$.bitPosition))
		}

		this.advance(n)

		return a & bitMask[n]
	}

	Aurora.bitStream = bitStream
	Aurora.BitStream = bitStream.constructor

	Aurora.BitStream.prototype = bitStream
}(this)


void function (global) {
	'use strict'

	var eventEmitter = Aurora.extend(Aurora.object, 'Aurora::EventEmitter', {
		events: { value: {} }
	})

	eventEmitter.constructor = function () {
		Aurora.object.constructor.apply(this)
	}

	eventEmitter.on = function (event, fn) {
		var callbacks = this.$.events[event] || []
		callbacks.push(fn)
		this.$.events[event] = callbacks
	}

	eventEmitter.off = function (event, fn) {
		var array = this.$.events[event]

		if (array) {
			var index = array.indexOf(fn)
			if (index != -1) {
				array.splice(index, 1)
			}
		}
	}

	eventEmitter.once = function (event, fn) {
		var cb = function () {
			this.off(event, cb)
			fn.apply(this, arguments)
		}
		this.on(event, cb)
	}

	eventEmitter.emit = function (event) {
		var array = this.$.events[event], args = Array.prototype.slice.call(arguments, 1)
		if (array) {
			for (var i = 0; i < array.length; i++) {
				array[i].apply(this, args)
			}
		}
	}

	Aurora.eventEmitter = eventEmitter
	Aurora.EventEmitter = eventEmitter.constructor

	Aurora.EventEmitter.prototype = eventEmitter
}(this)


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


// Generated by CoffeeScript 1.3.3
var Asset,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Asset = (function(_super) {

  __extends(Asset, _super);

  window.Asset = Asset;

  function Asset(source) {
    var _this = this;
    this.source = source;
    this.findDecoder = __bind(this.findDecoder, this);

    this.probe = __bind(this.probe, this);

    Asset.__super__.constructor.call(this);
    this.buffered = 0;
    this.duration = null;
    this.format = null;
    this.metadata = null;
    this.active = false;
    this.demuxer = null;
    this.decoder = null;
    this.source.once('data', this.probe);
    this.source.on('error', function(err) {
      _this.emit('error', err);
      return _this.stop();
    });
    this.source.on('progress', function(buffered) {
      _this.buffered = buffered;
      return _this.emit('buffer', _this.buffered);
    });
  }

  Asset.fromURL = function(url) {
    var source;
    source = new HTTPSource(url);
    return new Asset(source);
  };

  Asset.fromFile = function(file) {
    var source;
    source = new FileSource(file);
    return new Asset(source);
  };

  Asset.prototype.start = function() {
    if (this.active) {
      return;
    }
    this.active = true;
    return this.source.start();
  };

  Asset.prototype.stop = function() {
    if (!this.active) {
      return;
    }
    this.active = false;
    return this.source.pause();
  };

  Asset.prototype.get = function(event, callback) {
    var _this = this;
    if (event !== 'format' && event !== 'duration' && event !== 'metadata') {
      return;
    }
    if (this[event] != null) {
      return callback(this[event]);
    } else {
      this.once(event, function(value) {
        _this.stop();
        return callback(value);
      });
      return this.start();
    }
  };

  Asset.prototype.probe = function(chunk) {
    var demuxer,
      _this = this;
    if (!this.active) {
      return;
    }
    demuxer = Demuxer.find(chunk);
    if (!demuxer) {
      return this.emit('error', 'A demuxer for this container was not found.');
    }
    this.demuxer = new demuxer(this.source, chunk);
    this.demuxer.on('format', this.findDecoder);
    this.demuxer.on('duration', function(duration) {
      _this.duration = duration;
      return _this.emit('duration', _this.duration);
    });
    this.demuxer.on('metadata', function(metadata) {
      _this.metadata = metadata;
      return _this.emit('metadata', _this.metadata);
    });
    return this.demuxer.on('error', function(err) {
      _this.emit('error', err);
      return _this.stop();
    });
  };

  Asset.prototype.findDecoder = function(format) {
    var decoder,
      _this = this;
    this.format = format;
    if (!this.active) {
      return;
    }
    this.emit('format', this.format);
    console.log(this.format);
    decoder = Decoder.find(this.format.formatID);
    if (!decoder) {
      return this.emit('error', "A decoder for " + this.format.formatID + " was not found.");
    }
    this.decoder = new decoder(this.demuxer, this.format);
    this.decoder.on('data', function(buffer) {
      return _this.emit('data', buffer);
    });
    this.decoder.on('error', function(err) {
      _this.emit('error', err);
      return _this.stop();
    });
    return this.emit('decodeStart');
  };

  return Asset;

})(Aurora.EventEmitter);

// Generated by CoffeeScript 1.3.3
var Player,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

Player = (function(_super) {

  __extends(Player, _super);

  window.Player = Player;

  function Player(asset) {
    var _this = this;
    this.asset = asset;
    this.startPlaying = __bind(this.startPlaying, this);

    Player.__super__.constructor.call(this);
    this.playing = false;
    this.buffered = 0;
    this.currentTime = 0;
    this.duration = 0;
    this.volume = 100;
    this.pan = 0;
    this.metadata = {};
    this.filters = [new VolumeFilter(this, 'volume'), new BalanceFilter(this, 'pan')];
    this.asset.on('buffer', function(buffered) {
      _this.buffered = buffered;
      return _this.emit('buffer', _this.buffered);
    });
    this.asset.on('decodeStart', function() {
      _this.queue = new Queue(_this.asset.decoder);
      return _this.queue.once('ready', _this.startPlaying);
    });
    this.asset.on('format', function(format) {
      _this.format = format;
      return _this.emit('format', _this.format);
    });
    this.asset.on('metadata', function(metadata) {
      _this.metadata = metadata;
      return _this.emit('metadata', _this.metadata);
    });
    this.asset.on('duration', function(duration) {
      _this.duration = duration;
      return _this.emit('duration', _this.duration);
    });
    this.asset.on('error', function(error) {
      return _this.emit('error', error);
    });
  }

  Player.fromURL = function(url) {
    var asset;
    asset = Asset.fromURL(url);
    return new Player(asset);
  };

  Player.fromFile = function(file) {
    var asset;
    asset = Asset.fromFile(file);
    return new Player(asset);
  };

  Player.prototype.preload = function() {
    if (!this.asset) {
      return;
    }
    this.startedPreloading = true;
    return this.asset.start();
  };

  Player.prototype.play = function() {
    var _ref;
    if (this.playing) {
      return;
    }
    if (!this.startedPreloading) {
      this.preload();
    }
    this.playing = true;
    return (_ref = this.device) != null ? _ref.start() : void 0;
  };

  Player.prototype.pause = function() {
    var _ref;
    if (!this.playing) {
      return;
    }
    this.playing = false;
    return (_ref = this.device) != null ? _ref.stop() : void 0;
  };

  Player.prototype.togglePlayback = function() {
    if (this.playing) {
      return this.pause();
    } else {
      return this.play();
    }
  };

  Player.prototype.stop = function() {
    var _ref;
    this.pause();
    this.asset.stop();
    return (_ref = this.device) != null ? _ref.destroy() : void 0;
  };

  Player.prototype.startPlaying = function() {
    var decoder, div, format, frame, frameOffset, _ref,
      _this = this;
    frame = this.queue.read();
    frameOffset = 0;
    _ref = this.asset, format = _ref.format, decoder = _ref.decoder;
    div = decoder.floatingPoint ? 1 : Math.pow(2, format.bitsPerChannel - 1);
    this.device = new AudioDevice(format.sampleRate, format.channelsPerFrame);
    this.device.on('timeUpdate', function(currentTime) {
      _this.currentTime = currentTime;
      return _this.emit('progress', _this.currentTime);
    });
    this.refill = function(buffer) {
      var bufferOffset, filter, i, max, _i, _j, _len, _ref1;
      if (!_this.playing) {
        return;
      }
      bufferOffset = 0;
      while (frame && bufferOffset < buffer.length) {
        max = Math.min(frame.length - frameOffset, buffer.length - bufferOffset);
        for (i = _i = 0; _i < max; i = _i += 1) {
          buffer[bufferOffset++] = frame[frameOffset++] / div;
        }
        if (frameOffset === frame.length) {
          frame = _this.queue.read();
          frameOffset = 0;
        }
      }
      _ref1 = _this.filters;
      for (_j = 0, _len = _ref1.length; _j < _len; _j++) {
        filter = _ref1[_j];
        filter.process(buffer);
      }
      if (!frame) {
        if (decoder.receivedFinalBuffer) {
          _this.currentTime = _this.duration;
          _this.emit('progress', _this.currentTime);
          _this.emit('end');
          _this.pause();
        } else {
          _this.device.stop();
        }
      }
    };
    this.device.on('refill', this.refill);
    if (this.playing) {
      this.device.start();
    }
    return this.emit('ready');
  };

  return Player;

})(Aurora.EventEmitter);


// Generated by CoffeeScript 1.3.3
var AudioDevice,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

AudioDevice = (function(_super) {
  var devices;

  __extends(AudioDevice, _super);

  function AudioDevice(sampleRate, channels) {
    this.sampleRate = sampleRate;
    this.channels = channels;
    this.updateTime = __bind(this.updateTime, this);

    AudioDevice.__super__.constructor.call(this);
    this.playing = false;
    this.currentTime = 0;
    this._lastTime = 0;
  }

  AudioDevice.prototype.start = function() {
    var _ref,
      _this = this;
    if (this.playing) {
      return;
    }
    this.playing = true;
    if ((_ref = this.device) == null) {
      this.device = AudioDevice.create(this.sampleRate, this.channels);
    }
    this._lastTime = this.device.getDeviceTime();
    this._timer = setInterval(this.updateTime, 200);
    return this.device.on('refill', this.refill = function(buffer) {
      return _this.emit('refill', buffer);
    });
  };

  AudioDevice.prototype.stop = function() {
    if (!this.playing) {
      return;
    }
    this.playing = false;
    this.device.off('refill', this.refill);
    return clearInterval(this._timer);
  };

  AudioDevice.prototype.destroy = function() {
    this.stop();
    return this.device.destroy();
  };

  AudioDevice.prototype.seek = function(currentTime) {
    this.currentTime = currentTime;
    this._lastTime = this.device.getDeviceTime();
    return this.emit('timeUpdate', this.currentTime);
  };

  AudioDevice.prototype.updateTime = function() {
    var time;
    time = this.device.getDeviceTime();
    this.currentTime += (time - this._lastTime) / this.device.sampleRate * 1000 | 0;
    this._lastTime = time;
    return this.emit('timeUpdate', this.currentTime);
  };

  devices = [];

  AudioDevice.register = function(device) {
    return devices.push(device);
  };

  AudioDevice.create = function(sampleRate, channels) {
    var device, _i, _len;
    for (_i = 0, _len = devices.length; _i < _len; _i++) {
      device = devices[_i];
      if (device.supported) {
        return new device(sampleRate, channels);
      }
    }
    return null;
  };

  return AudioDevice;

})(Aurora.EventEmitter);

// Generated by CoffeeScript 1.3.3
var WebKitAudioDevice,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

WebKitAudioDevice = (function(_super) {
  var AudioContext, sharedContext;

  __extends(WebKitAudioDevice, _super);

  AudioDevice.register(WebKitAudioDevice);

  AudioContext = window.AudioContext || window.webkitAudioContext;

  WebKitAudioDevice.supported = AudioContext != null;

  sharedContext = null;

  function WebKitAudioDevice(sampleRate, channels) {
    this.sampleRate = sampleRate;
    this.channels = channels;
    this.refill = __bind(this.refill, this);

    this.context = sharedContext != null ? sharedContext : sharedContext = new AudioContext;
    this.deviceChannels = this.context.destination.numberOfChannels;
    this.deviceSampleRate = this.context.sampleRate;
    this.node = this.context.createJavaScriptNode(4096, this.deviceChannels, this.deviceChannels);
    this.node.onaudioprocess = this.refill;
    this.node.connect(this.context.destination);
  }

  WebKitAudioDevice.prototype.refill = function(event) {
    var channelCount, channels, data, i, n, outputBuffer, _i, _j, _k, _ref;
    outputBuffer = event.outputBuffer;
    channelCount = outputBuffer.numberOfChannels;
    channels = new Array(channelCount);
    for (i = _i = 0; _i < channelCount; i = _i += 1) {
      channels[i] = outputBuffer.getChannelData(i);
    }
    data = new Float32Array(outputBuffer.length * channelCount);
    this.emit('refill', data);
    for (i = _j = 0, _ref = outputBuffer.length; _j < _ref; i = _j += 1) {
      for (n = _k = 0; _k < channelCount; n = _k += 1) {
        channels[n][i] = data[i * channelCount + n];
      }
    }
  };

  WebKitAudioDevice.prototype.destroy = function() {
    return this.node.disconnect(0);
  };

  WebKitAudioDevice.prototype.getDeviceTime = function() {
    return this.context.currentTime * this.deviceSampleRate;
  };

  return WebKitAudioDevice;

})(Aurora.EventEmitter);

// Generated by CoffeeScript 1.3.3
var MozillaAudioDevice,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

MozillaAudioDevice = (function(_super) {
  var createTimer, destroyTimer;

  __extends(MozillaAudioDevice, _super);

  AudioDevice.register(MozillaAudioDevice);

  MozillaAudioDevice.supported = 'mozWriteAudio' in new Audio;

  function MozillaAudioDevice(sampleRate, channels) {
    this.sampleRate = sampleRate;
    this.channels = channels;
    this.refill = __bind(this.refill, this);

    this.audio = new Audio;
    this.audio.mozSetup(this.channels, this.sampleRate);
    this.writePosition = 0;
    this.prebufferSize = this.sampleRate / 2;
    this.tail = null;
    this.timer = createTimer(this.refill, 100);
  }

  MozillaAudioDevice.prototype.refill = function() {
    var available, buffer, currentPosition, written;
    if (this.tail) {
      written = this.audio.mozWriteAudio(this.tail);
      this.writePosition += written;
      if (this.tailPosition < this.tail.length) {
        this.tail = this.tail.subarray(written);
      } else {
        this.tail = null;
      }
    }
    currentPosition = this.audio.mozCurrentSampleOffset();
    available = currentPosition + this.prebufferSize - this.writePosition;
    if (available > 0) {
      buffer = new Float32Array(available);
      this.emit('refill', buffer);
      written = this.audio.mozWriteAudio(buffer);
      if (written < buffer.length) {
        this.tail = buffer.subarray(written);
      }
      this.writePosition += written;
    }
  };

  MozillaAudioDevice.prototype.destroy = function() {
    return destroyTimer(this.timer);
  };

  MozillaAudioDevice.prototype.getDeviceTime = function() {
    return this.audio.mozCurrentSampleOffset() / this.channels;
  };

  createTimer = function(fn, interval) {
    var url, worker;
    url = Buffer.makeBlobURL("setInterval(function() { postMessage('ping'); }, " + interval + ");");
    if (url == null) {
      return setInterval(fn, interval);
    }
    worker = new Worker(url);
    worker.onmessage = fn;
    worker.url = url;
    return worker;
  };

  destroyTimer = function(timer) {
    if (timer.terminate) {
      timer.terminate();
      return URL.revokeObjectURL(timer.url);
    } else {
      return clearInterval(timer);
    }
  };

  return MozillaAudioDevice;

})(Aurora.EventEmitter);


// Generated by CoffeeScript 1.3.3
var HTTPSource,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

HTTPSource = (function(_super) {

  __extends(HTTPSource, _super);

  function HTTPSource(url) {
    this.url = url;
    this.chunkSize = 1 << 20;
    this.inflight = false;
    this.reset();
  }

  HTTPSource.prototype.start = function() {
    var _this = this;
    this.inflight = true;
    this.xhr = new XMLHttpRequest();
    this.xhr.onload = function(event) {
      _this.length = parseInt(_this.xhr.getResponseHeader("Content-Length"));
      _this.inflight = false;
      return _this.loop();
    };
    this.xhr.onerror = function(err) {
      _this.pause();
      return _this.emit('error', err);
    };
    this.xhr.onabort = function(event) {
      console.log("HTTP Aborted: Paused?");
      return _this.inflight = false;
    };
    this.xhr.open("HEAD", this.url, true);
    return this.xhr.send(null);
  };

  HTTPSource.prototype.loop = function() {
    var endPos,
      _this = this;
    if (this.inflight || !this.length) {
      return this.emit('error', 'Something is wrong in HTTPSource.loop');
    }
    if (this.offset === this.length) {
      this.inflight = false;
      this.emit('end');
      return;
    }
    this.inflight = true;
    this.xhr = new XMLHttpRequest();
    this.xhr.onprogress = function(event) {
      return _this.emit('progress', (_this.offset + event.loaded) / _this.length * 100);
    };
    this.xhr.onload = function(event) {
      var buf, buffer, i, txt, _i, _ref;
      if (_this.xhr.response) {
        buf = new Uint8Array(_this.xhr.response);
      } else {
        txt = _this.xhr.responseText;
        buf = new Uint8Array(txt.length);
        for (i = _i = 0, _ref = txt.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
          buf[i] = txt.charCodeAt(i) & 0xff;
        }
      }
      buffer = new Aurora.Buffer(buf.buffer);
      _this.offset += buffer.length;
      _this.emit('data', buffer);
      if (_this.offset === _this.length) {
        _this.emit('end');
      }
      _this.emit('progress', _this.offset / _this.length * 100);
      _this.inflight = false;
      return _this.loop();
    };
    this.xhr.onerror = function(err) {
      _this.emit('error', err);
      return _this.pause();
    };
    this.xhr.onabort = function(event) {
      return _this.inflight = false;
    };
    this.xhr.open("GET", this.url, true);
    this.xhr.responseType = "arraybuffer";
    endPos = Math.min(this.offset + this.chunkSize, this.length);
    this.xhr.setRequestHeader("Range", "bytes=" + this.offset + "-" + endPos);
    this.xhr.overrideMimeType('text/plain; charset=x-user-defined');
    return this.xhr.send(null);
  };

  HTTPSource.prototype.pause = function() {
    var _ref;
    this.inflight = false;
    return (_ref = this.xhr) != null ? _ref.abort() : void 0;
  };

  HTTPSource.prototype.reset = function() {
    this.pause();
    return this.offset = 0;
  };

  return HTTPSource;

})(Aurora.EventEmitter);

// Generated by CoffeeScript 1.3.3
var FileSource,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

FileSource = (function(_super) {

  __extends(FileSource, _super);

  function FileSource(file) {
    this.file = file;
    if (!window.FileReader) {
      return this.emit('error', 'This browser does not have FileReader support.');
    }
    this.offset = 0;
    this.length = this.file.size;
    this.chunkSize = 1 << 20;
  }

  FileSource.prototype.start = function() {
    var _this = this;
    this.reader = new FileReader;
    this.reader.onload = function(e) {
      var buf;
      buf = new Aurora.Buffer(e.target.result);
      _this.offset += buf.length;
      _this.emit('data', buf);
      _this.emit('progress', _this.offset / _this.length * 100);
      if (_this.offset < _this.length) {
        return _this.loop();
      }
    };
    this.reader.onloadend = function() {
      if (_this.offset === _this.length) {
        _this.emit('end');
        return _this.reader = null;
      }
    };
    this.reader.onerror = function(e) {
      return _this.emit('error', e);
    };
    this.reader.onprogress = function(e) {
      return _this.emit('progress', (_this.offset + e.loaded) / _this.length * 100);
    };
    return this.loop();
  };

  FileSource.prototype.loop = function() {
    var blob, endPos, slice;
    this.file[slice = 'slice'] || this.file[slice = 'webkitSlice'] || this.file[slice = 'mozSlice'];
    endPos = Math.min(this.offset + this.chunkSize, this.length);
    blob = this.file[slice](this.offset, endPos);
    return this.reader.readAsArrayBuffer(blob);
  };

  FileSource.prototype.pause = function() {
    var _ref;
    return (_ref = this.reader) != null ? _ref.abort() : void 0;
  };

  FileSource.prototype.reset = function() {
    this.pause();
    return this.offset = 0;
  };

  return FileSource;

})(Aurora.EventEmitter);


// Generated by CoffeeScript 1.3.3
var Filter;

Filter = (function() {

  function Filter(context, key) {
    if (context && key) {
      Object.defineProperty(this, 'value', {
        get: function() {
          return context[key];
        }
      });
    }
  }

  Filter.prototype.process = function(buffer) {};

  return Filter;

})();

// Generated by CoffeeScript 1.3.3
var VolumeFilter,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

VolumeFilter = (function(_super) {

  __extends(VolumeFilter, _super);

  function VolumeFilter() {
    return VolumeFilter.__super__.constructor.apply(this, arguments);
  }

  VolumeFilter.prototype.process = function(buffer) {
    var i, vol, _i, _ref;
    if (this.value >= 100) {
      return;
    }
    vol = Math.max(0, Math.min(100, this.value)) / 100;
    for (i = _i = 0, _ref = buffer.length; _i < _ref; i = _i += 1) {
      buffer[i] *= vol;
    }
  };

  return VolumeFilter;

})(Filter);

// Generated by CoffeeScript 1.3.3
var BalanceFilter,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

BalanceFilter = (function(_super) {

  __extends(BalanceFilter, _super);

  function BalanceFilter() {
    return BalanceFilter.__super__.constructor.apply(this, arguments);
  }

  BalanceFilter.prototype.process = function(buffer) {
    var i, pan, _i, _ref;
    if (this.value === 0) {
      return;
    }
    pan = Math.max(-50, Math.min(50, this.value));
    for (i = _i = 0, _ref = buffer.length; _i < _ref; i = _i += 2) {
      buffer[i] *= Math.min(1, (50 - pan) / 50);
      buffer[i + 1] *= Math.min(1, (50 + pan) / 50);
    }
  };

  return BalanceFilter;

})(Filter);

// Generated by CoffeeScript 1.3.3
var EarwaxFilter,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

EarwaxFilter = (function(_super) {
  var NUMTAPS, filt;

  __extends(EarwaxFilter, _super);

  filt = new Int8Array([4, -6, 4, -11, -1, -5, 3, 3, -2, 5, -5, 0, 9, 1, 6, 3, -4, -1, -5, -3, -2, -5, -7, 1, 6, -7, 30, -29, 12, -3, -11, 4, -3, 7, -20, 23, 2, 0, 1, -6, -14, -5, 15, -18, 6, 7, 15, -10, -14, 22, -7, -2, -4, 9, 6, -12, 6, -6, 0, -11, 0, -5, 4, 0]);

  NUMTAPS = 64;

  function EarwaxFilter() {
    this.taps = new Float32Array(NUMTAPS * 2);
  }

  EarwaxFilter.prototype.process = function(buffer) {
    var i, len, output, _i, _ref;
    len = buffer.length;
    i = 0;
    while (len--) {
      output = 0;
      for (i = _i = _ref = NUMTAPS - 1; _i > 0; i = _i += -1) {
        this.taps[i] = this.taps[i - 1];
        output += this.taps[i] * filt[i];
      }
      this.taps[0] = buffer[i] / 64;
      output += this.taps[0] * filt[0];
      buffer[i++] = output;
    }
  };

  return EarwaxFilter;

})(Filter);


// Generated by CoffeeScript 1.3.3
var CAFDemuxer,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

CAFDemuxer = (function(_super) {

  __extends(CAFDemuxer, _super);

  function CAFDemuxer() {
    return CAFDemuxer.__super__.constructor.apply(this, arguments);
  }

  Aurora.Demuxer.register(CAFDemuxer);

  CAFDemuxer.probe = function(buffer) {
    return buffer.peekString(0, 4) === 'caff';
  };

  CAFDemuxer.prototype.readChunk = function() {
    var buffer, char, entries, flags, i, key, metadata, value, _i;
    if (!this.$.format && this.$.stream.available(64)) {
      if (this.$.stream.readString(4) !== 'caff') {
        return this.emit('error', "Invalid CAF, does not begin with 'caff'");
      }
      this.$.stream.advance(4);
      if (this.$.stream.readString(4) !== 'desc') {
        return this.emit('error', "Invalid CAF, 'caff' is not followed by 'desc'");
      }
      if (!(this.$.stream.readUInt32() === 0 && this.$.stream.readUInt32() === 32)) {
        return this.emit('error', "Invalid 'desc' size, should be 32");
      }
      this.$.format = {};
      this.$.format.sampleRate = this.$.stream.readFloat64();
      this.$.format.formatID = this.$.stream.readString(4);
      flags = this.$.stream.readUInt32();
      this.$.format.floatingPoint = Boolean(flags & 1);
      this.$.format.littleEndian = Boolean(flags & 2);
      this.$.format.bytesPerPacket = this.$.stream.readUInt32();
      this.$.format.framesPerPacket = this.$.stream.readUInt32();
      this.$.format.channelsPerFrame = this.$.stream.readUInt32();
      this.$.format.bitsPerChannel = this.$.stream.readUInt32();
      this.emit('format', this.$.format);
    }
    while (this.$.stream.available(1)) {
      if (!this.headerCache) {
        this.headerCache = {
          type: this.$.stream.readString(4),
          oversize: this.$.stream.readUInt32() !== 0,
          size: this.$.stream.readUInt32()
        };
        if (this.headerCache.oversize) {
          return this.emit('error', "Holy Shit, an oversized file, not supported in JS");
        }
      }
      switch (this.headerCache.type) {
        case 'kuki':
          if (this.$.stream.available(this.headerCache.size)) {
            if (this.$.format.formatID === 'aac ') {
              this.len = this.headerCache.size;
              M4ADemuxer.prototype.readEsds.call(this);
            } else {
              buffer = this.$.stream.readBuffer(this.headerCache.size);
              this.emit('cookie', buffer);
            }
            this.headerCache = null;
          }
          break;
        case 'pakt':
          if (this.$.stream.available(this.headerCache.size)) {
            if (this.$.stream.readUInt32() !== 0) {
              return this.emit('error', 'Sizes greater than 32 bits are not supported.');
            }
            this.numPackets = this.$.stream.readUInt32();
            if (this.$.stream.readUInt32() !== 0) {
              return this.emit('error', 'Sizes greater than 32 bits are not supported.');
            }
            this.numFrames = this.$.stream.readUInt32();
            this.primingFrames = this.$.stream.readUInt32();
            this.remainderFrames = this.$.stream.readUInt32();
            this.emit('duration', this.numFrames / this.$.format.sampleRate * 1000 | 0);
            this.sentDuration = true;
            this.$.stream.advance(this.headerCache.size - 24);
            this.headerCache = null;
          }
          break;
        case 'info':
          entries = this.$.stream.readUInt32();
          metadata = {};
          for (i = _i = 0; 0 <= entries ? _i < entries : _i > entries; i = 0 <= entries ? ++_i : --_i) {
            key = '';
            while ((char = this.$.stream.readUInt8()) !== 0) {
              key += String.fromCharCode(char);
            }
            value = '';
            while ((char = this.$.stream.readUInt8()) !== 0) {
              value += String.fromCharCode(char);
            }
            metadata[key] = value;
          }
          this.emit('metadata', metadata);
          this.headerCache = null;
          break;
        case 'data':
          if (!this.sentFirstDataChunk) {
            this.$.stream.advance(4);
            this.headerCache.size -= 4;
            if (this.$.format.bytesPerPacket !== 0 && !this.sentDuration) {
              this.numFrames = this.headerCache.size / this.$.format.bytesPerPacket;
              this.emit('duration', this.numFrames / this.$.format.sampleRate * 1000 | 0);
            }
            this.sentFirstDataChunk = true;
          }
          buffer = this.$.stream.readSingleBuffer(this.headerCache.size);
          this.headerCache.size -= buffer.length;
          this.emit('data', buffer, this.headerCache.size === 0);
          if (this.headerCache.size <= 0) {
            this.headerCache = null;
          }
          break;
        default:
          if (this.$.stream.available(this.headerCache.size)) {
            this.$.stream.advance(this.headerCache.size);
            this.headerCache = null;
          }
      }
    }
  };

  return CAFDemuxer;

})(Aurora.Demuxer);

// Generated by CoffeeScript 1.3.3
var M4ADemuxer,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

M4ADemuxer = (function(_super) {
  var genres, metafields, readDescr;

  __extends(M4ADemuxer, _super);

  function M4ADemuxer() {
    return M4ADemuxer.__super__.constructor.apply(this, arguments);
  }

  Aurora.Demuxer.register(M4ADemuxer);

  M4ADemuxer.probe = function(buffer) {
    return buffer.peekString(8, 4) === 'M4A ';
  };

  metafields = {
    '©alb': 'Album',
    '©arg': 'Arranger',
    '©art': 'Artist',
    '©ART': 'Album Artist',
    'catg': 'Category',
    '©com': 'Composer',
    'covr': 'Cover Art',
    'cpil': 'Compilation',
    '©cpy': 'Copyright',
    'cprt': 'Copyright',
    'desc': 'Description',
    'disk': 'Disk Number',
    '©gen': 'Genre',
    'gnre': 'Genre',
    '©grp': 'Grouping',
    '©isr': 'ISRC Code',
    'keyw': 'Keyword',
    '©lab': 'Record Label',
    '©lyr': 'Lyrics',
    '©nam': 'Title',
    'pcst': 'Podcast',
    'pgap': 'Gapless',
    '©phg': 'Recording Copyright',
    '©prd': 'Producer',
    '©prf': 'Performers',
    'purl': 'Podcast URL',
    'rtng': 'Rating',
    '©swf': 'Songwriter',
    'tmpo': 'Tempo',
    '©too': 'Encoder',
    'trkn': 'Track Number',
    '©wrt': 'Composer'
  };

  genres = ["Blues", "Classic Rock", "Country", "Dance", "Disco", "Funk", "Grunge", "Hip-Hop", "Jazz", "Metal", "New Age", "Oldies", "Other", "Pop", "R&B", "Rap", "Reggae", "Rock", "Techno", "Industrial", "Alternative", "Ska", "Death Metal", "Pranks", "Soundtrack", "Euro-Techno", "Ambient", "Trip-Hop", "Vocal", "Jazz+Funk", "Fusion", "Trance", "Classical", "Instrumental", "Acid", "House", "Game", "Sound Clip", "Gospel", "Noise", "AlternRock", "Bass", "Soul", "Punk", "Space", "Meditative", "Instrumental Pop", "Instrumental Rock", "Ethnic", "Gothic", "Darkwave", "Techno-Industrial", "Electronic", "Pop-Folk", "Eurodance", "Dream", "Southern Rock", "Comedy", "Cult", "Gangsta", "Top 40", "Christian Rap", "Pop/Funk", "Jungle", "Native American", "Cabaret", "New Wave", "Psychadelic", "Rave", "Showtunes", "Trailer", "Lo-Fi", "Tribal", "Acid Punk", "Acid Jazz", "Polka", "Retro", "Musical", "Rock & Roll", "Hard Rock", "Folk", "Folk/Rock", "National Folk", "Swing", "Fast Fusion", "Bebob", "Latin", "Revival", "Celtic", "Bluegrass", "Avantgarde", "Gothic Rock", "Progressive Rock", "Psychedelic Rock", "Symphonic Rock", "Slow Rock", "Big Band", "Chorus", "Easy Listening", "Acoustic", "Humour", "Speech", "Chanson", "Opera", "Chamber Music", "Sonata", "Symphony", "Booty Bass", "Primus", "Porn Groove", "Satire", "Slow Jam", "Club", "Tango", "Samba", "Folklore", "Ballad", "Power Ballad", "Rhythmic Soul", "Freestyle", "Duet", "Punk Rock", "Drum Solo", "A Capella", "Euro-House", "Dance Hall"];

  M4ADemuxer.prototype.readChunk = function() {
    var buffer, diff, duration, entryCount, field, i, numEntries, pos, rating, sampleRate, _i, _ref;
    while (this.$.stream.available(1)) {
      if (!this.readHeaders && this.$.stream.available(8)) {
        this.len = this.$.stream.readUInt32() - 8;
        this.type = this.$.stream.readString(4);
        if (this.len === 0) {
          continue;
        }
        this.readHeaders = true;
      }
      if (this.type in metafields) {
        this.metafield = this.type;
        this.readHeaders = false;
        continue;
      }
      switch (this.type) {
        case 'ftyp':
          if (!this.$.stream.available(this.len)) {
            return;
          }
          if (this.$.stream.readString(4) !== 'M4A ') {
            return this.emit('error', 'Not a valid M4A file.');
          }
          this.$.stream.advance(this.len - 4);
          break;
        case 'moov':
        case 'trak':
        case 'mdia':
        case 'minf':
        case 'stbl':
        case 'udta':
        case 'ilst':
          break;
        case 'stco':
          this.$.stream.advance(4);
          entryCount = this.$.stream.readUInt32();
          this.chunkOffsets = [];
          for (i = _i = 0; 0 <= entryCount ? _i < entryCount : _i > entryCount; i = 0 <= entryCount ? ++_i : --_i) {
            this.chunkOffsets[i] = this.$.stream.readUInt32();
          }
          break;
        case 'meta':
          this.metadata = {};
          this.metaMaxPos = this.$.stream.offset + this.len;
          this.$.stream.advance(4);
          break;
        case 'data':
          if (!this.$.stream.available(this.len)) {
            return;
          }
          field = metafields[this.metafield];
          switch (this.metafield) {
            case 'disk':
            case 'trkn':
              pos = this.$.stream.offset;
              this.$.stream.advance(10);
              this.metadata[field] = this.$.stream.readUInt16() + ' of ' + this.$.stream.readUInt16();
              this.$.stream.advance(this.len - (this.$.stream.offset - pos));
              break;
            case 'cpil':
            case 'pgap':
            case 'pcst':
              this.$.stream.advance(8);
              this.metadata[field] = this.$.stream.readUInt8() === 1;
              break;
            case 'gnre':
              this.$.stream.advance(8);
              this.metadata[field] = genres[this.$.stream.readUInt16() - 1];
              break;
            case 'rtng':
              this.$.stream.advance(8);
              rating = this.$.stream.readUInt8();
              this.metadata[field] = rating === 2 ? 'Clean' : rating !== 0 ? 'Explicit' : 'None';
              break;
            case 'tmpo':
              this.$.stream.advance(8);
              this.metadata[field] = this.$.stream.readUInt16();
              break;
            case 'covr':
              this.$.stream.advance(8);
              this.metadata[field] = this.$.stream.readBuffer(this.len - 8);
              break;
            default:
              this.metadata[field] = this.$.stream.readUTF8(this.len);
          }
          break;
        case 'mdhd':
          if (!this.$.stream.available(this.len)) {
            return;
          }
          this.$.stream.advance(4);
          this.$.stream.advance(8);
          sampleRate = this.$.stream.readUInt32();
          duration = this.$.stream.readUInt32();
          this.emit('duration', duration / sampleRate * 1000 | 0);
          this.$.stream.advance(4);
          break;
        case 'stsd':
          if (!this.$.stream.available(this.len)) {
            return;
          }
          this.$.stream.advance(4);
          numEntries = this.$.stream.readUInt32();
          if (numEntries !== 1) {
            return this.emit('error', "Only expecting one entry in sample description atom!");
          }
          this.$.stream.advance(4);
          this.$.format = {};
          this.$.format.formatID = this.$.stream.readString(4);
          this.$.stream.advance(6);
          if (this.$.stream.readUInt16() !== 1) {
            return this.emit('error', 'Unknown version in stsd atom.');
          }
          this.$.stream.advance(6);
          this.$.stream.advance(2);
          this.$.format.channelsPerFrame = this.$.stream.readUInt16();
          this.$.format.bitsPerChannel = this.$.stream.readUInt16();
          this.$.stream.advance(4);
          this.$.format.sampleRate = this.$.stream.readUInt16();
          this.$.stream.advance(2);
          this.emit('format', this.$.format);
          break;
        case 'alac':
          this.$.stream.advance(4);
          this.emit('cookie', this.$.stream.readBuffer(this.len - 4));
          this.sentCookie = true;
          if (this.dataSections) {
            this.sendDataSections();
          }
          break;
        case 'esds':
          this.readEsds();
          this.sentCookie = true;
          if (this.dataSections) {
            this.sendDataSections();
          }
          break;
        case 'mdat':
          if (this.chunkOffsets && this.$.stream.offset < this.chunkOffsets[0]) {
            diff = this.chunkOffsets[0] - this.$.stream.offset;
            this.$.stream.advance(diff);
            this.len -= diff;
          }
          buffer = this.$.stream.readSingleBuffer(this.len);
          this.len -= buffer.length;
          this.readHeaders = this.len > 0;
          if (this.sentCookie) {
            this.emit('data', buffer, this.len === 0);
          } else {
            if ((_ref = this.dataSections) == null) {
              this.dataSections = [];
            }
            this.dataSections.push(buffer);
          }
          break;
        default:
          if (!this.$.stream.available(this.len)) {
            return;
          }
          this.$.stream.advance(this.len);
      }
      if (this.$.stream.offset === this.metaMaxPos) {
        this.emit('metadata', this.metadata);
      }
      if (this.type !== 'mdat') {
        this.readHeaders = false;
      }
    }
  };

  M4ADemuxer.prototype.sendDataSections = function() {
    var interval,
      _this = this;
    return interval = setInterval(function() {
      _this.emit('data', _this.dataSections.shift(), _this.dataSections.length === 0);
      if (_this.dataSections.length === 0) {
        return clearInterval(interval);
      }
    }, 100);
  };

  M4ADemuxer.readDescrLen = function(stream) {
    var c, count, len;
    len = 0;
    count = 4;
    while (count--) {
      c = stream.readUInt8();
      len = (len << 7) | (c & 0x7f);
      if (!(c & 0x80)) {
        break;
      }
    }
    return len;
  };

  readDescr = function(stream) {
    var tag;
    tag = stream.readUInt8();
    return [tag, M4ADemuxer.readDescrLen(stream)];
  };

  M4ADemuxer.prototype.readEsds = function() {
    var codec_id, extra, flags, len, startPos, tag, _ref, _ref1, _ref2;
    startPos = this.$.stream.offset;
    this.$.stream.advance(4);
    _ref = readDescr(this.$.stream), tag = _ref[0], len = _ref[1];
    if (tag === 0x03) {
      this.$.stream.advance(2);
      flags = this.$.stream.readUInt8();
      if (flags & 0x80) {
        this.$.stream.advance(2);
      }
      if (flags & 0x40) {
        this.$.stream.advance(this.$.stream.readUInt8());
      }
      if (flags & 0x20) {
        this.$.stream.advance(2);
      }
    } else {
      this.$.stream.advance(2);
    }
    _ref1 = readDescr(this.$.stream), tag = _ref1[0], len = _ref1[1];
    if (tag === 0x04) {
      codec_id = this.$.stream.readUInt8();
      this.$.stream.advance(1);
      this.$.stream.advance(3);
      this.$.stream.advance(4);
      this.$.stream.advance(4);
      _ref2 = readDescr(this.$.stream), tag = _ref2[0], len = _ref2[1];
      if (tag === 0x05) {
        this.emit('cookie', this.$.stream.readBuffer(len));
      }
    }
    extra = this.len - this.$.stream.offset + startPos;
    return this.$.stream.advance(extra);
  };

  return M4ADemuxer;

})(Aurora.Demuxer);

// Generated by CoffeeScript 1.3.3
var AIFFDemuxer,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

AIFFDemuxer = (function(_super) {

  __extends(AIFFDemuxer, _super);

  function AIFFDemuxer() {
    return AIFFDemuxer.__super__.constructor.apply(this, arguments);
  }

  Aurora.Demuxer.register(AIFFDemuxer);

  AIFFDemuxer.probe = function(buffer) {
    var _ref;
    return buffer.peekString(0, 4) === 'FORM' && ((_ref = buffer.peekString(8, 4)) === 'AIFF' || _ref === 'AIFC');
  };

  AIFFDemuxer.prototype.readChunk = function() {
    var buffer, format, offset, _ref;
    if (!this.readStart && this.$.stream.available(12)) {
      if (this.$.stream.readString(4) !== 'FORM') {
        return this.emit('error', 'Invalid AIFF.');
      }
      this.fileSize = this.$.stream.readUInt32();
      this.fileType = this.$.stream.readString(4);
      this.readStart = true;
      if ((_ref = this.fileType) !== 'AIFF' && _ref !== 'AIFC') {
        return this.emit('error', 'Invalid AIFF.');
      }
    }
    while (this.$.stream.available(1)) {
      if (!this.readHeaders && this.$.stream.available(8)) {
        this.type = this.$.stream.readString(4);
        this.len = this.$.stream.readUInt32();
      }
      switch (this.type) {
        case 'COMM':
          if (!this.$.stream.available(this.len)) {
            return;
          }
          this.$.format = {
            formatID: 'lpcm',
            channelsPerFrame: this.$.stream.readUInt16(),
            sampleCount: this.$.stream.readUInt32(),
            bitsPerChannel: this.$.stream.readUInt16(),
            sampleRate: this.$.stream.readFloat80()
          };
          if (this.fileType === 'AIFC') {
            format = this.$.stream.readString(4);
            if (format === 'twos' || format === 'sowt' || format === 'fl32' || format === 'fl64' || format === 'NONE') {
              format = 'lpcm';
            }
            this.$.format.formatID = format;
            this.$.format.littleEndian = format === 'sowt';
            this.$.format.floatingPoint = format === 'fl32' || format === 'fl64';
            this.len -= 4;
          }
          this.$.stream.advance(this.len - 18);
          this.emit('format', this.$.format);
          this.emit('duration', this.$.format.sampleCount / this.$.format.sampleRate * 1000 | 0);
          break;
        case 'SSND':
          if (!(this.readSSNDHeader && this.$.stream.available(4))) {
            offset = this.$.stream.readUInt32();
            this.$.stream.advance(4);
            this.$.stream.advance(offset);
            this.readSSNDHeader = true;
          }
          buffer = this.$.stream.readSingleBuffer(this.len);
          this.len -= buffer.length;
          this.readHeaders = this.len > 0;
          this.emit('data', buffer, this.len === 0);
          break;
        default:
          if (!this.$.stream.available(this.len)) {
            return;
          }
          this.$.stream.advance(this.len);
      }
      if (this.type !== 'SSND') {
        this.readHeaders = false;
      }
    }
  };

  return AIFFDemuxer;

})(Aurora.Demuxer);

// Generated by CoffeeScript 1.3.3
var WAVEDemuxer,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

WAVEDemuxer = (function(_super) {
  var formats;

  __extends(WAVEDemuxer, _super);

  function WAVEDemuxer() {
    return WAVEDemuxer.__super__.constructor.apply(this, arguments);
  }

  Aurora.Demuxer.register(WAVEDemuxer);

  WAVEDemuxer.probe = function(buffer) {
    return buffer.peekString(0, 4) === 'RIFF' && buffer.peekString(8, 4) === 'WAVE';
  };

  formats = {
    0x0001: 'lpcm',
    0x0003: 'lpcm',
    0x0006: 'alaw',
    0x0007: 'ulaw'
  };

  WAVEDemuxer.prototype.readChunk = function() {
    var buffer, bytes, encoding;
    if (!this.readStart && this.$.stream.available(12)) {
      if (this.$.stream.readString(4) !== 'RIFF') {
        return this.emit('error', 'Invalid WAV file.');
      }
      this.fileSize = this.$.stream.readUInt32(true);
      this.readStart = true;
      if (this.$.stream.readString(4) !== 'WAVE') {
        return this.emit('error', 'Invalid WAV file.');
      }
    }
    while (this.$.stream.available(1)) {
      if (!this.readHeaders && this.$.stream.available(8)) {
        this.type = this.$.stream.readString(4);
        this.len = this.$.stream.readUInt32(true);
      }
      switch (this.type) {
        case 'fmt ':
          encoding = this.$.stream.readUInt16(true);
          if (!(encoding in formats)) {
            return this.emit('error', 'Unsupported format in WAV file.');
          }
          this.$.format = {
            formatID: formats[encoding],
            floatingPoint: encoding === 0x0003,
            littleEndian: formats[encoding] === 'lpcm',
            channelsPerFrame: this.$.stream.readUInt16(true),
            sampleRate: this.$.stream.readUInt32(true)
          };
          this.$.stream.advance(4);
          this.$.stream.advance(2);
          this.$.format.bitsPerChannel = this.bitsPerChannel = this.$.stream.readUInt16(true);
          this.emit('format', this.$.format);
          break;
        case 'data':
          if (!this.sentDuration) {
            bytes = this.bitsPerChannel / 8;
            this.emit('duration', this.len / bytes / this.$.format.channelsPerFrame / this.$.format.sampleRate * 1000 | 0);
            this.sentDuration = true;
          }
          buffer = this.$.stream.readSingleBuffer(this.len);
          this.len -= buffer.length;
          this.readHeaders = this.len > 0;
          this.emit('data', buffer, this.len === 0);
          break;
        default:
          if (!this.$.stream.available(this.len)) {
            return;
          }
          this.$.stream.advance(this.len);
      }
      if (this.type !== 'data') {
        this.readHeaders = false;
      }
    }
  };

  return WAVEDemuxer;

})(Aurora.Demuxer);

// Generated by CoffeeScript 1.3.3
var AUDemuxer,
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

AUDemuxer = (function(_super) {
  var bps, formats;

  __extends(AUDemuxer, _super);

  function AUDemuxer() {
    return AUDemuxer.__super__.constructor.apply(this, arguments);
  }

  Aurora.Demuxer.register(AUDemuxer);

  AUDemuxer.probe = function(buffer) {
    return buffer.peekString(0, 4) === '.snd';
  };

  bps = [8, 8, 16, 24, 32, 32, 64];

  bps[26] = 8;

  formats = {
    1: 'ulaw',
    27: 'alaw'
  };

  AUDemuxer.prototype.readChunk = function() {
    var buf, bytes, dataSize, encoding, size, _results;
    if (!this.readHeader && this.$.stream.available(24)) {
      if (this.$.stream.readString(4) !== '.snd') {
        return this.emit('error', 'Invalid AU file.');
      }
      size = this.$.stream.readUInt32();
      dataSize = this.$.stream.readUInt32();
      encoding = this.$.stream.readUInt32();
      this.$.format = {
        formatID: formats[encoding] || 'lpcm',
        floatingPoint: encoding === 6 || encoding === 7,
        bitsPerChannel: bps[encoding - 1],
        sampleRate: this.$.stream.readUInt32(),
        channelsPerFrame: this.$.stream.readUInt32()
      };
      if (!(this.$.format.bitsPerChannel != null)) {
        return this.emit('error', 'Unsupported encoding in AU file.');
      }
      if (dataSize !== 0xffffffff) {
        bytes = this.$.format.bitsPerChannel / 8;
        this.emit('duration', dataSize / bytes / this.$.format.channelsPerFrame / this.$.format.sampleRate * 1000 | 0);
      }
      this.emit('format', this.$.format);
      this.readHeader = true;
    }
    if (this.readHeader) {
      _results = [];
      while (this.$.stream.available(1)) {
        buf = this.$.stream.readSingleBuffer(this.$.stream.remainingBytes());
        _results.push(this.emit('data', buf, this.$.stream.remainingBytes() === 0));
      }
      return _results;
    }
  };

  return AUDemuxer;

})(Aurora.Demuxer);


// Generated by CoffeeScript 1.3.3
var LPCMDecoder,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

LPCMDecoder = (function(_super) {

  __extends(LPCMDecoder, _super);

  function LPCMDecoder() {
    this.readChunk = __bind(this.readChunk, this);
    return LPCMDecoder.__super__.constructor.apply(this, arguments);
  }

  Aurora.Decoder.register('lpcm', LPCMDecoder);

  LPCMDecoder.prototype.init = function() {
    return this.floatingPoint = this.$.format.floatingPoint;
  };

  LPCMDecoder.prototype.readChunk = function() {
    var chunkSize, i, littleEndian, output, samples, stream, _i, _j, _k, _l, _m, _n;
    stream = this.$.stream;
    littleEndian = this.$.format.littleEndian;
    chunkSize = Math.min(4096, stream.remainingBytes());
    samples = chunkSize / (this.$.format.bitsPerChannel / 8) >> 0;
    if (chunkSize === 0) {
      return this.once('available', this.readChunk);
    }
    if (this.$.format.floatingPoint) {
      switch (this.$.format.bitsPerChannel) {
        case 32:
          output = new Float32Array(samples);
          for (i = _i = 0; _i < samples; i = _i += 1) {
            output[i] = stream.readFloat32(littleEndian);
          }
          break;
        case 64:
          output = new Float64Array(samples);
          for (i = _j = 0; _j < samples; i = _j += 1) {
            output[i] = stream.readFloat64(littleEndian);
          }
          break;
        default:
          return this.emit('error', 'Unsupported bit depth.');
      }
    } else {
      switch (this.$.format.bitsPerChannel) {
        case 8:
          output = new Int8Array(samples);
          for (i = _k = 0; _k < samples; i = _k += 1) {
            output[i] = stream.readInt8();
          }
          break;
        case 16:
          output = new Int16Array(samples);
          for (i = _l = 0; _l < samples; i = _l += 1) {
            output[i] = stream.readInt16(littleEndian);
          }
          break;
        case 24:
          output = new Int32Array(samples);
          for (i = _m = 0; _m < samples; i = _m += 1) {
            output[i] = stream.readInt24(littleEndian);
          }
          break;
        case 32:
          output = new Int32Array(samples);
          for (i = _n = 0; _n < samples; i = _n += 1) {
            output[i] = stream.readInt32(littleEndian);
          }
          break;
        default:
          return this.emit('error', 'Unsupported bit depth.');
      }
    }
    return this.emit('data', output);
  };

  return LPCMDecoder;

})(Aurora.Decoder);

// Generated by CoffeeScript 1.3.3
var XLAWDecoder,
  __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
  __hasProp = {}.hasOwnProperty,
  __extends = function(child, parent) { for (var key in parent) { if (__hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; };

XLAWDecoder = (function(_super) {
  var BIAS, QUANT_MASK, SEG_MASK, SEG_SHIFT, SIGN_BIT;

  __extends(XLAWDecoder, _super);

  Aurora.Decoder.register('ulaw', XLAWDecoder);

  Aurora.Decoder.register('alaw', XLAWDecoder);

  SIGN_BIT = 0x80;

  QUANT_MASK = 0xf;

  SEG_SHIFT = 4;

  SEG_MASK = 0x70;

  BIAS = 0x84;

  function XLAWDecoder() {
    this.readChunk = __bind(this.readChunk, this);

    var i, seg, t, table, val, _i, _j;
    XLAWDecoder.__super__.constructor.call(this);
    this.$.format.bitsPerChannel = 16;
    this.table = table = new Float32Array(256);
    if (this.$.format.formatID === 'ulaw') {
      for (i = _i = 0; _i < 256; i = ++_i) {
        val = ~i;
        t = ((val & QUANT_MASK) << 3) + BIAS;
        t <<= (val & SEG_MASK) >>> SEG_SHIFT;
        table[i] = val & SIGN_BIT ? BIAS - t : t - BIAS;
      }
    } else {
      for (i = _j = 0; _j < 256; i = ++_j) {
        val = i ^ 0x55;
        t = val & QUANT_MASK;
        seg = (val & SEG_MASK) >>> SEG_SHIFT;
        if (seg) {
          t = (t + t + 1 + 32) << (seg + 2);
        } else {
          t = (t + t + 1) << 3;
        }
        table[i] = val & SIGN_BIT ? t : -t;
      }
    }
    return;
  }

  XLAWDecoder.prototype.readChunk = function() {
    var chunkSize, i, output, samples, stream, table, _i;
    stream = this.stream, table = this.table;
    chunkSize = Math.min(4096, this.$.stream.remainingBytes());
    samples = chunkSize / (this.$.format.bitsPerChannel / 8) >> 0;
    if (chunkSize === 0) {
      return this.once('available', this.readChunk);
    }
    output = new Int16Array(samples);
    for (i = _i = 0; _i < samples; i = _i += 1) {
      output[i] = table[stream.readUInt8()];
    }
    return this.emit('data', output);
  };

  return XLAWDecoder;

})(Aurora.Decoder);


