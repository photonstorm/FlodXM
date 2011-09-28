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
  import flash.text.*;

  [Embed(source="/assets/Flod3.ttf", fontName="Flod", mimeType="application/x-font-truetype", embedAsCFF="false")]

  public final class Theme extends Font {
    public static const
      FONT_NAME      : String = "Flod",
      FONT_SIZE      : int = 8,

      LABEL_NORMAL   : int = 0x101420,
      LABEL_DISABLED : int = 0x73777d,
      BUTTON_LABEL   : int = 0x101420,
      TOGGLE_LABEL   : int = 0x101420,

      BUTTON_STATES  : Array = [
        [0xbec2c8, 0x5a5e64, 0x8c9096],     //rest
        [0xa5a9af, 0x73777d, 0x91959b],     //disabled
        [0xaabedc, 0x465a78, 0x788caa],     //hover
        [0x3c506e, 0x3c506e, 0x6e82a0],     //hover pressed
        [0x50545a, 0x50545a, 0x82868c]];    //pressed
  }
}