import { parse } from 'npm:acorn'
import { walk } from 'npm:estree-walker'
import { generate } from 'npm:astring'
import { builders } from 'npm:ast-types'
let expr = process.argv[2]
// 使用 acorn 解析代码为 AST
const ast = parse(expr, {
	ecmaVersion: 'latest',
	sourceType: 'module',
})
// 使用 estree-walker 遍历 AST，并进行修改
walk(ast, {
	enter(node, parent, prop, index) {
		if (
			node.type === 'Program' &&
			!node.body.some(n => n.type === 'ReturnStatement')
		) {
			// 如果没有 return 语句，则添加 return 语句
			const lastStatement = node.body[node.body.length - 1]
			if (lastStatement && lastStatement.type === 'ExpressionStatement')
				node.body[node.body.length - 1] = builders.returnStatement(
					lastStatement.expression,
				)
			else if (lastStatement && lastStatement.type === 'VariableDeclaration') {
				const lastDeclaration = lastStatement.declarations[lastStatement.declarations.length - 1]
				if (lastDeclaration.init)
					node.body.push(builders.returnStatement(lastDeclaration.id))
			}
		}
	},
})

// 将修改后的 AST 转换回代码
const modifiedCode = generate(ast)
console.log(`(async () => {${modifiedCode}})()`)
