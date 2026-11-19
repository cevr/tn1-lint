# tn1-lint

TN1's sidecar for TypeScript projects. It runs beside oxlint and prints its findings in oxlint's JSON form (`--format json`), so whatever reads oxlint's report reads these too:

```sh
oxlint --format json src > oxlint.json
tn1-lint lint --rule narration narration.tn1 src/*.ts > tn1.json
```

```sh
tn1-lint lint --rule NAME WEIGHTS FILE...   # findings, oxlint JSON; always exit 0 (advisory)
tn1-lint record FILE                        # the feature record of FILE (a FILE of - is the standard input)
tn1-lint project FILE...                    # each FILE's record version 3 in the project of FILEs, after "== FILE"
tn1-lint chunks FILE                        # each top-level statement: FROM TO (bytes)
tn1-lint serve                              # one JSON reply line per JSON request line, until EOF
tn1-lint --help                             # the usage; exit 0
```

It reads TypeScript itself, through the TypeScript host of TN1's feature record (`github.com/cevr/tn1-lint/tn1/ts`): a scanner (comments, strings, templates with nested `${}`, a regular expression told from a division, the braces open at each line), the record's rules stated over its tokens, and the file's top-level statements. The network and the engine are TN1's (`github.com/cevr/tn1-lint/tn1`), the ones `ergo lint` runs on Ergo source; no Ergo toolchain is needed beside the binary.

A finding's span is the comment on its line; its probability and the model's id (the first 12 hex digits of `tn1 id`) are in its message, and its severity is `advice`.

Cases. `cmd/tn1-lint/cases` runs the binary (`ergo test ./cmd/tn1-lint --cases cmd/tn1-lint/cases`); `ts/cases` is the TypeScript leg (`sh ts/check.sh BINARY`: Bun and the `typescript` package pinned in `ts/bun.lock`):

- `ts/cases/agree` is the law of the chunks: on seeded programs (imports, templates, regular expressions, ASI across `?:` and `.pipe` chains, decorators, labels, `Array<Array<X>>`, blocks followed by `;`), the statements `tn1-lint chunks` reads are the ones the TypeScript compiler's parser reports, from `getStart()` to `end`. A failing seed prints the program, both lists and `SEED=n bun ts/agree.ts`.
- `ts/cases/records` holds the host to the conformance vectors (`tn1/testdata/vectors`): `tn1-lint record` of each `src/*.ts.txt` is its `records/*.record`, byte for byte; and `tn1-lint project` over each `projects/P` is its `records/P-*.record` (record version 3: the file's package, the file itself and its declarations' callers in the project's import graph). oxlint-plugin-effect's ESTree extractor is held to the same records, and its JavaScript engine to `expected.tsv`.
- `lint` is the oxlint report of the narration control on the vectors' TypeScript source.
- `usage` is a bad command line; `help` is `--help`.
- `stdin` is `lint` of the standard input (`-`), the way the effect-oxlint rule `tn1Lint` passes a buffer.
- `serve` is the long-lived mode: each line of its input is a request `{"rule","weights","path","text"}` and each line of its output the reply `{"diagnostics","error"}`, the diagnostics `lint` reports for that text. A weights file is parsed once per run; a request that fails (no such weights file, a line that is not a request) is an `error` reply and the next line is read. The package's JS wrapper keeps one `serve` per lint run (below).

The npm package `@cevr/tn1-lint` (`npm/tn1-lint`) ships this program's static binary per platform, and `lint.js`, a synchronous `lintSync` for an oxlint rule that holds one `serve` process per lint run through a worker thread and `Atomics.wait` (`node npm/sidecar-check.js BINARY N` counts its process starts against one `lint` per file, compares the two paths' findings, and checks that no `serve` outlives the run): `sh npm/pack.sh tn1-lint` builds and dry-packs it, `sh npm/check.sh tn1-lint DIR` installs the packs with bun and npm and runs `tn1-lint --help`. `cmd/tn1-lint/workload` is a workload for ergo's `scripts/opcount`: the record of N bytes of TypeScript (`bench/gen`) against the hand Go control in `bench/control`; `bench/floor` is its floor.

What it shows: closed unions for the token kinds and the commands, exhaustive `match` over them, typed failures (`os.Exit`, `tn1.Malformed`) and a record (`Report`) whose field keys are oxlint's names.

## Layout

One Ergo module, `github.com/cevr/tn1-lint` (`ergo.mod` names the lowest ergo that builds it):

- `tn1/` is the engine: the network, the feature record and the conformance vectors (`tn1/testdata/vectors`); `tn1/ts` is the TypeScript host of the record; `tn1/suite` scores a network on a suite.
- `cmd/tn1-lint` is this program, and `cmd/tn1` the engine's own command line ([cmd/tn1/README.md](cmd/tn1/README.md)); each holds its `cases/`.
- `ts/` is the TypeScript leg, `npm/` the npm packages and their scripts, `bench/` the workload's input generator, hand Go control and floor.

## Building and checking

With `ergo` on `PATH` (`go install github.com/cevr/ergo/cmd/ergo@VERSION`, VERSION from `ergo.mod`):

```sh
ergo fmt --check . && ergo check ./... && ergo test ./...
ergo build ./cmd/tn1-lint -o out/tn1-lint && ergo build ./cmd/tn1 -o out/tn1
ergo test ./cmd/tn1-lint --cases cmd/tn1-lint/cases
ergo test ./cmd/tn1 --cases cmd/tn1/cases
(cd ts && bun install --frozen-lockfile) && sh ts/check.sh out/tn1-lint
```

CI (`.github/workflows/ci.yml`) runs the same, then packs and checks the npm packages. `release.yml` publishes them on a tag `vX.Y.Z`, with the secret `NPM_TOKEN` the owner sets.

## Mutants

`tn1/testdata/mutants.json` is the engine's mutant ledger. It moved here from ergo with its paths rewritten to this layout (a killer `test:./...` is `ergo test ./...`); no mutant has been judged in this layout yet.

## History

This repository was split out of [cevr/ergo](https://github.com/cevr/ergo) with its history (`git filter-repo`): the engine was `modules/tn1` there, this program `examples/tn1-lint` (first `examples/lint-ts`), `cmd/tn1` was `examples/tn1`, `npm/` was `tools/npm` and `scripts/npm*.sh`, and `bench/` was `cmd/ergo/testdata/tn1lint`. Commit messages keep the old paths.
