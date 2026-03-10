import strutils
import sequtils
import unicodedb/names_data

proc find_words(str: string): seq[int] =
  let needle = str.toUpperAscii().map(proc(x: char): int = x.ord())

  var i = 0
  var offset = 0
  while i < wordsData.len:
    if wordsData[i] == 0:
      inc i
      offset = i
      continue
    var found = true
    for j in 0..<needle.len:
      if wordsData[i + j] != needle[j]:
        found = false
        i += j + 1
        break
    if found:
      result.add wordsOffsets.find(offset)
      i += needle.len

proc find_runes*(str: string): seq[int] =
  let words = find_words(str)

  for n in 0..<namesTable.len.int32:
    if namesTable[n] in words:
      var ii: int32 = -1
      for i in 0..<namesIndices.len.int32:
        let ni = namesIndices[i]
        if ni == -1:
          continue
        if ni == n:
          break
        if ni > n:
          let blk = namesOffsets.find((ii div blockSize).uint8)
          result.add blk * blockSize + (ii mod blockSize)
          break
        ii = i
