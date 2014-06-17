Aurora.js
=========

Aurora.js is a framework that makes writing audio decoders in JavaScript easier.  It handles common 
tasks for you such as dealing with binary data, and the decoding pipeline from source to demuxer to 
decoder, and finally to the audio hardware itself by abstracting browser audio APIs.  Aurora contains 
two high level APIs for inspecting and playing back decoded audio, and it is easily extendible to support 
more sources, demuxers, decoders, and audio devices.

Check out the [documentation](https://github.com/audiocogs/aurora.js/wiki) to learn more about using and 
extending Aurora.

## Demo

We have written several decoders using Aurora.js, whose demos you can find [here](http://audiocogs.org/codecs/)
and whose source code can be found on our [Github](https://github.com/audiocogs/) page.

## Authors

Aurora.js was written by [@jensnockert](https://github.com/jensnockert) and [@devongovett](https://github.com/devongovett) 
of [Audiocogs](https://github.com/audiocogs/).

## Usage

You can use Aurora.js both in the browser, as well as in Node.js.  In the browser,
you can either download a prebuilt [release](https://github.com/audiocogs/aurora.js/releases)
or use [browserify](https://github.com/substack/node-browserify) to build it into your own 
app bundle (see below for Node.js usage - it's the same for browserify).

```html
<script src="aurora.js"></script>
<script src="mp3.js"></script>
<!-- more codecs here -->
```

To use Aurora.js in Node.js or a browserify build, you can install it from `npm`:

    npm install av
    
Then, require the module and codecs you need:

```javascript
var AV = require('av');
require('mp3');
// more codecs here...
```

For much more detailed information on how to use Aurora.js, check out the 
[documentation](https://github.com/audiocogs/aurora.js/wiki).

## Building

We use [browserify](https://github.com/substack/node-browserify) to build Aurora.js.  To build Aurora.js 
for the browser yourself, use the following commands:

    npm install
    make browser
    
This will place a built `aurora.js` file, as well as a source map in the `build/` directory.

By itself, Aurora will play LPCM, uLaw and aLaw files in a number of containers.
Be sure to add additional codec support by including some of our other decoders:

* [FLAC.js](https://github.com/audiocogs/flac.js) 
* [ALAC.js](https://github.com/audiocogs/alac.js)
* [MP3.js](https://github.com/audiocogs/mp3.js)
* [AAC.js](https://github.com/audiocogs/aac.js)

If you want to build Aurora without the default codecs, you can use the "browser_slim" profile:

    make browser_slim

This can help shave off approx. 30 KB from the joined file, or 20 KB when minified.

## License

Aurora.js is released under the MIT license.