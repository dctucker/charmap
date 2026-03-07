# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.
import strutils
import unicode
import unicodedb
import unicodedb/scripts

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
    $rune

when isMainModule:
  for i in 0..1024:
    let rune = Rune(i)
    echo "\\u", toHex(i, 4), "\t ", sym(rune), "\t", rune.name()

  #for i in 0..127:
  #  let rune = Rune(i*256+1)
  #  echo sym(rune), "\t", $(rune.name())
