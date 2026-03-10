# Package

version       = "0.1.0"
author        = "Casey Tucker"
description   = "Character map for terminal"
license       = "MIT"
srcDir        = "src"
namedBin      = toTable {"main": "charmap"}


# Dependencies

requires "nim >= 2.2.0"
requires "unicodedb >= 0.13.2"
