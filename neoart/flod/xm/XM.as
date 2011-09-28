/* FlodXM Alpha 3
   2011/09/17
   Christian Corti
   Neoart Costa Rica

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 	 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 	 LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
 	 IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

package neoart.flod.xm {

  public final class XM {
    public static const
      FLAG_PERIOD      : int = 1,
      FLAG_VOLUME      : int = 2,
      FLAG_PANNING     : int = 4,
      FLAG_TRIGGER     : int = 8,
      FLAG_STOP        : int = 16,

      NOTE_KEYOFF      : int = 97,

      ENVELOPE_OFF     : int = 0,
      ENVELOPE_ON      : int = 1,
      ENVELOPE_SUSTAIN : int = 2,
      ENVELOPE_LOOP    : int = 4,

      FX_ARPEGGIO                     : int = 0,
      FX_PORTAMENTO_UP                : int = 1,
      FX_PORTAMENTO_DOWN              : int = 2,
      FX_TONE_PORTAMENTO              : int = 3,
      FX_VIBRATO                      : int = 4,
      FX_TONE_PORTAMENTO_VOLUME_SLIDE : int = 5,
      FX_VIBRATO_VOLUME_SLIDE         : int = 6,
      FX_TREMOLO                      : int = 7,
      FX_SET_PANNING                  : int = 8,
      FX_SAMPLE_OFFSET                : int = 9,
      FX_VOLUME_SLIDE                 : int = 10,
      FX_POSITION_JUMP                : int = 11,
      FX_SET_VOLUME                   : int = 12,
      FX_PATTERN_BREAK                : int = 13,
      FX_EXTENDED_EFFECTS             : int = 14,
      FX_SET_SPEED                    : int = 15,
      FX_SET_GLOBAL_VOLUME            : int = 16,
      FX_GLOBAL_VOLUME_SLIDE          : int = 17,
      FX_KEYOFF                       : int = 20,
      FX_SET_ENVELOPE_POSITION        : int = 21,
      FX_PANNING_SLIDE                : int = 24,
      FX_MULTI_RETRIG_NOTE            : int = 27,
      FX_TREMOR                       : int = 29,
      FX_EXTRA_FINE_PORTAMENTO        : int = 31,

      EX_FINE_PORTAMENTO_UP           : int = 1,
      EX_FINE_PORTAMENTO_DOWN         : int = 2,
      EX_GLISSANDO_CONTROL            : int = 3,
      EX_VIBRATO_CONTROL              : int = 4,
      EX_SET_FINETUNE                 : int = 5,
      EX_PATTERN_LOOP                 : int = 6,
      EX_TREMOLO_CONTROL              : int = 7,
      EX_RETRIG_NOTE                  : int = 9,
      EX_FINE_VOLUME_SLIDE_UP         : int = 10,
      EX_FINE_VOLUME_SLIDE_DOWN       : int = 11,
      EX_NOTE_CUT                     : int = 12,
      EX_NOTE_DELAY                   : int = 13,
      EX_PATTERN_DELAY                : int = 14,

      VX_VOLUME_SLIDE_DOWN            : int = 6,
      VX_VOLUME_SLIDE_UP              : int = 7,
      VX_FINE_VOLUME_SLIDE_DOWN       : int = 8,
      VX_FINE_VOLUME_SLIDE_UP         : int = 9,
      VX_SET_VIBRATO_SPEED            : int = 10,
      VX_VIBRATO                      : int = 11,
      VX_SET_PANNING                  : int = 12,
      VX_PANNING_SLIDE_LEFT           : int = 13,
      VX_PANNING_SLIDE_RIGHT          : int = 14,
      VX_TONE_PORTAMENTO              : int = 15,

      MOD_SINE : Vector.<int> = Vector.<int>([
         0,  24,  49,  74,  97, 120, 141, 161, 180, 197, 212, 224, 235, 244, 250, 253,
       255, 253, 250, 244, 235, 224, 212, 197, 180, 161, 141, 120,  97,  74,  49,  24]),

      FT2_SINE : Vector.<int> = Vector.<int>([
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