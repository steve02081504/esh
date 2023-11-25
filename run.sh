#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# Parse and process remaining arguments
while [[ $# -gt 0 ]]; do
	case "$1" in
		-Command)
			if [[ $# -gt 1 ]]; then
				command="$2"
				shift 2
			else
				echo "Error: Missing argument after -Command"
				exit 1
			fi
			;;
		*)
			remaining_args+=("$1")
			shift
			;;
	esac
done

# Store parsed remaining arguments in a new variable
parsed_args="${remaining_args[@]}"

# 测试/c/Windows以确定是否在Windows上运行
if [[ -d "/c/Windows" ]]; then
	# 在Windows上运行
	# 对$SCRIPT_DIR进行Windows路径转换
	# 例如：/c/Users/username/Desktop -> C:\Users\username\Desktop
	# 我们不能使用wslpath，因为它不是所有Linux发行版或msys的一部分
	SCRIPT_DIR=$(echo "$SCRIPT_DIR" | sed -e 's/\/c/C:/g' -e 's/\//\\/g' -e 's/^\\//g')
fi

if [[ -z "$command" ]]; then
	if [[ -z "$parsed_args" ]]; then
		pwsh -nologo -NoExit -File "$SCRIPT_DIR/run.ps1"
	else
		pwsh "$parsed_args" -nologo -NoExit -File "$SCRIPT_DIR/run.ps1"
	fi
else
	if [[ -z "$parsed_args" ]]; then
		pwsh -nologo -Command ". $SCRIPT_DIR/run.ps1 ; & $command"
	else
		pwsh "$parsed_args" -nologo -Command ". $SCRIPT_DIR/run.ps1 ; & $command"
	fi
fi
