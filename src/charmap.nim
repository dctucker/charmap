# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.
import
  std/[
    strutils,
    unicode,
  ],
  unicodedb,
  unicodedb/blocks_data,
  ./[
    c1,
    search,
  ]

const PAGE_SIZE* = 256
const MAX_BASE* = 0xFFF00

type
  Charmap* = ref object
    base*: int
    row*: int
    col*: int
    runes*: seq[Rune]
    searching*: bool

func sym(rune: Rune): string =
  let i = rune.ord()
  case i
  of 0x00..0x1F:
    #"^" & chr('@'.int + i)
    " " & $Rune(0x2400 + i)
  of 0x7F:
    " " & $Rune(0x2421)
  of 0x80..0x9F:
    "\27[2m" & $Rune(0x241B) & chr('@'.int + i - 0x80) & "\27[0m"
  else:
    " " & $rune

func description(rune: Rune): string =
  let i = rune.ord
  case i
  of 0x00..0x1F:
    Rune(i + 0x2400).name().split(" ")[2..^1].join(" ")
  of 0x7F:
    Rune(0x2421).name().split(" ")[2..^1].join(" ")
  of 0x80..0x9F:
    c1_names[i - 0x80]
  else:
    rune.name()

func hex(v: int): string =
  if v < 0x10000:
    return v.toHex(4)
  else:
    return v.toHex(5)

proc cursorTo*(row, col: int) =
  stdout.write("\27[", $(row + 3), ";", $(2 + (1 + col) * 4), "f")

proc display_runes(cm: Charmap) =

  # clear screen and tabs
  stdout.write("\27[0m\27[2J\n\n")
  stdout.write("\27[3g")

  # set tabs and return home
  for x in 1..16:
    stdout.write("\27[", $(2 + x * 4), "G\27H")
  stdout.write("\27[H\27[34m", (cm.base shr 8).toHex(3), "\27[0m")

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
      let rune = cm.runes[x + 16 * y]
      stdout.write("\t", sym(rune))
    stdout.write("\n")

proc search*(cm: Charmap, needle: string) =
  let found = find_runes(needle)
  for i in 0..<PAGE_SIZE:
    cm.runes[i] = if i < found.len:
      Rune(found[i])
    else:
      Rune(-1)
  cm.searching = true

  #cursorTo(0, 0)
  #var n = 0
  #for i in 0..<16:
  #  stdout.write("\27[2K")
  #  for j in 0..<16:
  #    n = i * 16 + j
  #    if n >= found.len:
  #      break
  #    stdout.write(" ", Rune(found[n]), "\t")
  #  stdout.write("\n\t")

  #cursorTo(0, 0)

func rune*(cm: Charmap): Rune =
  return cm.runes[cm.row * 16 + cm.col]

proc describe(rune: Rune) =
  stdout.write("\27[K")
  if rune.ord < 0:
    return
  stdout.write(
    "\27[34;4m",
    "\\u", ord(rune).hex(), "\27[0m ",
    "\27[40;1m ",
    sym(rune),
    "  \27[0m ",
    rune.description(),
  )

proc blocks(cm: Charmap): seq[string] =
  let a = cm.base
  let b = cm.base + 255
  for i in 0..<blockRanges.len:
    let r = blockRanges[i]
    if a <= r.b and r.a <= b:
      result.add blockNames[i]

proc draw_blocks(cm: Charmap) =
  if cm.searching:
    return
  stdout.write("\27[34m")
  for (i, blk) in cm.blocks.pairs:
    if i mod 2 == 1:
      stdout.write(", ")
    stdout.write(blk)
    if i mod 2 == 1:
      stdout.write("\n\t")
  stdout.write("\27[0m")

proc draw*(cm: Charmap) =
  cursorTo(17, 0)
  cm.rune.describe()
  cursorTo(18, 0)
  cm.draw_blocks()
  cursorTo(cm.row, cm.col)

proc populate*(cm: Charmap) =
  cm.runes = @[]
  for i in cm.base..(cm.base+255):
    cm.runes.add Rune(i)
  cm.searching = false

proc redraw*(cm: Charmap) =
  stdout.write("\27[?25l")
  cm.display_runes()
  cursorTo(0,0)
  cm.draw()
  stdout.write("\27[?25h")

proc cleanup*() =
  stdout.write("\27[24;1f")
