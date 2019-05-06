#!/bin/bash
read -p "Music name (without +): " name
read -p "Run time (seconds): " runtime
read -p "Tempo (BPM) (leave empty to ignore): " beats
if [ -n $1 ]; then
	ext="${1#*.}"
	out=""
	if [ ${#name} ]; then
		out="$name"
	fi
	if [ ${#runtime} ]; then
		out="$out+$runtime"
	fi
	if [ ${#beats} != 0 ]; then
		out="$out+$beats"
	fi
	cp $1 "$out.$ext"
fi
