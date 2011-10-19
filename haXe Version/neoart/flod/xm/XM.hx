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

// TODO: replace MOD_SINE and FT2_SINE with Memory
@final class XM 
{
  public static inline var FLAG_PERIOD      : Int = 1;
  public static inline var FLAG_VOLUME      : Int = 2;
  public static inline var FLAG_PANNING     : Int = 4;
  public static inline var FLAG_TRIGGER     : Int = 8;
  public static inline var FLAG_STOP        : Int = 16;

  public static inline var NOTE_KEYOFF      : Int = 97;

  public static inline var ENVELOPE_OFF     : Int = 0;
  public static inline var ENVELOPE_ON      : Int = 1;
  public static inline var ENVELOPE_SUSTAIN : Int = 2;
  public static inline var ENVELOPE_LOOP    : Int = 4;

  public static inline var FX_ARPEGGIO                     : Int = 0;
  public static inline var FX_PORTAMENTO_UP                : Int = 1;
  public static inline var FX_PORTAMENTO_DOWN              : Int = 2;
  public static inline var FX_TONE_PORTAMENTO              : Int = 3;
  public static inline var FX_VIBRATO                      : Int = 4;
  public static inline var FX_TONE_PORTAMENTO_VOLUME_SLIDE : Int = 5;
  public static inline var FX_VIBRATO_VOLUME_SLIDE         : Int = 6;
  public static inline var FX_TREMOLO                      : Int = 7;
  public static inline var FX_SET_PANNING                  : Int = 8;
  public static inline var FX_SAMPLE_OFFSET                : Int = 9;
  public static inline var FX_VOLUME_SLIDE                 : Int = 10;
  public static inline var FX_POSITION_JUMP                : Int = 11;
  public static inline var FX_SET_VOLUME                   : Int = 12;
  public static inline var FX_PATTERN_BREAK                : Int = 13;
  public static inline var FX_EXTENDED_EFFECTS             : Int = 14;
  public static inline var FX_SET_SPEED                    : Int = 15;
  public static inline var FX_SET_GLOBAL_VOLUME            : Int = 16;
  public static inline var FX_GLOBAL_VOLUME_SLIDE          : Int = 17;
  public static inline var FX_KEYOFF                       : Int = 20;
  public static inline var FX_SET_ENVELOPE_POSITION        : Int = 21;
  public static inline var FX_PANNING_SLIDE                : Int = 24;
  public static inline var FX_MULTI_RETRIG_NOTE            : Int = 27;
  public static inline var FX_TREMOR                       : Int = 29;
  public static inline var FX_EXTRA_FINE_PORTAMENTO        : Int = 31;

  public static inline var EX_FINE_PORTAMENTO_UP           : Int = 1;
  public static inline var EX_FINE_PORTAMENTO_DOWN         : Int = 2;
  public static inline var EX_GLISSANDO_CONTROL            : Int = 3;
  public static inline var EX_VIBRATO_CONTROL              : Int = 4;
  public static inline var EX_SET_FINETUNE                 : Int = 5;
  public static inline var EX_PATTERN_LOOP                 : Int = 6;
  public static inline var EX_TREMOLO_CONTROL              : Int = 7;
  public static inline var EX_RETRIG_NOTE                  : Int = 9;
  public static inline var EX_FINE_VOLUME_SLIDE_UP         : Int = 10;
  public static inline var EX_FINE_VOLUME_SLIDE_DOWN       : Int = 11;
  public static inline var EX_NOTE_CUT                     : Int = 12;
  public static inline var EX_NOTE_DELAY                   : Int = 13;
  public static inline var EX_PATTERN_DELAY                : Int = 14;

  public static inline var VX_VOLUME_SLIDE_DOWN            : Int = 6;
  public static inline var VX_VOLUME_SLIDE_UP              : Int = 7;
  public static inline var VX_FINE_VOLUME_SLIDE_DOWN       : Int = 8;
  public static inline var VX_FINE_VOLUME_SLIDE_UP         : Int = 9;
  public static inline var VX_SET_VIBRATO_SPEED            : Int = 10;
  public static inline var VX_VIBRATO                      : Int = 11;
  public static inline var VX_SET_PANNING                  : Int = 12;
  public static inline var VX_PANNING_SLIDE_LEFT           : Int = 13;
  public static inline var VX_PANNING_SLIDE_RIGHT          : Int = 14;
  public static inline var VX_TONE_PORTAMENTO              : Int = 15;

  public static var MOD_SINE : Vector<Int>;
  public static var FT2_SINE : Vector<Int>;

  public static var INIT_XM = 
  {
    MOD_SINE = Vector.ofArray([
       0,  24,  49,  74,  97, 120, 141, 161, 180, 197, 212, 224, 235, 244, 250, 253,
       255, 253, 250, 244, 235, 224, 212, 197, 180, 161, 141, 120,  97,  74,  49,  24]);

    FT2_SINE = Vector.ofArray([
        0, -2, -3, -5, -6, -8, -9,-11,-12,-14,-16,-17,-19,-20,-22,-23,
      -24,-26,-27,-29,-30,-32,-33,-34,-36,-37,-38,-39,-41,-42,-43,-44,
      -45,-46,-47,-48,-49,-50,-51,-52,-53,-54,-55,-56,-56,-57,-58,-59,
      -59,-60,-60,-61,-61,-62,-62,-62,-63,-63,-63,-64,-64,-64,-64,-64,
      -64,-64,-64,-64,-64,-64,-63,-63,-63,-62,-62,-62,-61,-61,-60,-60,
      -59,-59,-58,-57,-56,-56,-55,-54,-53,-52,-51,-50,-49,-48,-47,-46,
      -45,-44,-43,-42,-41,-39,-38,-37,-36,-34,-33,-32,-30,-29,-27,-26,
      -24,-23,-22,-20,-19,-17,-16,-14,-12,-11, -9, -8, -6, -5, -3, -2,
        0,  2,  3,  5,  6,  8,  9, 11, 12, 14, 16, 17, 19, 20, 22, 23,
       24, 26, 27, 29, 30, 32, 33, 34, 36, 37, 38, 39, 41, 42, 43, 44,
       45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 56, 57, 58, 59,
       59, 60, 60, 61, 61, 62, 62, 62, 63, 63, 63, 64, 64, 64, 64, 64,
       64, 64, 64, 64, 64, 64, 63, 63, 63, 62, 62, 62, 61, 61, 60, 60,
       59, 59, 58, 57, 56, 56, 55, 54, 53, 52, 51, 50, 49, 48, 47, 46,
       45, 44, 43, 42, 41, 39, 38, 37, 36, 34, 33, 32, 30, 29, 27, 26,
       24, 23, 22, 20, 19, 17, 16, 14, 12, 11,  9,  8,  6,  5,  3,  2]);
  }
}
