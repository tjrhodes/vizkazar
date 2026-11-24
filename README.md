# Vizkazar

A Lab piece for [tomrhodes.it](https://tomrhodes.it): Islamic star patterns
from the tiles of Seville, built as solid blocks and raised, coloured and
turned over live by music. The look takes its cue from the RAI channel
idents by ELOISA, above all Rai 2: flat colour, no light, solids drawn with
three tones.

It plays `www/audio/amelie2.mp3` by default, or any audio file you choose, or
the microphone.

This is the `spinning-blocks` branch. The earlier 3D corridor (the "EQ
room") is parked on `main`, tagged `eq-tunnel`.

## The idea

A field of columns seen from above and a little in front, like the
diamond columns of the Rai 2 ident.

- **The pattern** is drawn the way the originals can be: lay plain polygons
  edge to edge, then from the middle of every edge send two lines into the
  tile at one fixed angle (the *contact angle*). Where they cross, stars
  appear. See `src/pattern/StarCutter.hx`.
- **Columns, drawn flat**: every kite and every star wedge is a column
  standing out of the ground; the grooves between them are the strapwork.
  There is no light and no perspective. Each face takes one of three flat
  tones by the way it points: tops in a clean colour, sides facing left in
  a darker tone, sides facing right darker still (see
  `src/scene/MeshWriter.hx`). Each tiling keeps to one colour family plus
  white, the way each RAI channel has its own colour.
- **A 16-band graphic equaliser**: each column stands as tall as its band
  is loud. Round each star the wedges carry the low bands and the kites the
  high ones, mirrored left to right. Columns further from the middle show
  the sound from a moment ago, so the music ripples outwards.
- **Kicks** squeeze the stars (the contact angle swings), raise every
  column and move the camera in. **Snares** whiten the wedges' tops as a
  ring rippling outwards. **Notes** colour the kites' white tops in their
  shade of the tiling's family; **the bassline** colours the star wedges
  and widens the grooves.
- **Complexity** steps through four tilings (4-, 6-, 8- and 12-fold) as the
  music swells and thins. **A wave of turning blocks** takes you between
  them: it runs out from the middle, and as it reaches each block the block
  turns over like a card, the old pattern on its front and the new one on
  its back. The scale and the ground's colour move to the new tiling's as
  the wave goes (see `src/scene/TurnWave.hx`).

## Where things are

| Folder | What it does |
| --- | --- |
| `src/Settings.hx` | Every tunable number and colour, in one place |
| `src/pattern/` | The geometry: tilings, laying the floor, cutting stars |
| `src/sound/` | Listening: sources, the two spectrums, notes, bassline, kick and snare hits, the equaliser, the memory |
| `src/scene/` | The 3D world: the flat-drawn stage, the field of columns, the wave between tilings, writing the blocks |
| `src/three/` | Haxe descriptions of the parts of three.js used (r128, loaded by the page) |
| `src/picture/` | The palette and colour families |
| `src/Conductor.hx` | Turns what is heard into tiling and contact angle |
| `src/Main.hx` | The frame loop that joins them up |

## Running it

Needs [Haxe 4.3](https://haxe.org/download/).

```sh
haxe build.hxml                       # builds www/visualiser.js
python3 -m http.server -d www 8000    # then open http://localhost:8000
```

## Not done yet

- Rai 2's zoom from the whole pattern into a single rosette and back, as
  another way between tilings.
- Blocks spinning on the beat, not only between tilings.
- 10-fold patterns.
