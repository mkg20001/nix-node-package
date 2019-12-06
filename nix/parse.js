'use strict'

const path = require('path')
const fs = require('fs')

const src = fs.realpathSync(process.argv.pop())

const pjson = require(path.join(src, 'package.json'))
const yarnLock = String(fs.readFileSync(path.join(src, 'yarn.lock')))

// TODO: rewrite properly

const parsed = []
const resolved = {}
let current
let ID = 0

yarnLock.split('\n').map((line) => {
  if (line.startsWith('#') || !line.trim()) {
    // ignore
  } else if (line.startsWith('    ')) {
    let [name, ...val] = line.substr(4).split(' ')
    val = val.join(' ')
    current.dependencies[name] = JSON.parse(val)
  } else if (line.startsWith('  ')) {
    if (line.endsWith(':')) {
      current.dependencies = {}
    } else {
      let [name, ...val] = line.substr(2).split(' ')
      val = val.join(' ')
      current[name] = val.startsWith('"') ? JSON.parse(val) : val
    }
  } else {
    current = { _id: ID++ }

    const applicable = line.match(/^(.+):$/)[1].split(', ').map(l => l.startsWith('"') ? JSON.parse(l) : l)
    applicable.forEach(d => {
      resolved[d] = current
    })
    parsed.push(current)
  }
})

const out = {
  name: pjson.name,
  version: pjson.version,
  lockfileVersion: 1,
  requires: true,
  dependencies: resolveTreeRecursive(pjson, resolved)
}

function isNeedleInHayList (needle, hays) {
  return Boolean(hays.filter(hay => hay.indexOf(needle) !== -1).length)
}

function resolveDependenciesRecursive (deps, resolved, devflag = false, ...parents) {

}

function resolveTreeRecursive (pkg, resolved, devflag = false, ...parents) {
  const out = {
    version: pkg.version

  }

  for (const dep in pkg.dependencies) { // eslint-disable-line guard-for-in
    const d = pkg.dependencies[dep]

    const vers = d.split(' || ')

    const isInTree = Boolean(vers.map(ver => resolved[`dep@${ver}`]._id).filter(id => isNeedleInHayList(id, parents)))
  }

  return {

  }
}

console.log(resolved)
