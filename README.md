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

## Building

Currently, the [importer](https://github.com/devongovett/importer) module is used to build Aurora.js.  You can run
the development server by first installing `importer` with npm, and then running it like this:

    npm install importer -g
    importer browser.coffee -p 8080
    
You can also build a static version like this:

    importer browser.coffee aurora.js
    
By itself, Aurora will play LPCM, uLaw and aLaw files in a number of containers.  Be sure to add additional codec support 
by including some of our other decoders such as [FLAC.js](https://github.com/audiocogs/flac.js), 
[ALAC.js](https://github.com/audiocogs/alac.js), and [MP3.js](https://github.com/devongovett/mp3.js).

If you want to build Aurora without the default codecs, you can use the "browser_slim.coffee" profile:

    importer browser_slim.coffee aurora.js

This can help shave off approx. 30 KB from the joined file, or 20 KB when minified.
    
## License

Aurora.js is released under the MIT license.