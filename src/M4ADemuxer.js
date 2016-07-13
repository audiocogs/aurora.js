import Demuxer from './Demuxer';

// common file type identifiers
// see http://mp4ra.org/filetype.html for a complete list
const TYPES = ['M4A ', 'M4P ', 'M4B ', 'M4V ', 'isom', 'mp42', 'qt  '];

// lookup table for atom handlers
let atoms = {};

// lookup table of container atom names
let containers = {};

class M4ADemuxer extends Demuxer {
  static probe(buffer) {
    return buffer.peekString(4, 4) === 'ftyp' &&
           TYPES.indexOf(buffer.peekString(8, 4)) !== -1;
  }
    
  init() {
    // current atom heirarchy stacks
    this.atoms = [];
    this.offsets = [];
    
    // m4a files can have multiple tracks
    this.track = null;
    return this._tracks = [];
  }
    
  readChunk() {
    this.break = false;
    
    while (this.stream.available(1) && !this.break) {
      // if we're ready to read a new atom, add it to the stack
      if (!this.readHeaders) {
        if (!this.stream.available(8)) { return false; }
        
        this.len = this.stream.readUInt32() - 8;
        this.type = this.stream.readString(4);
        
        if (this.len === 0) { continue; }
        
        this.atoms.push(this.type);
        this.offsets.push(this.stream.offset + this.len);
        this.readHeaders = true;
      }
        
      // find a handler for the current atom heirarchy
      let path = this.atoms.join('.');        
      let handler = atoms[path];
      
      if (handler && handler.fn) {
        // wait until we have enough data, unless this is the mdat atom
        if (!this.stream.available(this.len) && path !== 'mdat') {
          return false;
        }

        // call the parser for the atom type
        handler.fn.call(this);
        
        // check if this atom can contain sub-atoms
        if (path in containers) {
          this.readHeaders = false;
        }
          
      // handle container atoms
      } else if (path in containers) {
        this.readHeaders = false;
        
      // unknown atom
      } else {
        // wait until we have enough data
        if (!this.stream.available(this.len)) {
          return false;
        }
          
        this.stream.advance(this.len);
      }
        
      // pop completed items from the stack
      while (this.stream.offset >= this.offsets[this.offsets.length - 1]) {
        // call after handler
        handler = atoms[this.atoms.join('.')];
        if (handler && handler.after) {
          handler.after.call(this);
        }
        
        let type = this.atoms.pop();
        this.offsets.pop();
        this.readHeaders = false;
      }
    }
    
    return !this.break;
  }
    
  // reads a variable length integer
  static readDescrLen(stream) {
    let len = 0;
    let count = 4;

    while (count--) {
      let c = stream.readUInt8();
      len = (len << 7) | (c & 0x7f);
      if (!c & 0x80) { break; }
    }

    return len;
  }
    
  static readEsds(stream) {
    stream.advance(4); // version and flags
    
    let tag = stream.readUInt8();
    let len = M4ADemuxer.readDescrLen(stream);

    if (tag === 0x03) { // MP4ESDescrTag
      stream.advance(2); // id
      let flags = stream.readUInt8();

      if (flags & 0x80) { // streamDependenceFlag
        stream.advance(2);
      }

      if (flags & 0x40) { // URL_Flag
        stream.advance(stream.readUInt8());
      }

      if (flags & 0x20) { // OCRstreamFlag
        stream.advance(2);
      }

    } else {
      stream.advance(2); // id
    }

    tag = stream.readUInt8();
    len = M4ADemuxer.readDescrLen(stream);
      
    if (tag === 0x04) { // MP4DecConfigDescrTag
      let codec_id = stream.readUInt8(); // might want this... (isom.c:35)
      stream.advance(1); // stream type
      stream.advance(3); // buffer size
      stream.advance(4); // max bitrate
      stream.advance(4); // avg bitrate

      tag = stream.readUInt8();
      len = M4ADemuxer.readDescrLen(stream);
      
      if (tag === 0x05) { // MP4DecSpecificDescrTag
        return stream.readBuffer(len);
      }
    }
    
    return null;
  }
    
  // once we have all the information we need, generate the seek table for this track
  setupSeekPoints() {
    if ((this.track.chunkOffsets == null) || (this.track.stsc == null) || (this.track.sampleSize == null) || (this.track.stts == null)) { return; }
    
    let stscIndex = 0;
    let sttsIndex = 0;
    sttsIndex = 0;
    let sttsSample = 0;
    let sampleIndex = 0;
    
    let offset = 0;
    let timestamp = 0;
    this.track.seekPoints = [];
    
    for (let i = 0; i < this.track.chunkOffsets.length; i++) {
      let position = this.track.chunkOffsets[i];
      for (let j = 0, len = this.track.stsc[stscIndex].count; j < len; j++) {
        // push the timestamp and both the physical position in the file
        // and the offset without gaps from the start of the data
        this.track.seekPoints.push({
          offset,
          position,
          timestamp
        });
        
        let size = this.track.sampleSize || this.track.sampleSizes[sampleIndex++];
        offset += size;
        position += size;
        timestamp += this.track.stts[sttsIndex].duration;
        
        if (sttsIndex + 1 < this.track.stts.length && ++sttsSample === this.track.stts[sttsIndex].count) {
          sttsSample = 0;
          sttsIndex++;
        }
      }
          
      if (stscIndex + 1 < this.track.stsc.length && i + 1 === this.track.stsc[stscIndex + 1].first) {
        stscIndex++;
      }
    }
        
    return;
  }
      
  parseChapters() {
    if (!this.track.chapterTracks || this.track.chapterTracks.length <= 0) { return true; }

    // find the chapter track
    let id = this.track.chapterTracks[0];
    for (let i = 0; i < this._tracks.length; i++) {
      var track = this._tracks[i];
      if (track.id === id) { break; }
    }

    if (track.id !== id) {
      this.emit('error', 'Chapter track does not exist.');
    }

    if (this.chapters == null) { this.chapters = []; }
    
    // use the seek table offsets to find chapter titles
    while (this.chapters.length < track.seekPoints.length) {
      let left;
      let point = track.seekPoints[this.chapters.length];
      
      // make sure we have enough data
      if (!this.stream.available(point.position - this.stream.offset + 32)) { return false; }

      // jump to the title offset
      this.stream.seek(point.position);

      // read the length of the title string
      let len = this.stream.readUInt16();
      let title = null;
      
      if (!this.stream.available(len)) { return false; }
      
      // if there is a BOM marker, read a utf16 string
      if (len > 2) {
        let bom = this.stream.peekUInt16();
        if (bom === 0xfeff || bom === 0xfffe) {
          title = this.stream.readString(len, 'utf16-bom');
        }
      }

      // otherwise, use utf8
      if (typeof title === 'undefined' || title === null) { title = this.stream.readString(len, 'utf8'); }
      
      // add the chapter title, timestamp, and duration
      let seekPoint = track.seekPoints[this.chapters.length + 1];
      let nextTimestamp = (left = seekPoint && seekPoint.timestamp) != null ? left : track.duration;
      this.chapters.push({
        title,
        timestamp: point.timestamp / track.timeScale * 1000 | 0,
        duration: (nextTimestamp - point.timestamp) / track.timeScale * 1000 | 0
      });
    }
        
    // we're done, so emit the chapter data
    this.emit('chapters', this.chapters);
    return true;
  }
}
    
Demuxer.register(M4ADemuxer);
export default M4ADemuxer;

// declare a function to be used for parsing a given atom name
let atom = function(name, fn) {    
  let c = [];
  let iterable = name.split('.').slice(0, -1);
  for (let i = 0; i < iterable.length; i++) {
    let container = iterable[i];
    c.push(container);
    containers[c.join('.')] = true;
  }
    
  if (atoms[name] == null) { atoms[name] = {}; }
  return atoms[name].fn = fn;
};
  
// declare a function to be called after parsing of an atom and all sub-atoms has completed
let after = function(name, fn) {
  if (atoms[name] == null) { atoms[name] = {}; }
  return atoms[name].after = fn;
};

atom('ftyp', function() {
  if (!TYPES.indexOf(this.stream.readString(4)) === -1) {
    return this.emit('error', 'Not a valid M4A file.');
  }
  
  return this.stream.advance(this.len - 4);
});

atom('moov.trak', function() {
  this.track = {};
  return this._tracks.push(this.track);
});
  
atom('moov.trak.tkhd', function() {
  this.stream.advance(4); // version and flags
  
  this.stream.advance(8); // creation and modification time
  this.track.id = this.stream.readUInt32();
  
  return this.stream.advance(this.len - 16);
});
  
atom('moov.trak.mdia.hdlr', function() {
  this.stream.advance(4); // version and flags
  
  this.stream.advance(4); // component type
  this.track.type = this.stream.readString(4);
  
  this.stream.advance(12); // component manufacturer, flags, and mask
  return this.stream.advance(this.len - 24); // component name
});

atom('moov.trak.mdia.mdhd', function() {
  this.stream.advance(4); // version and flags
  this.stream.advance(8); // creation and modification dates
  
  this.track.timeScale = this.stream.readUInt32();
  this.track.duration = this.stream.readUInt32();
  
  return this.stream.advance(4); // language and quality
});
  
// corrections to bits per channel, base on formatID
// (ffmpeg appears to always encode the bitsPerChannel as 16)
let BITS_PER_CHANNEL = { 
  ulaw: 8,
  alaw: 8,
  in24: 24,
  in32: 32,
  fl32: 32,
  fl64: 64
};
  
atom('moov.trak.mdia.minf.stbl.stsd', function() {
  this.stream.advance(4); // version and flags
  
  let numEntries = this.stream.readUInt32();
  
  // just ignore the rest of the atom if this isn't an audio track
  if (this.track.type !== 'soun') {
    return this.stream.advance(this.len - 8);
  }
  
  if (numEntries !== 1) {
    return this.emit('error', "Only expecting one entry in sample description atom!");
  }
    
  this.stream.advance(4); // size
  
  let format = this.track.format = {};
  format.formatID = this.stream.readString(4);
  
  this.stream.advance(6); // reserved
  this.stream.advance(2); // data reference index
  
  let version = this.stream.readUInt16();
  this.stream.advance(6); // skip revision level and vendor
  
  format.channelsPerFrame = this.stream.readUInt16();
  format.bitsPerChannel = this.stream.readUInt16();
  
  this.stream.advance(4); // skip compression id and packet size
  
  format.sampleRate = this.stream.readUInt16();
  this.stream.advance(2);
  
  if (version === 1) {
    format.framesPerPacket = this.stream.readUInt32();
    this.stream.advance(4); // bytes per packet
    format.bytesPerFrame = this.stream.readUInt32();
    this.stream.advance(4); // bytes per sample
    
  } else if (version !== 0) {
    this.emit('error', 'Unknown version in stsd atom');
  }
    
  if (BITS_PER_CHANNEL[format.formatID] != null) {
    format.bitsPerChannel = BITS_PER_CHANNEL[format.formatID];
  }
    
  format.floatingPoint = format.formatID === 'fl32' || format.formatID === 'fl64';
  format.littleEndian = format.formatID === 'sowt' && format.bitsPerChannel > 8;
  
  if (['twos', 'sowt', 'in24', 'in32', 'fl32', 'fl64', 'raw ', 'NONE'].indexOf(format.formatID) !== -1) {
    return format.formatID = 'lpcm';
  }
});
  
atom('moov.trak.mdia.minf.stbl.stsd.alac', function() {
  this.stream.advance(4);
  return this.track.cookie = this.stream.readBuffer(this.len - 4);
});
  
atom('moov.trak.mdia.minf.stbl.stsd.esds', function() {
  let offset = this.stream.offset + this.len;
  this.track.cookie = M4ADemuxer.readEsds(this.stream);
  return this.stream.seek(offset); // skip garbage at the end 
});
  
atom('moov.trak.mdia.minf.stbl.stsd.wave.enda', function() {
  return this.track.format.littleEndian = !!this.stream.readUInt16();
});
  
// time to sample
atom('moov.trak.mdia.minf.stbl.stts', function() {
  this.stream.advance(4); // version and flags

  let entries = this.stream.readUInt32();
  this.track.stts = [];
  for (let i = 0; i < entries; i++) {
    this.track.stts[i] = {
      count: this.stream.readUInt32(),
      duration: this.stream.readUInt32()
    };
  }
    
  return this.setupSeekPoints();
});

// sample to chunk
atom('moov.trak.mdia.minf.stbl.stsc', function() {
  this.stream.advance(4); // version and flags

  let entries = this.stream.readUInt32();
  this.track.stsc = [];
  for (let i = 0; i < entries; i++) {
    this.track.stsc[i] = { 
      first: this.stream.readUInt32(),
      count: this.stream.readUInt32(),
      id: this.stream.readUInt32()
    };
  }
    
  return this.setupSeekPoints();
});

// sample size
atom('moov.trak.mdia.minf.stbl.stsz', function() {
  this.stream.advance(4); // version and flags

  this.track.sampleSize = this.stream.readUInt32();
  let entries = this.stream.readUInt32();

  if (this.track.sampleSize === 0 && entries > 0) {
    this.track.sampleSizes = [];
    for (let i = 0; i < entries; i++) {
      this.track.sampleSizes[i] = this.stream.readUInt32();
    }
  }
    
  return this.setupSeekPoints();
});

// chunk offsets
atom('moov.trak.mdia.minf.stbl.stco', function() { // TODO: co64
  this.stream.advance(4); // version and flags

  let entries = this.stream.readUInt32();
  this.track.chunkOffsets = [];
  for (let i = 0; i < entries; i++) {
    this.track.chunkOffsets[i] = this.stream.readUInt32();
  }
  
  return this.setupSeekPoints();
});

// chapter track reference
atom('moov.trak.tref.chap', function() {
  let entries = this.len >> 2;
  this.track.chapterTracks = [];
  for (let i = 0; i < entries; i++) {
    this.track.chapterTracks[i] = this.stream.readUInt32();
  }
  
  return;
});
    
after('moov', function() {    
  // if the mdat block was at the beginning rather than the end, jump back to it
  if (this.mdatOffset != null) {
    this.stream.seek(this.mdatOffset - 8);
  }

  // choose a track
  for (let i = 0; i < this._tracks.length; i++) {
    let track = this._tracks[i];
    if (track.type === 'soun') {
      this.track = track;
      break;
    }
  }

  if (this.track.type !== 'soun') {
    this.track = null;
    return this.emit('error', 'No audio tracks in m4a file.');
  }
  
  this.track.format.cookie = this.track.cookie;
  this.addTrack('audio', this.track.format, this.track.duration / this.track.timeScale * 1000 | 0);

  // use the seek points from the selected track
  return this.seekPoints = this.track.seekPoints;
});

atom('mdat', function() {
  if (!this.startedData) {
    if (this.mdatOffset == null) { this.mdatOffset = this.stream.offset; }

    // if we haven't read the headers yet, the mdat atom was at the beginning
    // rather than the end. Skip over it for now to read the headers first, and
    // come back later.
    if (this._tracks.length === 0) {
      let bytes = Math.min(this.stream.remainingBytes(), this.len);
      this.stream.advance(bytes);
      this.len -= bytes;
      return;
    }

    this.chunkIndex = 0;
    this.stscIndex = 0;
    this.sampleIndex = 0;
    this.tailOffset = 0;
    this.tailSamples = 0;

    this.startedData = true;
  }

  // read the chapter information if any
  if (!this.readChapters) {
    this.readChapters = this.parseChapters();
    if (this.break = !this.readChapters) { return; }
    this.stream.seek(this.mdatOffset);
  }

  // get the starting offset
  let offset = this.track.chunkOffsets[this.chunkIndex] + this.tailOffset;
  let length = 0;

  // make sure we have enough data to get to the offset
  if (!this.stream.available(offset - this.stream.offset)) {
    this.break = true;
    return;
  }

  // seek to the offset
  this.stream.seek(offset);

  // calculate the maximum length we can read at once
  while (this.chunkIndex < this.track.chunkOffsets.length) {
    // calculate the size in bytes of the chunk using the sample size table
    let numSamples = this.track.stsc[this.stscIndex].count - this.tailSamples;
    let chunkSize = 0;
    let sample = 0;
    for (; sample < numSamples; sample++) {
      let size = this.track.sampleSize || this.track.sampleSizes[this.sampleIndex];
  
      // if we don't have enough data to add this sample, jump out
      if (!this.stream.available(length + size)) { break; }
  
      length += size;
      chunkSize += size;
      this.sampleIndex++;
    }

    // if we didn't make it through the whole chunk, add what we did use to the tail
    if (sample < numSamples) {
      this.tailOffset += chunkSize;
      this.tailSamples += sample;
      break;
    } else {
      // otherwise, we can move to the next chunk
      this.chunkIndex++;
      this.tailOffset = 0;
      this.tailSamples = 0;
  
      // if we've made it to the end of a list of subsequent chunks with the same number of samples,
      // go to the next sample to chunk entry
      if (this.stscIndex + 1 < this.track.stsc.length && this.chunkIndex + 1 === this.track.stsc[this.stscIndex + 1].first) {
        this.stscIndex++;
      }
  
      // if the next chunk isn't right after this one, jump out
      if (offset + length !== this.track.chunkOffsets[this.chunkIndex]) {
        break;
      }
    }
  }

  // emit some data if we have any, otherwise wait for more
  if (length > 0) {
    this.tracks[0].write(this.stream.readBuffer(length));
    return this.break = this.chunkIndex === this.track.chunkOffsets.length;
  } else {
    return this.break = true;
  }
});
        
// metadata chunk
atom('moov.udta.meta', function() {
  this.metadata = {};    
  return this.stream.advance(4); // version and flags
});

// emit when we're done
after('moov.udta.meta', function() {
  return this.emit('metadata', this.metadata);
});

// convienience function to generate metadata atom handler
let meta = (field, name, fn) =>
  atom(`moov.udta.meta.ilst.${field}.data`, function() {
    this.stream.advance(8);
    this.len -= 8;
    return fn.call(this, name);
  })
;

// string field reader
let string = function(field) {
  return this.metadata[field] = this.stream.readString(this.len, 'utf8');
};

// from http://atomicparsley.sourceforge.net/mpeg-4files.html
meta('©alb', 'album', string);
meta('©arg', 'arranger', string);
meta('©art', 'artist', string);
meta('©ART', 'artist', string);
meta('aART', 'albumArtist', string);
meta('catg', 'category', string);
meta('©com', 'composer', string);
meta('©cpy', 'copyright', string);
meta('cprt', 'copyright', string);
meta('©cmt', 'comments', string);
meta('©day', 'releaseDate', string);
meta('desc', 'description', string);
meta('©gen', 'genre', string); // custom genres
meta('©grp', 'grouping', string);
meta('©isr', 'ISRC', string);
meta('keyw', 'keywords', string);
meta('©lab', 'recordLabel', string);
meta('ldes', 'longDescription', string);
meta('©lyr', 'lyrics', string);
meta('©nam', 'title', string);
meta('©phg', 'recordingCopyright', string);
meta('©prd', 'producer', string);
meta('©prf', 'performers', string);
meta('purd', 'purchaseDate', string);
meta('purl', 'podcastURL', string);
meta('©swf', 'songwriter', string);
meta('©too', 'encoder', string);
meta('©wrt', 'composer', string);

meta('covr', 'coverArt', function(field) {
  return this.metadata[field] = this.stream.readBuffer(this.len);
});

// standard genres
let genres = [
  "Blues", "Classic Rock", "Country", "Dance", "Disco", "Funk", "Grunge", 
  "Hip-Hop", "Jazz", "Metal", "New Age", "Oldies", "Other", "Pop", "R&B",
  "Rap", "Reggae", "Rock", "Techno", "Industrial", "Alternative", "Ska", 
  "Death Metal", "Pranks", "Soundtrack", "Euro-Techno", "Ambient", 
  "Trip-Hop", "Vocal", "Jazz+Funk", "Fusion", "Trance", "Classical", 
  "Instrumental", "Acid", "House", "Game", "Sound Clip", "Gospel", "Noise",
  "AlternRock", "Bass", "Soul", "Punk", "Space", "Meditative", "Instrumental Pop", 
  "Instrumental Rock", "Ethnic", "Gothic",  "Darkwave", "Techno-Industrial", 
  "Electronic", "Pop-Folk", "Eurodance", "Dream", "Southern Rock", "Comedy", 
  "Cult", "Gangsta", "Top 40", "Christian Rap", "Pop/Funk", "Jungle", 
  "Native American", "Cabaret", "New Wave", "Psychadelic", "Rave", "Showtunes",
  "Trailer", "Lo-Fi", "Tribal", "Acid Punk", "Acid Jazz", "Polka", "Retro", 
  "Musical", "Rock & Roll", "Hard Rock", "Folk", "Folk/Rock", "National Folk", 
  "Swing", "Fast Fusion", "Bebob", "Latin", "Revival", "Celtic", "Bluegrass",
  "Avantgarde", "Gothic Rock", "Progressive Rock", "Psychedelic Rock", "Symphonic Rock",
  "Slow Rock", "Big Band", "Chorus", "Easy Listening", "Acoustic", "Humour", "Speech", 
  "Chanson", "Opera", "Chamber Music", "Sonata", "Symphony", "Booty Bass", "Primus", 
  "Porn Groove", "Satire", "Slow Jam", "Club", "Tango", "Samba", "Folklore", "Ballad", 
  "Power Ballad", "Rhythmic Soul", "Freestyle", "Duet", "Punk Rock", "Drum Solo", 
  "A Capella", "Euro-House", "Dance Hall"
];

meta('gnre', 'genre', function(field) {
  return this.metadata[field] = genres[this.stream.readUInt16() - 1];
});

meta('tmpo', 'tempo', function(field) {
  return this.metadata[field] = this.stream.readUInt16();
});

meta('rtng', 'rating', function(field) {
  let rating = this.stream.readUInt8();
  return this.metadata[field] = rating === 2 ? 'Clean' : rating !== 0 ? 'Explicit' : 'None';
});

let diskTrack = function(field) {
  this.stream.advance(2);
  this.metadata[field] = this.stream.readUInt16() + ' of ' + this.stream.readUInt16();
  return this.stream.advance(this.len - 6);
};

meta('disk', 'diskNumber', diskTrack);
meta('trkn', 'trackNumber', diskTrack);

let bool = function(field) {
  return this.metadata[field] = this.stream.readUInt8() === 1;
};

meta('cpil', 'compilation', bool);
meta('pcst', 'podcast', bool);
meta('pgap', 'gapless', bool);
