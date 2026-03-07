# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.
from std/terminal import getch
import strutils
import unicode
import unicodedb
import unicodedb/scripts
import unicodedb/blocks_data

type
  Charmap = ref object
    base: int
    row: int
    col: int

func sym(rune: Rune): string =
  let i = rune.ord()
  case i
  of 0x00..0x1f:
    "^" & chr('@'.int + i)
  of 0x7f:
    "^?"
  of 0x80..0x9f:
    "^" & chr('`'.int + i - 0x80)
  else:
    " " & $rune

func hex(v: int): string =
  if v < 0x10000:
    return v.toHex(4)
  else:
    return v.toHex(5)

proc cursorTo(row, col: int) =
  stdout.write("\27[", $(row + 3), ";", $(2 + (1 + col) * 4), "f")

proc display_range(r: HSlice) =
  # clear screen and tabs
  stdout.write("\27[0m\27[2J\n\n")
  stdout.write("\27[3g")

  # set tabs and return home
  for x in 1..16:
    stdout.write("\27[", $(2 + x * 4), "G\27H")
  stdout.write("\27[H")

  # column headers
  stdout.write("\27[34m")
  for x in 0..15:
    stdout.write("\t ", x.toHex(1))
  stdout.write("\n\n")

  for y in 0..15:
    # row labels
    stdout.write("\27[34m", y.toHex(1), "x", "\27[0m")

    # row of runes
    for x in 0..15:
      let rune = Rune(x + 16 * y);
      stdout.write("\t", sym(rune))
    stdout.write("\n")

func rune(cm: Charmap): Rune =
  return Rune(cm.base + cm.row * 16 + cm.col)

proc describe(rune: Rune) =
  stdout.write(
    "\27[34m",
    "\\u", ord(rune).hex(), "\27[0m ",
    "\27[40;1m ",
    sym(rune),
    "  \27[0m ",
    rune.name(),
    "\27[K",
  )

proc draw(cm: Charmap) =
  cursorTo(17, 0)
  cm.rune.describe()
  cursorTo(cm.row, cm.col)

proc up(cm: Charmap) =
  if cm.row > 0:
    cm.row -= 1
  cm.draw()

proc down(cm: Charmap) =
  if cm.row < 15:
    cm.row += 1
  cm.draw()

proc left(cm: Charmap) =
  if cm.col > 0:
    cm.col -= 1
  cm.draw()

proc right(cm: Charmap) =
  if cm.col < 15:
    cm.col += 1
  cm.draw()

proc getUserInput*(cm: Charmap): string =
  var first = true
  while true:
    let k = getch()
    case k
    of '\10', '\13': # CR or LF confirms
      result = " "
      break
    of '\3', '\4', 'q': # ^C or ^D or q cancels
      result = ""
      break
    of '\27': # escape codes
      case getch()
      of '[':
        case getch()
        of 'A': cm.up()
        of 'B': cm.down()
        of 'C': cm.right()
        of 'D': cm.left()
        #of 'H': cm.home()
        else: discard
      of '\27': # double escape cancels
        result = ""
        break
      else: discard
    else:
      discard
    first = false
  stdout.write("\27[24;1f")


when isMainModule:
  #for i in 0..1024:
  #  let rune = Rune(i)
  #  echo "\\u", toHex(i, 4), "\t ", sym(rune), "\t", rune.name()

  #for i in 0..<blockNames.len:
  #  let r = blockRanges[i]
  #  echo r.a.hex, "-", r.b.hex, "\t", blockNames[i]

  let cm = Charmap()
  displayRange(0..255)
  cursorTo(0,0)
  cm.draw()
  discard cm.getUserInput()
