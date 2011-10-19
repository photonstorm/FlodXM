/* FlodXM Alpha 3
   2011/09/17
   Christian Corti
   Neoart Costa Rica

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 	 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 	 LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
 	 IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

package neoart.flod.core;

import flash.events.SampleDataEvent;
import flash.utils.ByteArray;
import flash.Vector;

@final class Soundblaster 
{
  public static inline var BUFFER_SIZE : Int = 8192;

  public var player      : SBPlayer;
  public var channels    : Vector<SBChannel>;
  public var record      : Int;
  public var samplesTick : Int;

  public var buffer      : Vector<Sample>;
  public var completed (default, setCompleted) : Int;
  public var remains     : Int;
  public var samplesLeft : Int;
  public var wave        : ByteArray;

  public var waveform (getWaveform, null) : ByteArray;

  public function new() 
  {
    //var i : Int;
    var len : Int;

    wave = new ByteArray();
    wave.endian = flash.utils.Endian.LITTLE_ENDIAN;//"littleEndian";

    len = BUFFER_SIZE;
    buffer = new Vector<Sample>(len, true);
    buffer[0] = new Sample();

    for (i in 1...len)
    {
      // what is int(i-1) ???
      //buffer[i] = buffer[Std.int(i - 1)].next = new Sample();

      buffer[i] = new Sample();
      buffer[i - 1].next = buffer[i];
    }

    record = 0;
  }

  private function setCompleted(value : Int) : Int
  {
    completed = value ^ player.loopSong;

    return completed;
  }

  public function getWaveform() : ByteArray 
  {
    var snd:ByteArray = new ByteArray();
    snd.endian = flash.utils.Endian.LITTLE_ENDIAN;//"littleEndian";

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

  public function setup(len : Int) : Void 
  {
    //var i : Int;
    channels = new Vector<SBChannel>(len, true);
    channels[0] = new SBChannel(0);

    // int(i - 1) ???
    for (i in 1...len)
    {
      //channels[i] = channels[Std.int(i - 1)].next = new SBChannel(i);
      channels[i] = new SBChannel(i);
      channels[i - 1].next = channels[i];
    }
  }

  public function initialize() : Void 
  {
    var chan : SBChannel = channels[0];
    var sample : Sample = buffer[0];
    wave.clear();
    completed   = 0;
    remains     = 0;
    samplesLeft = 0;

    while (chan != null) {
      chan.initialize();
      chan = chan.next;
    }

    while (sample != null) {
      sample.l = sample.r = 0.0;
      sample = sample.next;
    }
  }

  public function mix(e:SampleDataEvent) : Void 
  {
    var chan:SBChannel;
    //var d:Vector<Float>;
    var data:ByteArray = e.data;
    //var i : Int;
    //var j : Int;
    var len : Int = 0;
    var mixed : Int = 0;
    var mixLen : Int = 0;
    var mixPos : Int = 0;
    var s:SBSample;
    var sample:Sample;
    var size : Int = BUFFER_SIZE;
    var toMix : Int = 0;
    var value:Float = 0.0;

    if (completed != 0) {
      if (remains == 0) 
      {
        trace("nothing to do!");
        return;
      }
      size = remains;
    }

    //trace("remains: " + remains + ", completed: " + completed, ", channels: " + channels.length);
    //try
    //{
    len  = channels.length;

    while (mixed < size) 
    {
      if (samplesLeft == 0) 
      {
        player.process();
        samplesLeft = samplesTick;
        if (completed != 0) {
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

      //var chansProcessed : Int = 0;

      //for(chan in channels)
      //while(chan != null)
      for (i in 0...len) 
      {
        if (chan.sample == null || chan.sample.bytes == null) 
        {
          //trace("null sample or data");
          chan = chan.next;
          continue;
        }

        s = chan.sample;
        
        // original code: d = s.data;
        // now using haxe memory

        //trace(s.bytes.length + " " + s.bytes.position);

        flash.Memory.select(s.bytes);

        sample = buffer[mixPos];

        for (j in mixPos...mixLen) 
        {
          // apparently, chan.mute is neither initialized nor modified
          // original code: if (chan.mute == 0) value = d[Std.int(chan.pointer)];
          if (chan.mute == 0) value = flash.Memory.getFloat(Std.int(chan.pointer) << 2);

          chan.pointer += chan.speed;

          sample.l += value * chan.lvol;
          sample.r += value * chan.rvol;
          sample = sample.next;
          value = 0.0;

          if (chan.speed < 0) 
          {
            if (chan.pointer <= chan.counter) 
            {
              chan.pointer = s.loopStart + (chan.counter - chan.pointer);
              chan.counter = s.length;
              chan.speed = -chan.speed;
            }
          } 
          else 
          {
            if (chan.pointer >= chan.counter) 
            {
              if (s.loopMode == 1) 
              {
                chan.pointer = s.loopStart + (chan.pointer - chan.counter);
                chan.counter = s.length;
              } 
              else if (s.loopMode == 2) 
              {
                chan.pointer = s.length - (chan.pointer - chan.counter);
                if (chan.pointer == s.length) chan.pointer -= 0.00000000001;
                chan.counter = s.loopStart;
                chan.speed = -chan.speed;
              } 
              else 
              {
                chan.sample = null;
                break;
              }
            }
          }
        }

        chan = chan.next;
      }

      //trace("chansProcessed: " + chansProcessed);

      mixPos = mixLen;
      mixed += toMix;
      samplesLeft -= toMix;

      //trace(toMix);
    }

    sample = buffer[0];

    // if (record)
    if (record != 0) 
    {
      //trace(size);
      for (i in 0...size) 
      {
        if (sample.l > 1.0) sample.l = 1.0;
          else if (sample.l < -1.0) sample.l = -1.0;
        if (sample.r > 1.0) sample.r = 1.0;
          else if (sample.r < -1.0) sample.r = -1.0;

        wave.writeShort(65536 + Std.int(sample.l * 65536));
        wave.writeShort(65536 + Std.int(sample.r * 65536));

        data.writeFloat(sample.l);
        data.writeFloat(sample.r);
        sample.l = sample.r = 0.0;
        sample = sample.next;
      }
    } 
    else 
    {
      //trace(size);
            
      for (i in 0...size) 
      {
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
    /*
    }
    catch(e : Dynamic)
    {
      trace(e);
    }
    */
  }
}
