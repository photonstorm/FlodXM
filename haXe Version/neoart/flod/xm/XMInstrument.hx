/* FlodXM Alpha 3
   2011/09/17
   Christian Corti
   Neoart Costa Rica

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 	 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 	 LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
 	 IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

package neoart.flod.xm;

import flash.Vector;

@final class XMInstrument 
{
  public var name         : String;
  public var samples      : Vector<XMSample>;
  public var noteSamples  : Vector<Int>;
  public var fadeout      : Int;
  public var hasVolume    : Int;
  public var volData      : XMData;
  public var hasPanning   : Int;
  public var panData      : XMData;
  public var vibratoType  : Int;
  public var vibratoSweep : Int;
  public var vibratoSpeed : Int;
  public var vibratoDepth : Int;

  public function new() 
  {
    name        = "";
    noteSamples = new Vector<Int>(96, true);
    volData     = new XMData();
    panData     = new XMData();
  }
}
