# Vizkazar

A Lab piece for [tomrhodes.it](https://tomrhodes.it): Islamic star patterns
from the tiles of Seville, built as matte 3D solids and cut, lifted and
coloured live by music. The motion takes its cue from the 2019 RAI channel
idents (Rai 3 and Rai 4).

It plays `www/audio/amelie2.mp3` by default, or any audio file you choose, or
the microphone.

## The idea

A corridor, like the room in the RAI 4 ident: floor, ceiling and both
walls carry the same wall of Alcazar blocks, mirrored, so wherever you look
there is a lit solid surface. The walls slide towards the camera for ever.

- **The pattern** is drawn the way the originals can be: lay plain polygons
  edge to edge, then from the middle of every edge send two lines into the
  tile at one fixed angle (the *contact angle*). Where they cross, stars
  appear. See `src/pattern/StarCutter.hx`.
- **Large solid blocks**: every kite and every star wedge is a deep block,
  packed edge to edge out of a cream wall; the grooves between them are the
  strapwork. Each wall is exactly as wide as a line the pattern is mirrored
  along, preferring one that runs along a white gap (see
  `pattern/MirrorLines.hx`), so the pattern folds round each corner like
  paper: a block crossing the corner is cut down its own middle and is
  whole again once folded. Blocks near a corner are **corner blocks**, one
  block folded round it, with a 45° face across the inside of the fold that
  moves out along the diagonal as the block grows.
- **A 16-band graphic equaliser**: each block stands out of the wall as far
  as its band is loud. Round each star the wedges carry the low bands and
  the kites the high ones, mirrored left to right. Blocks further down the
  corridor show the sound from a moment ago, so the music runs away down
  the walls.
- **Kicks** squeeze the stars (the contact angle swings), push every block
  out, rush the walls on and make the camera lunge. **Snares** lighten the
  faces as a ring running down the corridor. **Notes** light the kite faces
  in their shade of the tiling's colour family; **the bassline** colours the
  star wedges and widens the grooves.
- **Complexity** steps through four tilings (4-, 6-, 8- and 12-fold) as the
  music swells and thins. **A doorway** takes you between them, without
  changing pace: a short way down the tunnel a door grows across it (its
  frame rises out of the walls, its blocks slide in like a camera iris
  closing), carrying a rosette of the next pattern in its own colours.
  Once it is shut, the next corridor is built behind it. You travel on to
  it, and when it fills the screen it opens again the same way. The fog
  shifts colour as you go through.

## Where things are

| Folder | What it does |
| --- | --- |
| `src/Settings.hx` | Every tunable number and colour, in one place |
| `src/pattern/` | The geometry: tilings, laying the floor, cutting stars |
| `src/sound/` | Listening: sources, the two spectrums, notes, bassline, kick and snare hits, the equaliser, the memory |
| `src/scene/` | The 3D world: stage, light and fog, the corridor, the wall of blocks, the doorway between tilings |
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

- Kites that meet at a corner belong to different tiles, so one visible shape
  can carry two or three shades. Decide whether to keep that faceted look.
- 10-fold patterns and wrapping the pattern onto a dome.
