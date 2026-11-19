#!/bin/sh
# check.sh BINARY: the ts leg. Each folder of ts/cases is a case of a
# TypeScript check: `bun ARGS...` (its args file, one argument a line) runs
# in a fresh folder that holds a copy of ts/, after the case's setup.sh
# (run there as `sh setup.sh CASEDIR`), with ERGO_BIN naming the built
# tn1-lint and HOME an empty folder. Its standard output must equal
# expected.out byte for byte, and its status expected.status (0 when
# absent). Run `bun install --frozen-lockfile` in ts/ first. No case is a
# failure.
set -u
bin=${1:?usage: check.sh BINARY}
case "$bin" in /*) ;; *) bin=$(pwd)/$bin ;; esac
ts=$(cd "$(dirname "$0")" && pwd)
[ -d "$ts/node_modules/typescript" ] || { echo "ts: run bun install --frozen-lockfile in ts/ first" >&2; exit 2; }
scratch=$(mktemp -d)
echo "ts: cases run under $scratch"
n=0 failed=0
for c in "$ts"/cases/*/; do
	[ -f "$c/args" ] || continue
	c=${c%/}
	name=$(basename "$c")
	n=$((n + 1))
	work="$scratch/$name"
	mkdir -p "$work/home"
	cp -R "$ts" "$work/ts"
	if [ -f "$c/setup.sh" ]; then
		(cd "$work" && HOME="$work/home" sh "$c/setup.sh" "$c") >"$work/setup.log" 2>&1 || { echo "FAIL ts/$name: setup.sh"; cat "$work/setup.log"; failed=$((failed + 1)); continue; }
	fi
	set --
	while IFS= read -r a || [ -n "$a" ]; do set -- "$@" "$a"; done <"$c/args"
	in=/dev/null
	[ -f "$c/stdin" ] && in="$c/stdin"
	(cd "$work" && HOME="$work/home" ERGO_BIN="$bin" bun "$@") <"$in" >"$work/out" 2>"$work/err"
	status=$?
	want=0
	[ -f "$c/expected.status" ] && want=$(cat "$c/expected.status")
	if [ "$status" != "$want" ] || ! cmp -s "$work/out" "$c/expected.out"; then
		echo "FAIL ts/$name: status $status (want $want)"
		diff "$c/expected.out" "$work/out" | head -40
		head -20 "$work/err"
		failed=$((failed + 1))
	else
		echo "ok ts/$name"
	fi
done
[ "$n" -gt 0 ] || { echo "ts: no cases in $ts/cases" >&2; exit 1; }
[ "$failed" = 0 ]
