import {Transform} from 'stream';
import StreamWriter from 'binary-io/writer/StreamWriter';

export default class Encoder extends Transform {
  constructor(format) {
    super();
    
    this.format = format;
    this.stream = new StreamWriter(this);
    
    this.init();
  }
  
  init() {}
  encode(buffer) {}
  finalize() {}
  
  _transform(chunk, encoding, callback) {
    this.encode(chunk);
    // console.log(this.stream.offset)
    callback();
  }
  
  _flush(callback) {
    this.finalize();
    this.stream.end();
    callback();
  }
}
