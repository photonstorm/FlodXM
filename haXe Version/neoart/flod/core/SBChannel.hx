/* FlodXM Alpha 3
   2011/09/17
   Christian Corti
   Neoart Costa Rica

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 	 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 	 LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
 	 IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

package neoart.flod.core;

class SBChannel 
{  
  public var index   : Int;
  public var next    : SBChannel;
  public var mute    : Int;
  public var volume  : Float;
  public var lvol    : Float;
  public var rvol    : Float;
  public var panning : Float;
  public var sample  : SBSample;
  public var pointer : Float;
  public var counter : Int;
  public var speed   : Float;

  public function new (index : Int) 
  {
    this.index = index;

    //initialize();
  }

  public function initialize() : Void
  {
    volume   = 0.0;
    lvol     = 0.0;
    rvol     = 0.0;
    panning  = 0.0;
    sample   = null;
    pointer  = 0.0;
    counter  = 0;
    speed    = 0.0;

    // it's not initialized anywhere in the code
    mute     = 0;
  }
}
