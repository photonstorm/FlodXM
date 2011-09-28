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
  import flash.geom.*;

  public class Inward extends Visualizer {
    private var rows:int;

    public function Inward() {
      super();
    }

    override internal function override():void {
      flectrum.spectrum = SoundEx.SPECTRUM_DOUBLE;
      flectrum.stereo = false;
    }

    override internal function meterUpdate(spectrum:Vector.<Number>):void {
      var h:int, i:int, r:int = flectrum.m_columns, s:Number;
      sourceRect.x = 0;
      buffer.fillRect(buffer.rect, 0xff000000);

      for (i = 0; i < flectrum.m_columns; ++i) {
        s = spectrum[i];
        if (s > levels[i]) levels[i] = s;
        h = Math.ceil(levels[i] * rows) * sectionHeight;
        sourceRect.y = h;
        sourceRect.height = m_height - h;

        s = spectrum[r];
        if (s > levels[r]) levels[r] = s;
        h = Math.ceil(levels[r] * rows) * sectionHeight;
        sourceRect.height += m_height - h;
        buffer.fillRect(sourceRect, 0);

        sourceRect.x += sectionWidth;
        levels[i] -= flectrum.m_decay;
        levels[r] -= flectrum.m_decay;
        ++r;
      }
      bitmapData.copyPixels(input, input.rect, destPoint, buffer);
    }

    override internal function peaksUpdate(spectrum:Vector.<Number>):void {
      var h1:int, h2:int, i:int, r:int = flectrum.m_columns, s1:Number, s2:Number;
      sourceRect.x = 0;
      buffer.fillRect(buffer.rect, 0xff000000);

      for (i = 0; i < flectrum.m_columns; ++i) {
        s1 = spectrum[i];
        if (s1 > meters[i]) meters[i] = s1;
        h1 = Math.ceil(meters[i] * rows) * sectionHeight;
        sourceRect.y = h1;
        sourceRect.height = m_height - h1;

        s2 = spectrum[r];
        if (s2 > meters[r]) meters[r] = s2;
        h2 = Math.ceil(meters[r] * rows) * sectionHeight;
        sourceRect.height += m_height - h2;
        buffer.fillRect(sourceRect, 0);

        if (s1 > levels[i]) {
          levels[i] = s1;
        } else {
          h1 = Math.ceil(levels[i] * rows) * sectionHeight;
          sourceRect.y = h1;
        }
        sourceRect.y -= sectionHeight;
        sourceRect.height = flectrum.m_rowSize;
        buffer.fillRect(sourceRect, flectrum.m_peaksAlpha);

        if (s2 > levels[r]) {
          levels[r] = s2;
        } else {
          h2 = Math.ceil(levels[r] * rows) * sectionHeight;
          sourceRect.y = (m_height << 1) - h2;
        }
        buffer.fillRect(sourceRect, flectrum.m_peaksAlpha);

        sourceRect.x += sectionWidth;
        meters[i] -= flectrum.m_decay;
        levels[i] -= flectrum.m_peaksDecay;
        meters[r] -= flectrum.m_decay;
        levels[r] -= flectrum.m_peaksDecay;
        ++r;
      }
      bitmapData.copyPixels(input, input.rect, destPoint, buffer);
    }

    override internal function trailUpdate(spectrum:Vector.<Number>):void {
      var h:int, i:int, r:int = flectrum.m_columns;
      sourceRect.x = 0;
      buffer.fillRect(buffer.rect, flectrum.m_trailAlpha);
      bitmapData.copyPixels(bitmapData, bitmapData.rect, destPoint, buffer);
      buffer.fillRect(buffer.rect, 0xff000000);

      for (i = 0; i < flectrum.m_columns; ++i) {
        h = Math.ceil(spectrum[i] * rows) * sectionHeight;
        sourceRect.y = h;
        sourceRect.height = m_height - h;
        h = Math.ceil(spectrum[r] * rows) * sectionHeight;
        sourceRect.height += m_height - h;
        buffer.fillRect(sourceRect, 0);
        sourceRect.x += sectionWidth;
        ++r;
      }
      bitmapData.copyPixels(input, input.rect, destPoint, buffer, null, true);
    }

    override protected function clone():void {
      var i:int, v:Vector.<uint>;
      buffer = new BitmapData(m_width - flectrum.m_colSpacing, (m_height - flectrum.m_rowSpacing) << 1, true, 0);
      buffer.lock();

      v = scale(true, true);
      destPoint.x = 0;
      destPoint.y = m_height - flectrum.m_rowSpacing;

      sourceRect.x = 0;
      sourceRect.y = 0;
      sourceRect.width = flectrum.meter.width;
      sourceRect.height = flectrum.meter.height;

      for (i = 0; i < flectrum.m_columns; ++i) {
        buffer.setVector(sourceRect, v);
        sourceRect.x += sectionWidth;
        buffer.copyPixels(flectrum.meter, flectrum.meter.rect, destPoint);
        destPoint.x += sectionWidth;
      }
      levels = new Vector.<Number>(flectrum.m_columns << 1, true);
      meters = new Vector.<Number>(flectrum.m_columns << 1, true);
      m_height <<= 1;
      finalizeClone();
      m_height >>= 1;
      rows = flectrum.m_rows >> 1;
    }

    override protected function draw():void {
      var c:int = flectrum.m_columns << 1, h:int, s:Shape = new Shape(), g:Graphics = s.graphics, m:Matrix = new Matrix();

      if ((flectrum.m_rows & 1) != 0) {
        flectrum.m_rows--;
        m_height -= sectionHeight;
      }
      h = m_height >> 1;
      rows = flectrum.m_rows >> 1;

      m.createGradientBox(m_width, h, Math.PI * 1.5, 0, 0);
      g.beginGradientFill("linear", flectrum.m_colors[0], flectrum.m_alphas[0], flectrum.m_ratios[0], m);
      g.drawRect(0, 0, m_width, h);

      m.createGradientBox(m_width, h, Math.PI * 0.5, 0, h);
      g.beginGradientFill("linear", flectrum.m_colors[1], flectrum.m_alphas[1], flectrum.m_ratios[1], m);
      g.drawRect(0, h, m_width, h);

      levels = new Vector.<Number>(c, true);
      meters = new Vector.<Number>(c, true);
      finalizeDraw(s);
      m_height = h;
    }
  }
}