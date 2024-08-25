import esprima from 'esprima'
let expr = process.argv[2]
esprima.parse(expr)
