import fs from 'fs';
import WAVDemuxer from './src/WAVDemuxer';
import {MP4Demuxer} from 'mp4';
import Speaker from 'speaker';
import AACDecoder from 'aac/src/decoder';

fs.createReadStream(process.argv[process.argv.length - 1])
  .pipe(new M4ADemuxer)
  .on('track', function(track) {
    let decoder = new AACDecoder(track.format);
    console.log(track.format);
    
    let speaker = new Speaker({
      channels: track.format.channelsPerFrame,
      sampleRate: track.format.sampleRate,
      bitDepth: track.format.bitsPerChannel,
      float: track.format.floatingPoint
    });
    
    track.pipe(decoder).pipe(speaker);
  });
