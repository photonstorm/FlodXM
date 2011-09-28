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
  import flash.text.*;

  public class Label extends Control {
    protected var
      m_autoSize : Boolean = true,
      m_color    : int,
      m_field    : TextField,
      m_format   : TextFormat,
      m_metrics  : TextLineMetrics;

    public function Label(container:DisplayObjectContainer = null, x:Number = 0.0, y:Number = 0.0, text:String = "") {
      super(container, x, y);
      this.text = text;
    }

    public function get align():String { return m_format.align; }
    public function set align(value:String):void {
      if (value == m_format.align) return;
      m_format.align = value;
      m_field.setTextFormat(m_format);
      m_field.width  = m_width;
      m_field.height = m_height;

      switch (m_format.align) {
        case "center":
          m_field.scrollH = m_field.maxScrollH >> 1;
          break;
        case "right":
          m_field.scrollH = m_field.maxScrollH;
          break;
        default:
          m_field.scrollH = 0;
          break;
      }
    }

    public function get autoSize():Boolean { return m_autoSize; }
    public function set autoSize(value:Boolean):void {
      if (value == m_autoSize) return;
      m_autoSize = value;

      if (value) {
        m_field.autoSize = "left";
        resize(m_field.width, m_field.height);
      } else {
        m_field.autoSize = "none";
      }
    }

    public function get color():int { return m_color; }
    public function set color(value:int):void {
      m_format.color = m_color = value;
      m_field.setTextFormat(m_format);
    }

    override public function set enabled(value:Boolean):void {
      super.enabled = value;
      mouseEnabled = false;
      m_format.color = value ? m_color : Theme.LABEL_DISABLED;
      m_field.setTextFormat(m_format);
    }

    public function get font():String { return m_format.font; }
    public function set font(name:String):void {
      m_format.font = name;
      m_field.setTextFormat(m_format);
      resize(m_field.width, m_field.height);
    }

    public function get fontSize():int { return int(m_format.size); }
    public function set fontSize(value:int):void {
      m_format.size = value;
      m_field.setTextFormat(m_format);
      resize(m_field.width, m_field.height);
    }

    public function get letterSpacing():int { return int(m_format.letterSpacing); }
    public function set letterSpacing(value:int):void {
      m_format.letterSpacing = value;
      m_field.setTextFormat(m_format);
      resize(m_field.width, m_field.height);
    }

    public function get text():String { return m_field.text; }
    public function set text(value:String):void {
      m_field.text = value;
      m_field.setTextFormat(m_format);
      resize(m_field.width, m_field.height);
    }

    public function get textWidth():int {
      return m_metrics.width;
    }

    public function get textHeight():int {
      return m_metrics.height;
    }

    override public function resize(w:Number, h:Number):void {
      m_metrics = m_field.getLineMetrics(0);
      super.resize(w, h);
    }

    override protected function initialize():void {
      super.initialize();
      mouseEnabled = false;

      m_format = new TextFormat();
      m_format.color = m_color = Theme.LABEL_NORMAL;
      m_format.font  = Theme.FONT_NAME;
      m_format.size  = Theme.FONT_SIZE;

      m_field = new TextField();
      m_field.antiAliasType     = "normal";
      m_field.autoSize          = "left";
      m_field.defaultTextFormat = m_format;
      m_field.embedFonts        = true;
      m_field.gridFitType       = "pixel";
      m_field.mouseEnabled      = false;
      m_field.selectable        = false;
      m_field.text              = "Label";
      m_field.wordWrap          = false;

      addChild(m_field);
      resize(m_field.width, m_field.height);
    }
  }
}