/* Flexi 1.0
   2010/05/12
   Christian Corti
   Neoart Costa Rica

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 	 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 	 LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
 	 IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

package neoart.flexi {
  import flash.display.*;
  import flash.events.*;
  import flash.utils.*;

  public class Button extends Control {
    protected var
      m_autoRepeat : Boolean,
      m_caption    : Label,
      m_timer      : Timer,
      m_x          : int,
      m_y          : int;

    public function Button(container:DisplayObjectContainer = null, x:Number = 0.0, y:Number = 0.0, caption:String = "", w:Number = 72.0, h:Number = 19.0) {
      super(container, x, y);
      m_caption.text = caption;
      enabled = false;
      resize(w, h);
    }

    public function get autoRepeat():Boolean { return m_autoRepeat; }
    public function set autoRepeat(value:Boolean):void {
      if (value == m_autoRepeat) return;
      m_autoRepeat = value;

      if (value) {
        m_timer = new Timer(240, 1);
        m_timer.addEventListener(TimerEvent.TIMER, timerHandler);
      } else if (m_timer) {
        m_timer.removeEventListener(TimerEvent.TIMER, timerHandler);
        m_timer = null;
      }
    }

    public function get caption():String { return m_caption.text; }
    public function set caption(value:String):void {
      m_caption.text = value;
      center();
    }

    override public function set enabled(value:Boolean):void {
      super.enabled = m_caption.enabled = value;
    }

    public function disableHover():Function {
      removeEventListener(MouseEvent.ROLL_OVER, rollHandler);
      removeEventListener(MouseEvent.ROLL_OUT, rollHandler);
      return rollHandler;
    }

    override public function resize(w:Number, h:Number):void {
      super.resize(w, h);
      center();
    }

    override protected function initialize():void {
      super.initialize();
      m_caption = new Label(this);
      m_caption.color = Theme.BUTTON_LABEL;

      addEventListener(MouseEvent.ROLL_OVER, rollHandler);
      addEventListener(MouseEvent.ROLL_OUT, rollHandler);
      addEventListener(MouseEvent.MOUSE_DOWN, mouseDownHandler);
    }

    protected function center():void {
      m_x = m_caption.x = (m_width - m_caption.width) >> 1;
      m_y = m_caption.y = ((m_height - m_caption.height) >> 1) + 1;
    }

    override protected function draw():void {
      var g:Graphics = graphics, h:int = m_height, w:int = m_width;

      if (isInvalid(Invalidate.SIZE, Invalidate.STATE)) {
        g.clear();
        g.beginFill(Theme.BUTTON_STATES[m_state][0]);

        if (m_state >= Control.HOVER_PRESSED) {
          graphics.drawRect(0, 0, w, h);
        } else {
          g.drawRect(0, 0, w - 1, 1);
          g.drawRect(0, 1, 1, h - 2);
          g.beginFill(Theme.BUTTON_STATES[m_state][1]);
          g.drawRect(1, h - 1, w - 1, 1);
          g.drawRect(w - 1, 1, 1, h - 2);
        }

        g.beginFill(Theme.BUTTON_STATES[m_state][2]);
        g.drawRect(1, 1, w - 2, h - 2);
        g.endFill();

        if (m_state == Control.HOVER_PRESSED) m_caption.offset(1, 1);
          else m_caption.move(m_x, m_y);
      }

      super.draw();
    }

    protected function mouseDownHandler(e:MouseEvent):void {
      stage.addEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
      m_state = Control.HOVER_PRESSED;
      invalidate(Invalidate.STATE);
      if (m_autoRepeat) m_timer.start();
    }

    protected function mouseUpHandler(e:MouseEvent):void {
      stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
      if (m_autoRepeat) endPress();
      m_state = e.target == this ? Control.HOVER : Control.REST;
      invalidate(Invalidate.STATE);
    }

    protected function rollHandler(e:MouseEvent):void {
      if (m_autoRepeat) endPress();
      if (m_enabled) {
        m_state = e.type == MouseEvent.ROLL_OUT ? Control.REST : Control.HOVER;
        invalidate(Invalidate.STATE);
      }
    }

    private function timerHandler(e:TimerEvent):void {
      dispatchEvent(new MouseEvent(MouseEvent.CLICK));
      m_timer.reset();
      m_timer.delay = 80;
      m_timer.start();
    }

    private function endPress():void {
      m_timer.reset();
      m_timer.delay = 240;
    }
  }
}