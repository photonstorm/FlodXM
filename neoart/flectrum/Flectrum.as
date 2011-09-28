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
  import flash.display.*;
  import flash.events.*;
  import flash.utils.*;

  public class Flectrum extends Sprite {
    public static const DIRECTION_UP:   String = "up";
    public static const DIRECTION_DOWN: String = "down";
    public static const DIRECTION_LEFT: String = "left";
    public static const DIRECTION_RIGHT:String = "right";

    public static const MODE_METER:String = "meter";
    public static const MODE_PEAKS:String = "peaks";
    public static const MODE_TRAIL:String = "trail";

    public var backgroundBeat:Boolean;

    protected var background:Bitmap;
    protected var scheduled:Boolean;
    protected var timer:Timer;

    protected var m_soundEx:SoundEx;
    protected var m_visualizer:Visualizer;
    protected var m_direction:String = DIRECTION_UP;
    protected var m_method:String = SoundEx.METHOD_SAMPLE;
    protected var m_showBackground:Boolean = true;
    protected var m_backgroundAlpha:Number = 0.2;

    internal var meter:BitmapData;

    internal var m_mode:String = MODE_PEAKS;
    internal var m_stereo:Boolean = true;
    internal var m_spectrum:String = SoundEx.SPECTRUM_BOTH;
    internal var m_decay:Number = 0.2;
    internal var m_columns:int;
    internal var m_colSize:int = 10;
    internal var m_colSpacing:int = 1;
    internal var m_rows:int;
    internal var m_rowSize:int = 3;
    internal var m_rowSpacing:int = 1;
    internal var m_peaksDecay:Number = 0.02;
    internal var m_peaksAlpha:uint = 0xff000000;
    internal var m_trailAlpha:uint = 0xd2000000;

    internal var m_colors:Vector.<Array> = Vector.<Array>([
      [0xff3939, 0xffb320, 0xfff820, 0x50d020], [0xff3939, 0xffb320, 0xfff820, 0x50d020]]);
    internal var m_alphas:Vector.<Array> = Vector.<Array>([
      [1, 1, 1, 1], [1, 1, 1, 1]]);
    internal var m_ratios:Vector.<Array> = Vector.<Array>([
      [10, 60, 110, 250], [10, 60, 110, 250]]);

    private var compute:Function;
    private var handler:Function;

    public function Flectrum(soundEx:SoundEx, columns:int = 32, rows:int = 25) {
      this.soundEx = soundEx;
      m_columns = columns;
      m_rows = rows;
      initialize();
    }

    public function setBitmap(image:BitmapData):void {
      meter = image.clone();
      m_visualizer.reset();
    }

    public function setDraw():void {
      if (meter) {
        meter.dispose();
        meter = null;
      }
      m_visualizer.reset();
    }

    protected function initialize():void {
      mouseEnabled = false;
      tabEnabled = false;
      background = new Bitmap(null, "always", true);

      if (m_columns < 2) m_columns = 2;
        else if (m_columns > 256) m_columns = 256;
      if (m_rows < 6) m_rows = 6;
        else if (m_rows > 512) m_rows = 512;

      timer = new Timer(50);
      timer.addEventListener(TimerEvent.TIMER, timerHandler);
      visualizer = new Visualizer();
    }

    protected function reset():void {
      timer.reset();
      while (numChildren) removeChildAt(0);
      m_visualizer.reset();

      background.rotation = 0;
      background.x = 0;
      background.y = 0;

      if (m_showBackground) {
        background.bitmapData = m_visualizer.input;
        background.alpha = m_backgroundAlpha;
        addChild(background);
      }
      addChild(m_visualizer);
      direction = m_direction;
    }

    protected function startHandler(e:Event):void {
      m_soundEx.removeEventListener(SoundEx.SOUND_START, startHandler);
      m_soundEx.addEventListener(SoundEx.SOUND_STOP, stopHandler);
      m_soundEx.addEventListener(Event.SOUND_COMPLETE, stopHandler);
      m_visualizer.override();

      compute = m_stereo ? m_soundEx[m_method +"Stereo"] : m_soundEx[m_method +"Mono"];
      handler = m_visualizer[m_mode +"Update"];

      timer.repeatCount = 0;
      timer.removeEventListener(TimerEvent.TIMER_COMPLETE, completeHandler);
      timer.start();
    }

    protected function stopHandler(e:Event):void {
      m_soundEx.removeEventListener(SoundEx.SOUND_STOP, stopHandler);
      m_soundEx.removeEventListener(Event.SOUND_COMPLETE, stopHandler);
      m_soundEx.addEventListener(SoundEx.SOUND_START, startHandler);

      timer.reset();
      timer.repeatCount = 50;
      timer.addEventListener(TimerEvent.TIMER_COMPLETE, completeHandler);
      timer.start();
    }

    protected function completeHandler(e:Event):void {
      timer.reset();
      timer.removeEventListener(TimerEvent.TIMER_COMPLETE, completeHandler);
      background.alpha = m_backgroundAlpha;
      dispatchEvent(new Event("soundStop"));
    }

    protected function timerHandler(e:TimerEvent):void {
      m_soundEx.spectrum = m_spectrum;
      handler(compute(m_columns));
      if (backgroundBeat) background.alpha = m_soundEx.stereoPeak;
      e.updateAfterEvent();
    }

    protected function invalidate():void {
      if (timer.running || scheduled) return;
      scheduled = true;
      addEventListener(Event.ENTER_FRAME, invalidateHandler);
    }

    protected function invalidateHandler(e:Event):void {
      scheduled = false;
      removeEventListener(Event.ENTER_FRAME, invalidateHandler);
      reset();
    }

    public function setGradient(index:int, colors:Array, alphas:Array, ratios:Array):Boolean {
      if (colors.length != alphas.length ||
          colors.length != ratios.length ||
          alphas.length != ratios.length ||
          index < 0 || index > 1) return false;

      m_colors[index] = colors;
      m_alphas[index] = alphas;
      m_ratios[index] = ratios;
      return true;
    }

    public function get soundEx():SoundEx { return m_soundEx; }
    public function set soundEx(val:SoundEx):void {
      if (val == null) return;
      if (m_soundEx) {
        if (timer.running) {
          timer.reset();
          m_soundEx.removeEventListener(SoundEx.SOUND_STOP, stopHandler);
          m_soundEx.removeEventListener(Event.SOUND_COMPLETE, stopHandler);
        } else {
          m_soundEx.removeEventListener(SoundEx.SOUND_START, startHandler);
        }
      }
      m_soundEx = val;
      m_soundEx.addEventListener(SoundEx.SOUND_START, startHandler);
    }

    public function get visualizer():Visualizer { return m_visualizer; }
    public function set visualizer(val:Visualizer):void {
      if (val == null) return;
      if (timer.running) completeHandler(new TimerEvent(TimerEvent.TIMER_COMPLETE));
      m_visualizer = val;
      m_visualizer.initialize(this);
      invalidate();
    }

    public function get delay():int { return timer.delay; }
    public function set delay(val:int):void {
      timer.delay = val;
    }

    public function get direction():String { return m_direction; }
    public function set direction(val:String):void {
      if (!Flectrum["DIRECTION_"+ val.toUpperCase()]) return;
      switch (val) {
        case DIRECTION_UP:
          m_visualizer.rotation = 0;
          m_visualizer.x = 0;
          m_visualizer.y = 0;
          break;
        case DIRECTION_DOWN:
          m_visualizer.rotation = 180;
          m_visualizer.x = m_visualizer.width;
          m_visualizer.y = m_visualizer.height;
          break;
        case DIRECTION_LEFT:
          m_visualizer.rotation = 270;
          m_visualizer.x = 0;
          m_visualizer.y = m_visualizer.height;
          break;
        case DIRECTION_RIGHT:
          m_visualizer.rotation = 90;
          m_visualizer.x = m_visualizer.width;
          m_visualizer.y = 0;
          break;
      }
      background.rotation = m_visualizer.rotation;
      background.x = m_visualizer.x;
      background.y = m_visualizer.y;
      m_direction = val;
    }

    public function get showBackground():Boolean { return m_showBackground; }
    public function set showBackground(val:Boolean):void {
      if (val == m_showBackground) return;
      m_showBackground = val;
      if (m_showBackground) addChildAt(background, 0);
        else removeChild(background);
    }

    public function get backgroundAlpha():Number { return m_backgroundAlpha; }
    public function set backgroundAlpha(val:Number):void {
      background.alpha = m_backgroundAlpha = val;
    }

    public function get method():String { return m_method; }
    public function set method(val:String):void {
      if (timer.running || !SoundEx["METHOD_"+ val.toUpperCase()]) return;
      m_method = val;
    }

    public function get mode():String { return m_mode; }
    public function set mode(val:String):void {
      if (timer.running) trace("Timer is running...");
      if (timer.running || !Flectrum["MODE_"+ val.toUpperCase()]) return;
      m_mode = val;
    }

    public function get stereo():Boolean { return m_stereo; }
    public function set stereo(val:Boolean):void {
      if (timer.running || val == m_stereo) return;
      m_stereo = val;
    }

    public function get spectrum():String { return m_spectrum; }
    public function set spectrum(val:String):void {
      if (timer.running || !SoundEx["SPECTRUM_"+ val.toUpperCase()]) return;
      m_spectrum = val;
    }

    public function get decay():Number { return m_decay; }
    public function set decay(val:Number):void {
      if (val < 0.1) val = 0.1;
        else if (val > 1) val = 1;
      m_decay = val;
    }

    public function get columns():int { return m_columns; }
    public function set columns(val:int):void {
      if (val == m_columns) return;
      if (val < 2) val = 2;
        else if (val > 256) val = 256;
      m_columns = val;
      invalidate();
    }

    public function get columnSize():int { return m_colSize; }
    public function set columnSize(val:int):void {
      if (val == m_colSize) return;
      if (val < 1) val = 1;
      m_colSize = val;
      invalidate();
    }

    public function get columnSpacing():int { return m_colSpacing; }
    public function set columnSpacing(val:int):void {
      if (val == m_colSpacing) return;
      if (val < -m_colSize) val = 0;
      m_colSpacing = val;
      invalidate();
    }

    public function get rows():int { return m_rows; }
    public function set rows(val:int):void {
      if (val == m_rows) return;
      if (val < 6) val = 6;
        else if (val > 512) val = 512;
      m_rows = val;
      invalidate();
    }

    public function get rowSize():int { return m_rowSize; }
    public function set rowSize(val:int):void {
      if (val == m_rowSize) return;
      if (val < 1) val = 1;
      m_rowSize = val;
      invalidate();
    }

    public function get rowSpacing():int { return m_rowSpacing; }
    public function set rowSpacing(val:int):void {
      if (val == m_rowSpacing) return;
      if (val < -m_rowSize) val = 0;
      m_rowSpacing = val;
      invalidate();
    }

    public function get peaksDecay():Number { return m_peaksDecay; }
    public function set peaksDecay(val:Number):void {
      if (val < 0.01) val = 0.01;
        else if (val > 1) val = 1;
      m_peaksDecay = val;
    }

    public function get peaksAlpha():Number { return m_peaksAlpha / 255; }
    public function set peaksAlpha(val:Number):void {
      if (val < 0) val = 0;
        else if (val > 1) val = 1;
      m_peaksAlpha = int(val * 255) << 24;
    }

    public function get trailAlpha():Number { return m_trailAlpha / 255; }
    public function set trailAlpha(val:Number):void {
      if (val < 0) val = 0;
        else if (val > 1) val = 1;
      m_trailAlpha = int(val * 255) << 24;
    }
  }
}