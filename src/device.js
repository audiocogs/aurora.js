/*
 * The AudioDevice class is responsible for interfacing with various audio
 * APIs in browsers, and for keeping track of the current playback time
 * based on the device hardware time and the play/pause/seek state
 */

void function (global) {
	'use strict'

	var devices = []
	var device = Aurora.extend(Aurora.eventEmitter, 'Aurora::Device', {
		lastTime: { value: 0, writable: true }
	})

	device.constructor = function (sampleRate, channels) {
		Aurora.eventEmitter.constructor.apply(this)

		this.sampleRate = sampleRate, this.channels = channels
		this.playing = false
		this.currentTime = 0
	}

	device.constructor.register = function (device) {
		devices.push(device)
	}

	device.constructor.create = function (sampleRate, channels) {
		for (var i = 0; i < devices.length; i++) {
			if (devices[i].supported) {
				return new devices[i](sampleRate, channels)
			}
		}

		return null
	}

	device.start = function () {
		if (this.playing) { return }

		this.playing = true
		this.device = Aurora.Device.create(this.sampleRate, this.channels)
		this.$.lastTime = this.device.getDeviceTime()

		this.$.timer = setInterval(this.updateTime.bind(this), 200)
		this.$.refill = function (buffer) {
			this.emit('refill', buffer)
		}.bind(this)

		this.device.on('refill', this.$.refill)
	}

	device.stop = function () {
		if (!this.playing) { return }

		this.playing = false

		this.device.off('refill', this.$.refill)

		clearInterval(this.$.timer)
	}

	device.destroy = function () {
		this.stop()

		this.device.destroy()
	}

	device.seek = function (currentTime) {
		this.currentTime = currentTime

		this.$.lastTime = this.device.getDeviceTime()

		this.emit('timeUpdate', currentTime)
	}

	device.updateTime = function () {
		var time = this.device.getDeviceTime()
		this.currentTime += ((time - this.$.lastTime) / this.device.sampleRate * 1000) >> 0
		this.$.lastTime = time

		this.emit('timeUpdate', this.currentTime)
	}

	Aurora.device = device
	Aurora.Device = device.constructor

	Aurora.Device.prototype = device
}(this)
