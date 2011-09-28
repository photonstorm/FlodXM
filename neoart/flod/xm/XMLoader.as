/* FlodXM Alpha 3
   2011/09/17
   Christian Corti
   Neoart Costa Rica

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 	 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 	 LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
 	 IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

package neoart.flod.xm {
  import flash.utils.*;
  import neoart.flod.core.*;

  public final class XMLoader {

    public static function load(stream:ByteArray, mixer:Soundblaster):void {
      var header:int, i:int, iheader:int, instrument:XMInstrument, ipos:int, j:int, len:int, pattern:XMPattern, player:XMPlayer, pos:int, row:XMRow, rows:int, sample:XMSample, value:int;
      if (stream.length < 336) return;
      stream.position = 17;

      player = XMPlayer(mixer.player);
      player.title = stream.readMultiByte(20, SBPlayer.ENCODING);
      stream.position += 21;
      player.version = stream.readUnsignedShort();

      header = stream.readUnsignedInt();
      player.length = stream.readUnsignedShort();
      player.restart = stream.readUnsignedShort();
      player.channels = stream.readUnsignedShort();

      player.patterns = new Vector.<XMPattern>(stream.readUnsignedShort(), true);
      player.instruments = new Vector.<XMInstrument>(stream.readUnsignedShort() + 1, true);

      player.amiga = stream.readUnsignedShort();
      player.speed = stream.readUnsignedShort();
      player.tempo = stream.readUnsignedShort();

      len = player.length;
      player.track = new Vector.<int>(len, true);

      for (i = 0; i < len; ++i)
        player.track[i] = stream.readUnsignedByte();

      stream.position = header + 60;
      len = player.patterns.length;
      pos = stream.position;

      for (i = 0; i < len; ++i) {
        header = stream.readUnsignedInt();
        stream.position++;

        pattern = new XMPattern();
        pattern.length = stream.readUnsignedShort();
        pattern.size = rows = pattern.length * player.channels;
        pattern.rows = new Vector.<XMRow>(rows, true);

        value = stream.readUnsignedShort();
        stream.position = pos + header;
        ipos = stream.position + value;

        if (value > 0) {
          for (j = 0; j < rows; ++j) {
            row = new XMRow();
            value = stream.readUnsignedByte();

            if (value & 128) {
              if (value &  1) row.note       = stream.readUnsignedByte();
              if (value &  2) row.instrument = stream.readUnsignedByte();
              if (value &  4) row.volume     = stream.readUnsignedByte();
              if (value &  8) row.effect     = stream.readUnsignedByte();
              if (value & 16) row.param      = stream.readUnsignedByte();
            } else {
              row.note       = value;
              row.instrument = stream.readUnsignedByte();
              row.volume     = stream.readUnsignedByte();
              row.effect     = stream.readUnsignedByte();
              row.param      = stream.readUnsignedByte();
            }

            if (row.note != 97) if (row.note > 95) row.note = 0;
            if (row.instrument > player.instruments.length) row.instrument = 0;
            pattern.rows[j] = row;
          }
        } else {
          for (j = 0; j < rows; ++j) pattern.rows[j] = new XMRow();
        }

        player.patterns[i] = pattern;
        pos = stream.position;
        if (pos != ipos) pos = stream.position = ipos;
      }

      len = player.instruments.length;
      ipos = stream.position;

      for (i = 1; i < len; ++i) {
        iheader = stream.readUnsignedInt();
        if ((stream.position + iheader) >= stream.length) break;

        instrument = new XMInstrument();
        instrument.name = stream.readMultiByte(22, SBPlayer.ENCODING);
        stream.position++;

        value = stream.readUnsignedShort();
        if (value > 16) value = 16;
        header = stream.readUnsignedInt();

        if (value > 0) {
          instrument.samples = new Vector.<XMSample>(value, true);

          for (j = 0; j < 96; ++j)
            instrument.noteSamples[j] = stream.readUnsignedByte();
          for (j = 0; j < 12; ++j)
            instrument.volData.points[j] = new XMPoint(stream.readUnsignedShort(), stream.readUnsignedShort());
          for (j = 0; j < 12; ++j)
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

          if (instrument.volData.flags & XM.ENVELOPE_ON) instrument.hasVolume  = 1;
          if (instrument.panData.flags & XM.ENVELOPE_ON) instrument.hasPanning = 1;

          instrument.vibratoType  = stream.readUnsignedByte();
          instrument.vibratoSweep = stream.readUnsignedByte();
          instrument.vibratoDepth = stream.readUnsignedByte();
          instrument.vibratoSpeed = stream.readUnsignedByte();
          instrument.fadeout      = stream.readUnsignedShort();

          stream.position += 22;
          pos = stream.position;
          player.instruments[i] = instrument;

          for (j = 0; j < value; ++j) {
            sample = new XMSample();
            sample.length    = stream.readUnsignedInt();
            sample.loopStart = stream.readUnsignedInt();
            sample.loopLen   = stream.readUnsignedInt();
            sample.volume    = stream.readUnsignedByte();
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

          for (j = 0; j < value; ++j) {
            sample = instrument.samples[j];
            if (!sample.length) continue;
            pos = stream.position + sample.length;

            if (sample.loopMode & 16) {
              sample.bits       = 16;
              sample.loopMode  ^= 16;
              sample.length    >>= 1;
              sample.loopStart >>= 1;
              sample.loopLen   >>= 1;
            }

            if (!sample.loopLen) sample.loopMode = 0;
            sample.store(stream);
            if (sample.loopMode) sample.length = sample.loopStart + sample.loopLen;
            stream.position = pos;
          }
        } else {
          stream.position = ipos + iheader;
        }
        ipos = stream.position;
        if (ipos == stream.length) break;
      }

      instrument = new XMInstrument();
      instrument.name = "FlodXM";
      instrument.volData = new XMData();
      instrument.panData = new XMData();
      instrument.samples = new Vector.<XMSample>(1, true);

      for (i = 0; i < 12; ++i) {
        instrument.volData.points[i] = new XMPoint();
        instrument.panData.points[i] = new XMPoint();
      }

      sample = new XMSample();
      sample.length = 220;
      sample.data = new Vector.<Number>(220, true);
      for (i = 0; i < 220; ++i) sample.data[i] = 0.0;

      instrument.samples[0] = sample;
      player.instruments[0] = instrument;
      len = player.instruments.length;
    }
  }
}