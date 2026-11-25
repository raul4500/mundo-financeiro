#!/bin/sh
printf '\033c\033]0;%s\a' Mundo Financeiro
base_path="$(dirname "$(realpath "$0")")"
"$base_path/Mundo-Financeiro-Linux.x86_64" "$@"
