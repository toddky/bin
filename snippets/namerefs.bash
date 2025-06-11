#!/usr/bin/env bash
# DESCRIPTION: Name refs (introduced in bash 4.0)

# https://gist.github.com/izabera/e4717562e20eb6cfb6e05f8019883efb
var=foo
echo "$var"

declare -n var_alias=var
var_alias=bar
echo "$var"

var_name='var'
declare -n var_alias2="$var_name"
var_alias2=baz
echo "$var"

echo
tmp=()
x=0
declare -n counter='tmp[tmp[0]=x++,0]'
for i in {1..10}; do
	echo "$counter"
done

echo
f=(0 1)
declare -n fib='f[f[2]=f[0], f[0]+=f[1], f[1]=f[2], 0]'
for i in {1..10}; do
	echo "$fib"
done

echo
months=(- jan feb mar apr may jun jul aug sep oct nov dec)
declare -n month='months[$n]'
n=6
echo "$month"
n=12
echo "$month"

