from std/terminal import getch
import ./charmap

proc searchMode(cm: Charmap) =
  var needle = ""

  proc bs() =
    if needle.len > 0:
      needle = needle[0..^2]
      stdout.write("\27[D\27[K")

  proc confirm() =
    cm.search(needle)

  stdout.write("\27[2;1H\27[2K/")
  while true:
    let k = getch()
    case k
    of '\8', '\127': bs()
    of '\10', '\13':
      confirm()
      break
    of '\3', '\4':
      break
    of 'A'..'Z', 'a'..'z':
      needle &= k
      stdout.write(k)
    else:
      discard

  stdout.write("\r\27[2K")
  cm.redraw()
  cm.draw()

proc normalMode*(cm: Charmap) =
  proc up() =
    if cm.row > 0:
      cm.row -= 1
    elif cm.base > 0:
      cm.row = 15
      cm.base -= PAGE_SIZE
      cm.populate()
      cm.redraw()
      return
    cm.draw()

  proc down() =
    if cm.row < 15:
      cm.row += 1
    elif cm.base < MAX_BASE:
      cm.row = 0
      cm.base += PAGE_SIZE
      cm.populate()
      cm.redraw()
      return
    cm.draw()

  proc left() =
    if cm.col > 0:
      cm.col -= 1
    elif cm.row > 0:
      cm.col = 15
      cm.row -= 1
    elif cm.base > 0:
      cm.base -= PAGE_SIZE
      cm.col = 15
      cm.row = 15
      cm.populate()
      cm.redraw()
      return
    cm.draw()

  proc right() =
    if cm.col < 15:
      cm.col += 1
    elif cm.row < 15:
      cm.col = 0
      cm.row += 1
    elif cm.base < MAX_BASE:
      cm.base += PAGE_SIZE
      cm.col = 0
      cm.row = 0
      cm.populate()
      cm.redraw()
      return
    cm.draw()

  proc pageup() =
    if cm.base > 0:
      cm.base -= PAGE_SIZE
    cm.populate()
    cm.redraw()

  proc pagedown() =
    if cm.base < MAX_BASE:
      cm.base += PAGE_SIZE
    cm.populate()
    cm.redraw()

  proc confirm() =
    if not cm.searching:
      return
    let r = cm.rune.ord
    cm.base = r div PAGE_SIZE * PAGE_SIZE
    cm.row = (r mod PAGE_SIZE) div 16
    cm.col = r mod 16
    cm.populate()
    cm.redraw()


  while true:
    let k = getch()
    case k
    of '\27': # escape codes
      case getch()
      of '[':
        case getch()
        of 'A': up()
        of 'B': down()
        of 'C': right()
        of 'D': left()
        #of 'H': home()
        of '5':
          case getch()
          of '~': pageup()
          else: discard
        of '6':
          case getch()
          of '~': pagedown()
          else: discard
        else: discard
      of '\27': # double escape cancels
        break
      else: discard
    of '\3', '\4', 'q': # ^C or ^D or q cancels
      break
    of '\10', '\13': confirm()
    of '/': cm.searchMode()
    else:
      discard

  cleanup()

proc main() =
  let cm = Charmap()
  cm.populate()
  cm.redraw()
  cm.normalMode()

when isMainModule:
  main()
