/* FlodXM Alpha 3
   2011/09/17
   Christian Corti
   Neoart Costa Rica

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 	 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 	 LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
 	 IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

package neoart.flod.xm;
import flash.utils.ByteArray;
import neoart.flod.core.Soundblaster;
import neoart.flod.core.SBPlayer;
import flash.Vector;

@final class XMLoader 
{

  public static function load(stream:ByteArray, mixer:Soundblaster) : Void 
  {
    var header : Int;
    //var i : Int;
    var iheader : Int;
    var instrument:XMInstrument;
    var ipos : Int;
    //var j : Int;
    var len : Int;
    var pattern:XMPattern;
    var player:XMPlayer;
    var pos : Int;
    var row:XMRow;
    var rows : Int;
    var sample:XMSample;
    var value : Int;

    // not necessary, but to make things clearer
    stream.endian = flash.utils.Endian.LITTLE_ENDIAN;

    if (stream.length < 336) return;
    stream.position = 17;

    player = cast(mixer.player, XMPlayer);
    player.title = stream.readMultiByte(20, SBPlayer.ENCODING);

    trace(player.title);

    stream.position += 21;
    player.version = stream.readUnsignedShort();

    header = stream.readUnsignedInt();
    player.length = stream.readUnsignedShort();
    player.restart = stream.readUnsignedShort();
    player.channels = stream.readUnsignedShort();

    trace("channels: " + player.channels);
    trace("length: " + player.length);

    player.patterns = new Vector<XMPattern>(stream.readUnsignedShort(), true);
    player.instruments = new Vector<XMInstrument>(stream.readUnsignedShort() + 1, true);

    player.amiga = stream.readUnsignedShort();
    player.speed = stream.readUnsignedShort();
    player.tempo = stream.readUnsignedShort();

    trace("speed: " + player.speed);

    len = player.length;
    player.track = new Vector<Int>(len, true);

    for (i in 0...len)
      player.track[i] = stream.readUnsignedByte();

    stream.position = header + 60;
    len = player.patterns.length;
    pos = stream.position;

    trace("patterns: " + player.patterns.length);

    for (i in 0...len) 
    {
      header = stream.readUnsignedInt();
      stream.position++;

      pattern = new XMPattern();
      pattern.length = stream.readUnsignedShort();
      pattern.size = rows = pattern.length * player.channels;
      pattern.rows = new Vector<XMRow>(rows, true);

      value = stream.readUnsignedShort();
      stream.position = pos + header;
      ipos = stream.position + value;

      if (value > 0) {
        for (j in 0...rows) 
        {
          row = new XMRow();
          value = stream.readUnsignedByte();

          if ((value & 128) != 0) 
          {
            if ((value &  1) != 0) row.note       = stream.readUnsignedByte();
            if ((value &  2) != 0) row.instrument = stream.readUnsignedByte();
            if ((value &  4) != 0) row.volume     = stream.readUnsignedByte();
            if ((value &  8) != 0) row.effect     = stream.readUnsignedByte();
            if ((value & 16) != 0) row.param      = stream.readUnsignedByte();
          } 
          else 
          {
            row.note       = value;
            row.instrument = stream.readUnsignedByte();
            row.volume     = stream.readUnsignedByte();
            row.effect     = stream.readUnsignedByte();
            row.param      = stream.readUnsignedByte();
          }

          if (row.note != 97) if (row.note > 95) row.note = 0;

          // TODO: comparison of Int and UInt might lead to unexpected results
          // this should be an warning, not an error
          if (row.instrument > Std.int(player.instruments.length)) row.instrument = 0;
          pattern.rows[j] = row;
        }
      } else {
        for (j in 0...rows) pattern.rows[j] = new XMRow();
      }

      player.patterns[i] = pattern;
      pos = stream.position;
      if (pos != ipos) pos = stream.position = ipos;
    }

    len = player.instruments.length;
    ipos = stream.position;

    for (i in 1...len) 
    {
      iheader = stream.readUnsignedInt();
      // TODO: comparison of Int and UInt
      if ((stream.position + iheader) >= Std.int(stream.length)) 
      {
        trace("stream read break: " + i);
        break;
      }

      instrument = new XMInstrument();
      instrument.name = stream.readMultiByte(22, SBPlayer.ENCODING);
      //trace(instrument.name);
      stream.position++;

      value = stream.readUnsignedShort();
      if (value > 16) value = 16;
      header = stream.readUnsignedInt();

      if (value > 0) {
        instrument.samples = new Vector<XMSample>(value, true);

        for (j in 0...96)
          instrument.noteSamples[j] = stream.readUnsignedByte();
        for (j in 0...12)
          instrument.volData.points[j] = new XMPoint(stream.readUnsignedShort(), stream.readUnsignedShort());
        for (j in 0...12)
          instrument.panData.points[j] = new XMPoint(stream.readUnsignedShort(), stream.readUnsignedShort());

        instrument.volData.total     = stream.readUnsignedByte();
        instrument.panData.total     = stream.readUnsignedByte();
        instrument.volData.sustain   = stream.readUnsignedByte();
        instrument.volData.loopStart = stream.readUnsignedByte();
        instrument.volData.loopEnd   = stream.readUnsignedByte();
        instrument.panData.sustain   = stream.readUnsignedByte();
        instrument.panData.loopStart = stream.readUnsignedByte();
        instrument.panData.loopEnd   = stream.readUnsignedByte();
        instrument.volData.flags     = stream.readUnsignedByte();
        instrument.panData.flags     = stream.readUnsignedByte();

        if ((instrument.volData.flags & XM.ENVELOPE_ON) != 0) instrument.hasVolume  = 1;
        if ((instrument.panData.flags & XM.ENVELOPE_ON) != 0) instrument.hasPanning = 1;

        instrument.vibratoType  = stream.readUnsignedByte();
        instrument.vibratoSweep = stream.readUnsignedByte();
        instrument.vibratoDepth = stream.readUnsignedByte();
        instrument.vibratoSpeed = stream.readUnsignedByte();
        instrument.fadeout      = stream.readUnsignedShort();

        stream.position += 22;
        pos = stream.position;
        player.instruments[i] = instrument;

        for (j in 0...value) {
          sample = new XMSample();
          sample.length    = stream.readUnsignedInt();
          sample.loopStart = stream.readUnsignedInt();
          sample.loopLen   = stream.readUnsignedInt();
          sample.volume    = stream.readUnsignedByte();
          //trace("sample.volume: " + sample.volume);
          sample.finetune  = stream.readByte();
          sample.loopMode  = stream.readUnsignedByte();
          sample.panning   = stream.readUnsignedByte();
          sample.relative  = stream.readByte();

          stream.position++;
          sample.name = stream.readMultiByte(22, SBPlayer.ENCODING);
          instrument.samples[j] = sample;

          stream.position = pos + header;
          pos = stream.position;
        }

        for (j in 0...value) {
          sample = instrument.samples[j];
          if (sample.length == 0) continue;
          pos = stream.position + sample.length;

          if ((sample.loopMode & 16) != 0) 
          {
            sample.bits       = 16;
            sample.loopMode  ^= 16;
            sample.length    >>= 1;
            sample.loopStart >>= 1;
            sample.loopLen   >>= 1;
          }

          if (sample.loopLen == 0) sample.loopMode = 0;
          sample.store(stream);
          if (sample.loopMode != 0) sample.length = sample.loopStart + sample.loopLen;
          stream.position = pos;
        }
      } else {
        stream.position = ipos + iheader;
      }
      ipos = stream.position;
      // TODO: comparison of Int and UInt
      if (ipos == Std.int(stream.length)) break;
    }

    // TODO: what is this?
    instrument = new XMInstrument();
    instrument.name = "FlodXM";
    instrument.volData = new XMData();
    instrument.panData = new XMData();
    instrument.samples = new Vector<XMSample>(1, true);

    for (i in 0...12) {
      instrument.volData.points[i] = new XMPoint();
      instrument.panData.points[i] = new XMPoint();
    }

    sample = new XMSample();
    sample.length = 220;
    //sample.data = new Vector<Float>(220, true);
    //for (i in 0...220) sample.data[i] = 0.0;
    sample.fill(220, 0.0);

    instrument.samples[0] = sample;
    player.instruments[0] = instrument;

    len = player.instruments.length;
  }
}
