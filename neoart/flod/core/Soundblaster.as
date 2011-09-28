/* FlodXM Alpha 3
   2011/09/17
   Christian Corti
   Neoart Costa Rica

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 	 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 	 LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
 	 IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

package neoart.flod.core {
  import flash.events.*;
  import flash.utils.*;

  public final class Soundblaster {
    public static const
      BUFFER_SIZE : int = 8192;
    public var
      player      : SBPlayer,
      channels    : Vector.<SBChannel>,
      record      : int,
      samplesTick : int;
    private var
      buffer      : Vector.<Sample>,
      completed   : int,
      remains     : int,
      samplesLeft : int,
      wave        : ByteArray;

    public function Soundblaster() {
      var i:int, len:int;
      wave = new ByteArray();
      wave.endian = "littleEndian";

      len = BUFFER_SIZE;
      buffer = new Vector.<Sample>(len, true);
      buffer[0] = new Sample();

      for (i = 1; i < len; ++i)
        buffer[i] = buffer[int(i - 1)].next = new Sample();
    }

    public function set complete(value:int):void {
      completed = value ^ player.loopSong;
    }

    public function get waveform():ByteArray {
      var snd:ByteArray = new ByteArray();
      snd.endian = "littleEndian";

      snd.writeUTFBytes("RIFF");
      snd.writeInt(wave.length + 44);
      snd.writeUTFBytes("WAVEfmt ");
      snd.writeInt(16);
      snd.writeShort(1);
      snd.writeShort(2);
      snd.writeInt(44100);
      snd.writeInt(44100 << 2);
      snd.writeShort(4);
      snd.writeShort(16);
      snd.writeUTFBytes("data");
      snd.writeInt(wave.length);
      snd.writeBytes(wave);

      snd.position = 0;
      return snd;
    }

    internal function setup(len:int):void {
      var i:int;
      channels = new Vector.<SBChannel>(len, true);
      channels[0] = new SBChannel(0);

      for (i = 1; i < len; ++i)
        channels[i] = channels[int(i - 1)].next = new SBChannel(i);
    }

    internal function initialize():void {
      var chan:SBChannel = channels[0], sample:Sample = buffer[0];
      wave.clear();
      completed   = 0;
      remains     = 0;
      samplesLeft = 0;

      while (chan) {
        chan.initialize();
        chan = chan.next;
      }

      while (sample) {
        sample.l = sample.r = 0.0;
        sample = sample.next;
      }
    }

    internal function mix(e:SampleDataEvent):void {
      var chan:SBChannel, d:Vector.<Number>, data:ByteArray = e.data, i:int, j:int, len:int, mixed:int, mixLen:int, mixPos:int, s:SBSample, sample:Sample, size:int = BUFFER_SIZE, toMix:int, value:Number = 0.0;

      if (completed) {
        if (!remains) return;
        size = remains;
      }

      len  = channels.length;

      while (mixed < size) {
        if (!samplesLeft) {
          player.process();
          samplesLeft = samplesTick;
          if (completed) {
            size = mixed + samplesTick;
            if (size > BUFFER_SIZE) {
              remains = size - BUFFER_SIZE;
              size = BUFFER_SIZE;
            }
          }
        }

        toMix = samplesLeft;
        if ((mixed + toMix) >= size) toMix = size - mixed;
        mixLen = mixPos + toMix;
        chan = channels[0];

        for (i = 0; i < len; ++i) {
          if (!chan.sample || !chan.sample.data) {
            chan = chan.next;
            continue;
          }
          s = chan.sample;
          d = s.data;
          sample = buffer[mixPos];

          for (j = mixPos; j < mixLen; ++j) {
            if (!chan.mute) value = d[int(chan.pointer)];
            chan.pointer += chan.speed;

            sample.l += value * chan.lvol;
            sample.r += value * chan.rvol;
            sample = sample.next;
            value = 0.0;

            if (chan.speed < 0) {
              if (chan.pointer <= chan.counter) {
                chan.pointer = s.loopStart + (chan.counter - chan.pointer);
                chan.counter = s.length;
                chan.speed = -chan.speed;
              }
            } else {
              if (chan.pointer >= chan.counter) {
                if (s.loopMode == 1) {
                  chan.pointer = s.loopStart + (chan.pointer - chan.counter);
                  chan.counter = s.length;
                } else if (s.loopMode == 2) {
                  chan.pointer = s.length - (chan.pointer - chan.counter);
                  if (chan.pointer == s.length) chan.pointer -= 0.00000000001;
                  chan.counter = s.loopStart;
                  chan.speed = -chan.speed;
                } else {
                  chan.sample = null;
                  break;
                }
              }
            }
          }
          chan = chan.next;
        }

        mixPos = mixLen;
        mixed += toMix;
        samplesLeft -= toMix;
      }

      sample = buffer[0];

      if (record) {
        for (i = 0; i < size; ++i) {
          if (sample.l > 1.0) sample.l = 1.0;
            else if (sample.l < -1.0) sample.l = -1.0;
          if (sample.r > 1.0) sample.r = 1.0;
            else if (sample.r < -1.0) sample.r = -1.0;

          wave.writeShort(65536 + int(sample.l * 65536));
          wave.writeShort(65536 + int(sample.r * 65536));

          data.writeFloat(sample.l);
          data.writeFloat(sample.r);
          sample.l = sample.r = 0.0;
          sample = sample.next;
        }
      } else {
        for (i = 0; i < size; ++i) {
          if (sample.l > 1.0) sample.l = 1.0;
            else if (sample.l < -1.0) sample.l = -1.0;
          if (sample.r > 1.0) sample.r = 1.0;
            else if (sample.r < -1.0) sample.r = -1.0;

          data.writeFloat(sample.l);
          data.writeFloat(sample.r);
          sample.l = sample.r = 0.0;
          sample = sample.next;
        }
      }
    }
  }
}