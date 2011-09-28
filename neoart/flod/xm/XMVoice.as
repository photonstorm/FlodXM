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
  import neoart.flod.core.*;

  public final class XMVoice {
    internal var
      index            : int,
      next             : XMVoice,
      channel          : SBChannel,
      flags            : int,
      note             : int,
      target           : int,
      period           : int,
      frequency        : int,
      frqDelta         : int,
      delay            : int,
      keyoff           : int,
      instrument       : XMInstrument,
      autoVibratoPos   : int,
      autoSweepPos     : int,
      sample           : XMSample,
      finetune         : int,
      sampleOffset     : int,
      patternLoopRow   : int,
      patternLoopCnt   : int,
      fadeout          : int,
      isFading         : int,
      volume           : int,
      volSlide         : int,
      volSlideMaster   : int,
      fineVolSlideUp   : int,
      fineVolSlideDown : int,
      volEnvelope      : XMEnvelope,
      panning          : int,
      panSlide         : int,
      panEnvelope      : XMEnvelope,
      arpeggioOn       : int,
      portaDown        : int,
      portaUp          : int,
      finePortaUp      : int,
      finePortaDown    : int,
      xtraPortaUp      : int,
      xtraPortaDown    : int,
      portaPeriod      : int,
      portaSpeed       : int,
      vibratoOn        : int,
      vibratoPos       : int,
      vibratoSpeed     : int,
      vibratoDepth     : int,
      tremoloPos       : int,
      tremoloSpeed     : int,
      tremoloDepth     : int,
      waveControl      : int,
      tremorPos        : int,
      tremorOn         : int,
      tremorOff        : int,
      tremorVol        : int,
      retrigX          : int,
      retrigY          : int,
      volTemp          : int;

    public function XMVoice(index:int) {
      this.index = index;
      volEnvelope = new XMEnvelope();
      panEnvelope = new XMEnvelope();
    }

    internal function reset():void {
      volume   = sample.volume;
      volTemp = volume;
      panning  = sample.panning;
      finetune = sample.finetune;
      keyoff   = 0;
      fadeout  = 65536;
      isFading = 0;

      volEnvelope.reset(64);
      panEnvelope.reset(32);

      autoVibratoPos = 0;
      autoSweepPos   = 0;
      tremorPos      = 0;

      if ((waveControl & 15) < 4) vibratoPos = 0;
      if ((waveControl >> 4) < 4) tremoloPos = 0;

      flags |= (XM.FLAG_VOLUME | XM.FLAG_PANNING);
    }

    internal function autoVibrato():void {
      var delta:int;

      if (++autoSweepPos > instrument.vibratoSweep)
        autoSweepPos = instrument.vibratoSweep;

      autoVibratoPos = (autoVibratoPos + instrument.vibratoSpeed) & 255;

      switch (instrument.vibratoType) {
        case 0:
          delta = XM.FT2_SINE[autoVibratoPos];
          break;
        case 1:
          if (autoVibratoPos < 128) delta = -64;
            else delta = 64;
          break;
        case 2:
          delta = ((64 + (autoVibratoPos >> 1)) & 127) - 64;
          break;
        case 3:
          delta = ((64 - (autoVibratoPos >> 1)) & 127) - 64;
          break;
      }

      delta *= instrument.vibratoDepth;
      if (instrument.vibratoSweep)
        delta = delta * (autoSweepPos / instrument.vibratoSweep);

      frqDelta = (delta >> 6);
      flags |= XM.FLAG_PERIOD;
    }

    internal function tonePortamento():void {
      if (period < portaPeriod) {
        period += portaSpeed << 2;
        if (period > portaPeriod) period = portaPeriod;
      } else if (period > portaPeriod) {
        period -= portaSpeed << 2;
        if (period < portaPeriod) period = portaPeriod;
      }

      frequency = period;
      flags |= XM.FLAG_PERIOD;
    }

    internal function tremolo():void {
      var delta:int, position:int = tremoloPos & 31, value:int;

      switch ((waveControl >> 4) & 3) {
        case 0:
          delta = XM.MOD_SINE[position];
          break;
        case 1:
          delta = position << 3;
          break;
        case 2:
          delta = 255;
          break;
      }

      value = (delta * tremoloDepth) >> 6;

      if (tremoloPos > 31) volume = volTemp - value;
        else volume = volTemp + value;

      tremoloPos = (tremoloPos + tremoloSpeed) & 63;
      flags |= XM.FLAG_VOLUME;
    }

    internal function vibrato():void {
      var delta:int, position:int = vibratoPos & 31, value:int;

      switch (waveControl & 3) {
        case 0:
          delta = XM.MOD_SINE[position];
          break;
        case 1:
          delta = position << 3;
          if (vibratoPos > 31) delta = 255 - delta;
          break;
        default:
          delta = 255;
          break;
      }

      value = (delta * vibratoDepth) >> 7;

      if (vibratoPos > 31) frequency = period - value;
        else frequency = period + value;

      vibratoPos = (vibratoPos + vibratoSpeed) & 63;
      flags |= XM.FLAG_PERIOD;
    }

    internal function tremor():void {
      if (tremorPos >= tremorOn) {
        tremorVol = volume;
        volume = 0;
        flags |= XM.FLAG_VOLUME;
      }

      if (++tremorPos >= tremorOff) {
        tremorPos = 0;
        volume = tremorVol;
        flags |= XM.FLAG_VOLUME;
      }
    }
  }
}