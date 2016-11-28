(function () {
  'use strict';

	var config, socket, host, path, firstData, 
		bytesLoaded, length, bufferMessages = [],
		ack, open, paused;

	var init = function (config) {
		config = config || {};
		host = config.host || null;
		path = config.path || null;
		if (typeof WebSocket === "undefined" || WebSocket === null) {
			return throwError('This browser does not have WebSocket support.');
		}
		socket = new WebSocket(host);
		if (socket.binaryType == null) {
			socket.close();
			return throwError('This browser does not have binary WebSocket support.');
		}
		bytesLoaded = 0;
		length = 0;
		ack = false;
		paused = false;
		open = false;
		setupSocket();
		
		console.log('Websocket worker started.');
	};

	var throwError = function (errMsg) {
		console.log(errMsg);
		postMessage({"cmd": "error", "error": errMsg});
	};
	
	var send = function (msg) {
		if (!open) {
			bufferMessages.push(msg);
		} else {
			socket.send(JSON.stringify(msg));
		}
	};

	var syn = function () {
		if (!ack) {
			send({"syn": true});
      		setTimeout(function() {
				return syn();
			}, 100);
		}
	};

	var setupSocket = function () {
    	socket.binaryType = 'arraybuffer';
    	socket.onopen = function() {
			open = true;
			setTimeout(function() {
				return syn();
			}, 100);
		};

		socket.onmessage = function(e) {
			var buf, data;
			data = e.data;
			if (typeof data === 'string') {
				data = JSON.parse(data);
				if (data.ack != null) {
					ack = true;
					if (path) {
						send({"file": path});
					}
					while (bufferMessages.length > 0) {
						send(bufferMessages.shift());
					}
				}
				if (data.fileSize != null) {
					postMessage({"cmd": "fileSize", "value": data.fileSize});
				}
				if (data.error != null) {
					postMessage({"cmd": "error", "error": data.error});
				}
				if (data.end) {
					postMessage({"cmd": "end"});
					open = false;
					socket.close();
				}
			} else {
				buf = new Uint8Array(data);
				if (length) {
					postMessage({"cmd": "progress", "value": bytesLoaded / length * 100});
				}
				postMessage({"cmd": "data", "data": buf.buffer},[buf.buffer]);
			}
		};
		
		socket.onclose = function(e) {
			open = false;
			if (e.wasClean) {
				postMessage({'end':true});
			} else {
				throwError('WebSocket closed uncleanly with code ' + e.code + '.');
			}
		};

		socket.onerror = function(err) {
			throwError(err);
		};
	};
	
	onmessage = function (e) {
		switch (e.data.cmd) {
			case 'init':
				init(e.data.config);
				break;

			case 'play':
				send({'play': true});
				break;

			case 'pause':
				if (!paused) {
					paused = true;
					send({'pause': true});
				}
				break;

			case 'resume':
				if (paused) {
					paused = false;
					send({'resume': true});
				}
				break;

			case 'reset':
				send({'reset':true});
				break;

		};
	}
})();