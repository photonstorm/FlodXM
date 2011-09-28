/* Flectrum version 1.1
   2009/08/31
   Christian Corti
   Neoart Costa Rica

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 	 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 	 LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
 	 IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

package neoart.flectrum {
  import flash.events.*;
  import flash.media.*;
  import flash.utils.*;

  public class SoundEx extends Sound {
    public static const SOUND_START:String = "soundStart";
    public static const SOUND_STOP: String = "soundStop";

    public static const SPECTRUM_LEFT:  String = "left";
    public static const SPECTRUM_RIGHT: String = "right";
    public static const SPECTRUM_BOTH:  String = "both";
    public static const SPECTRUM_DOUBLE:String = "double";

    public static const METHOD_ADD:   String = "add";
    public static const METHOD_SAMPLE:String = "sample";

    public var soundChannel:SoundChannel;
    public var fourier:Boolean;
    public var stretchFactor:int;
    public var spectrum:String;

    protected var values:ByteArray;
    protected var vector:Vector.<Number>;

    public function SoundEx(fourier:Boolean = false, stretchFactor:int = 2) {
      this.fourier = fourier;
      this.stretchFactor = stretchFactor;
      values = new ByteArray();
      vector = new Vector.<Number>();
      super();
    }

    override public function play(startTime:Number = 0, loops:int = 0, sndTransform:SoundTransform = null):SoundChannel {
      soundChannel = super.play(startTime, loops, sndTransform);
      soundChannel.addEventListener(Event.SOUND_COMPLETE, completeHandler);
      dispatchEvent(new Event(SOUND_START));
      return soundChannel;
    }

    public function stop():void {
      if (!soundChannel) return;
      soundChannel.stop();
      dispatchEvent(new Event(SOUND_STOP));
      soundChannel = null;
    }

    public function addMono(columns:int):Vector.<Number> {
      var i:int, j:int, l:int, o:Number = 256 / columns, p:Number = 0, s:Number, t:Number;
      SoundMixer.computeSpectrum(values, fourier, stretchFactor);

      switch (spectrum) {
        case SPECTRUM_BOTH:   o *= 2;
          break;
        case SPECTRUM_DOUBLE: columns <<= 1;
          break;
        case SPECTRUM_RIGHT:  values.position = 1024;
          break;
      }
      vector.length = columns;

      for (i = 0; i < columns; ++i) {
        t = 0;
        l = (((Math.ceil(p += o) >> 2) << 4) - values.position) >> 2;
        for (j = 0; j < l; ++j) {
          if ((s = values.readFloat()) < 0) s = -s;
          t += s;
        }
        t /= l;
        vector[i] = t * (2 - t);
      }
      return vector;
    }

    public function addStereo(columns:int):Vector.<Number> {
      var c:int, i:int, j:int, l:int, o:Number = 256 / columns, p:Number = 0, s:Number, t:Number;
      SoundMixer.computeSpectrum(values, fourier, stretchFactor);
      vector.length = columns;

      for (i = 0; i < columns; ++i) {
        t = 0;
        l = (((Math.ceil(p += o) >> 2) << 4) - values.position) >> 2;

        for (j = 0; j < l; ++j) {
          if ((s = values.readFloat()) < 0) s = -s;
          t += s;
          values.position = 1024 + c;
          if ((s = values.readFloat()) < 0) s = -s;
          t += s;
          values.position = (c += 4);
        }
        t /= (l << 1);
        vector[i] = t * (2 - t);
      }
      return vector;
    }

    public function sampleMono(columns:int):Vector.<Number> {
      var i:int, o:Number = 256 / columns, p:Number = 0, s:Number;
      SoundMixer.computeSpectrum(values, fourier, stretchFactor);

      switch (spectrum) {
        case SPECTRUM_BOTH:   o *= 2;
          break;
        case SPECTRUM_DOUBLE: columns <<= 1;
          break;
        case SPECTRUM_RIGHT:  values.position = p = 1024;
          break;
      }
      vector.length;

      for (i = 0; i < columns; ++i) {
        if ((s = values.readFloat()) < 0) s = -s;
        vector[i] = s * (2 - s);
        values.position = Math.ceil(p += o) << 2;
      }
      return vector;
    }

    public function sampleStereo(columns:int):Vector.<Number> {
      var i:int, o:Number = 256 / columns, p:Number = 0, s:Number, t:Number;
      SoundMixer.computeSpectrum(values, fourier, stretchFactor);
      vector.length = columns;

      for (i = 0; i < columns; ++i) {
        if ((s = values.readFloat()) < 0) s = -s;
        t = s;
        values.position = 1024 + (Math.ceil(p) << 2);
        if ((s = values.readFloat()) < 0) s = -s;
        t += s;
        values.position = Math.ceil(p += o) << 2;
        t *= 0.5;
        vector[i] = t * (2 - t);
      }
      return vector;
    }

    protected function completeHandler(e:Event):void {
      soundChannel.removeEventListener(Event.SOUND_COMPLETE, completeHandler);
      dispatchEvent(e);
      soundChannel = null;
    }

    public function get stereoPeak():Number {
      if (!soundChannel) return 0;
      return (soundChannel.leftPeak + soundChannel.rightPeak) * 0.5;
    }
  }
}