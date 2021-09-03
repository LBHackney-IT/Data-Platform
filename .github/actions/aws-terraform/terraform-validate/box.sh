#!/usr/bin/env bash
echo $1 | sed -e 's/^/../' -e 's/$/../' -e 's/./*/g'
echo $1 | sed -e 's/^/* /' -e 's/$/ */'
echo $1 | sed -e 's/^/../' -e 's/$/../' -e 's/./*/g'
