Notes on Websocket Fork of Aurora.js
=========

The integrated websocket code is based upon [aurora-websocket](https://github.com/fabienbrooke/aurora-websocket) 
library written by [@fabienbrooke](https://github.com/fabienbrooke).

There are two new sources that this code makes available - WebsocketSource and 
WSWorkerSource.  As the name implies, WSWorkerSource is functionally identical 
to WebsocketSource except that it runs in a web worker and uses transferable objects
to minimize the latency this introduces.

## Other Changes

A number of changes were made to the Aurora code.  In most cases, this is to facilitate
better handling of streaming live content.

### core/buffer.coffee

The *append* method was added to allow the websockets code to buffer the first
few blocks of data.  This was necessary since some decoders (mp3.js in particular)
expect multiple frames of audio to be available when Asset#probe is called.

```javascript
var audioBuffer = new AVBuffer(data);
audioBuffer.append(newData);
```

Because *append* needed to rationalize the new data in the same way that the constructor
does, a *sanitize* method was also added.

### device/webaudio.coffee

This code was updated to allow the system to decide the proper size of the buffer
for the ScriptNodeProcessor.  On older implementations that support
the obsolete JavaScriptNode, the buffer size must be supplied, as having the system
chose the best size was not available.

### asset.coffee

Added references to WebsocketSource and WSWorkerSource source files.  Also added methods
for creating the new sources - Asset#fromWebSocket and Asset#fromWSWorker.  Both forms
take the URL for the websocket server and the path to the asset being requested.

```javascript
var wsUrl = "wss://www.example.org/wss",
	wsFile = "someAudio.mp3";

var asset = new Asset.fromWebSocket(wsUrl, wsFile);
```

### queue.coffee

Initially, Aurora would stop if the queue of decoded audio was depleted.
In a non-streaming context, this makes perfect sense.  However, slow network connections
make it a very real possibility when streaming live audio.  In order to accomodate this,
the Queue class was updated to emit "buffering" and stop the output device when
the queue was nearing depletion.  It will then emit "ready" again when the queue
is replenished.  In addition, the readyMark variable was changed to represent
a byte length rather than a number of audio frames.

## License

Aurora.js, aurora-websocket and all additional code are released under the MIT license.