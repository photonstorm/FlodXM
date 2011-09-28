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

  public class Control extends Sprite {
    public static const
      REST          : int = 0,
      DISABLED      : int = 1,
      HOVER         : int = 2,
      HOVER_PRESSED : int = 3,
      PRESSED       : int = 4;

    protected var
      m_enabled : Boolean = true,
      m_flags   : Invalidate,
      m_state   : int,
      m_width   : int,
      m_height  : int;

    public function Control(container:DisplayObjectContainer, x:Number, y:Number) {
      move(x, y);
      if (container) container.addChild(this);
      initialize();
      m_width  = super.width;
      m_height = super.height;
    }

    public function get enabled():Boolean { return m_enabled; }
    public function set enabled(value:Boolean):void {
      if (value == m_enabled) return;
      m_enabled = value;
      m_state = value ? REST : DISABLED;
      mouseEnabled = value;
      invalidate(Invalidate.STATE);
    }

    override public function get width():Number { return m_width; }
    override public function set width(value:Number):void {
      if (int(value) == m_width) return;
      resize(value, m_height);
    }

    override public function get height():Number { return m_height; }
    override public function set height(value:Number):void {
      if (int(value) == m_height) return;
      resize(m_width, value);
    }

    override public function set x(value:Number):void {
      move(value, super.y);
    }

    override public function set y(value:Number):void {
      move(super.x, value);
    }

    public function move(x:Number, y:Number):void {
      super.x = Math.round(x);
      super.y = Math.round(y);
    }

    public function offset(x:Number, y:Number):void {
      move(super.x + x, super.y + y);
    }

    public function resize(w:Number, h:Number):void {
      m_width  = Math.round(w);
      m_height = Math.round(h);
      invalidate(Invalidate.SIZE);
    }

    protected function initialize():void {
      tabEnabled = false;
      m_flags = new Invalidate();
    }

    protected function draw():void {
      m_flags.reset();
    }

    protected function invalidate(index:int = Invalidate.ALL):void {
      m_flags.invalidate(index);

      if (!m_flags.isInvalid(Invalidate.SET)) {
        addEventListener(Event.ENTER_FRAME, invalidateHandler);
        m_flags.invalidate(Invalidate.SET);
      }
    }

    protected function isInvalid(index:int, ...indexes:Array):Boolean {
      if (m_flags.isInvalid(index) || m_flags.isInvalid(Invalidate.ALL)) return true;
      while (indexes.length > 0) { if (m_flags.isInvalid(indexes.pop())) return true; }
      return false;
    }

    private function invalidateHandler(e:Event):void {
      m_flags.validate(Invalidate.SET);
      removeEventListener(Event.ENTER_FRAME, invalidateHandler);
      draw();
    }
  }
}