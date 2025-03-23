import fs from 'node:fs'
import path from 'node:path'
import { exit } from 'node:process'

var file = process.argv[2]
if (!file) exit(1)
var content = fs.readFileSync(path.resolve(file), 'utf8')
console.dir(JSON.parse(content), { depth: null })
