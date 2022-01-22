/* eslint-disable no-console */

import { readFileSync } from 'fs'

const file = process.argv.pop()

const contents = String(readFileSync(file))

const data = JSON.parse(contents)

const L = '  '

function stringValueSingle ({ _value, _quoted }) {
  if (_quoted) {
    return JSON.stringify(_value)
  }

  return _value
}

function stringValue (ar) {
  return ar.map(stringValueSingle).join(', ')
}

function iter (data, l = 0) {
  data.forEach(el => {
    if (el.empty) console.log()
    else if (Array.isArray(el.value)) {
      console.log(L.repeat(l) + stringValue(el.key) + ':')
      iter(el.value, l + 1)
    } else if (el.value) {
      console.log(L.repeat(l) + stringValueSingle(el.key) + ' ' + stringValueSingle(el.value))
    } else {
      throw new SyntaxError('Invalid branch without value or empty flag')
    }
  })
}

data.comment.forEach((v) => console.log(v))
iter(data.root)
