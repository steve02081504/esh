import esprima from 'npm:esprima'
let expr = process.argv[2]
esprima.parse(expr)
