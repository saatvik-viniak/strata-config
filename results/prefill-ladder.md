# Prefill ladder — IQ3_XXS, 3× V100, engine 0.1.42, `--spec 4`

Same box and config as the README (context 393216, YaRN ×1.5, `int8`
KV with 20480 resident cells, `--prefill auto`, solo serving).
Harness: `bench_prefill.py`, 2 reps per rung (both reps in the table;
prefill rate uses the faster rep — rep 1 of the smallest rung caught the
server seconds after a fresh start and paid ~200 s of one-time warmup,
so the median there is the warmup, not the speed).

| prompt (tokens) | TTFT | prefill | decode (256 out) |
|---:|---:|---:|---:|
| 2,518 | 2.71 s | 929 tok/s | 101.8 tok/s |
| 8,572 | 7.0 s | 1,226 tok/s | 107.9 tok/s |
| 33,628 | 13.0 s | 2,593 tok/s | 100.8 tok/s |
| 104,114 | 34.5 s | 3,015 tok/s | 96.5 tok/s |
| 249,304 | 90.6 s | 2,751 tok/s | 90.2 tok/s |

Reading it: prefill scales almost linearly with prompt size here
(~3× the tokens for ~2.4× the time from 8k to 104k) — the prompt path
is not the bottleneck on this setup; waiting comes from queuing, not
reading. Decode gently falls with depth (108 → 96 tok/s) as KV depth
grows. Raw runs: not shipped in this repo (local bench logs only).
