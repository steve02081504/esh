import fs from 'fs'
import path from 'path'
import { exit } from 'process'

var file = process.argv[2]
if (!file) exit(1)
var content = fs.readFileSync(path.resolve(file), 'utf8')
console.dir(JSON.parse(content), { depth: null })
