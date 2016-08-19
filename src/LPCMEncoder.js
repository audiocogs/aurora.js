import Encoder from './Encoder';

export default class LPCMEncoder extends Encoder {
  init() {
    this.mult = Math.pow(2, this.format.bitsPerChannel - 1);
    this.min = -mult;
    this.max = mult - 1;
  }
  
  encode(buffer) {
    let samples = new Float32Array(buffer.buffer);
    for (let i = 0; i < samples.length; i++) {
      this.stream.writeInt16(Math.min(this.max, Math.max(this.min, samples[i] * this.mult)), this.format.littleEndian);
    }
  }
}
