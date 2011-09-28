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

  public final class ToggleButton extends Button {
    private var
      m_default  : String,
      m_selected : String,
      m_pressed  : Boolean;

    public function ToggleButton(container:DisplayObjectContainer = null, x:Number = 0.0, y:Number = 0.0, caption:String = "", selected:String = "", w:Number = 27.0, h:Number = 19.0) {
      m_default  = caption;
      m_selected = selected == "" ? caption : selected;
      super(container, x, y, caption, w, h);
    }

    override public function set enabled(value:Boolean):void {
      super.enabled = value;
      if (value) {
        m_state = m_pressed ? Control.PRESSED : Control.REST;
        invalidate(Invalidate.STATE);
      }
    }

    override public function get caption():String { return m_default; }
    override public function set caption(value:String):void {
      super.caption = m_default = value;
    }

    public function get pressed():Boolean { return m_pressed; }
    public function set pressed(value:Boolean):void {
      if (value == m_pressed) return;
      m_pressed = value;
      m_state = value ? Control.PRESSED : Control.REST;
      invalidate(Invalidate.STATE);
    }

    public function get pressedCaption():String { return m_selected; }
    public function set pressedCaption(value:String):void {
      m_selected = value;
      if (m_pressed) super.caption = value;
    }

    override protected function draw():void {
      super.draw();
      if (!m_enabled) return;

      if (m_pressed) {
        m_caption.color = Theme.TOGGLE_LABEL;
        m_caption.text  = m_selected;
      } else {
        m_caption.color = Theme.BUTTON_LABEL;
        m_caption.text  = m_default;
      }

      center();
    }

    override protected function mouseDownHandler(e:MouseEvent):void {
      m_pressed = Boolean(!m_pressed);
      super.mouseDownHandler(e);
    }

    override protected function mouseUpHandler(e:MouseEvent):void {
      stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUpHandler);
      m_state = m_pressed ? Control.PRESSED : Control.REST;
      invalidate(Invalidate.STATE);
    }

    override protected function rollHandler(e:MouseEvent):void {
      if (!m_pressed) super.rollHandler(e);
    }
  }
}