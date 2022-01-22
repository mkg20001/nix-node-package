import { readFileSync } from 'fs'

const file = process.argv.pop()

const contents = String(readFileSync(file))

const lines = contents.split('\n')
const end = lines.length

let cur = []
const root = cur
const stack = [cur]
let level = 0
const comment = []
let newLevel = null

function parseValueSingle (v) {
  if (v.startsWith('"')) {
    return { _quoted: true, _value: JSON.parse(v) }
  }

  return { _quoted: false, _value: v }
}

function parseValue (value) {
  return value.split(', ').map(parseValueSingle)
}

let i = 0

while (i < end) {
  const line = lines[i]
  i++
  if (!line.trim()) {
    newLevel = 0
  } else if (line.startsWith('#')) {
    comment.push(line)
    continue
  } else {
    let j = 0
    while (line[j] === ' ') j++
    newLevel = j / 2
  }
  if (Math.floor(newLevel) !== newLevel) {
    throw new SyntaxError('Indent must be power of 2')
  }
  if (level < newLevel) {
    throw new SyntaxError('Going inside object that is unknown')
  }
  if (level > newLevel) { // leaving
    while (newLevel < level) {
      cur = stack.pop()
      level--
    }
  }
  if (line.endsWith(':')) {
    const n = []
    // only do multiple keys at top
    cur.push({ key: (level ? parseValueSingle : parseValue)(line.substr(level * 2, line.length - 1 - level * 2)), value: n })
    stack.push(cur)
    cur = n
    level++
    continue
  } else if (line.trim()) {
    const target = line.indexOf(' ', level * 2)
    cur.push({ key: parseValueSingle(line.substr(level * 2, target - level * 2)), value: parseValueSingle(line.substr(target + 1)) })
  } else {
    cur.push({ empty: true })
  }
}

console.log(JSON.stringify({ comment, root }, null, 2))
