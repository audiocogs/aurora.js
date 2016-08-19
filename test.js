import fs from 'fs';
import WAVDemuxer from './src/WAVDemuxer';
import {MP4Demuxer} from 'mp4';
import Speaker from 'speaker';
import AACDecoder from 'aac/src/decoder';
import {MP3Demuxer, MP3Decoder} from 'mp3';
import WAVMuxer from './src/WAVMuxer';
import Track from './src/Track';
import LPCMEncoder from './src/LPCMEncoder';

fs.createReadStream(process.argv[process.argv.length - 1])
  .pipe(new MP3Demuxer)
  .on('metadata', console.log)
  .on('track', function(track) {
    console.log(track.type, track.format)
    
    if (track.type === 'audio') {
      let decoder = new MP3Decoder(track.format);
      // let speaker = new Speaker({
      //   channels: track.format.channelsPerFrame,
      //   sampleRate: track.format.sampleRate,
      //   bitDepth: track.format.bitsPerChannel,
      //   float: track.format.floatingPoint
      // });
      //
      // track.pipe(decoder).pipe(speaker);
      // track.pipe(decoder).pipe(fs.createWriteStream('/dev/null'))
      let muxer = new WAVMuxer;
      let trk = new Track(track.type, {
        formatID: 'lpcm',
        channelsPerFrame: track.format.channelsPerFrame,
        bitsPerChannel: 16,
        sampleRate: track.format.sampleRate,
        littleEndian: true,
        // floatingPoint: true
      });
      
      let encoder = new LPCMEncoder(trk.format);
      
      muxer.addTrack(trk);
      muxer.pipe(fs.createWriteStream('out.wav'));
      track.pipe(decoder).pipe(encoder).pipe(trk);
    } else {
      track.discard();
    }
  });
