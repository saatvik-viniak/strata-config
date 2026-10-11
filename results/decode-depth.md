# Decode vs prompt depth — greedy filler, 256-token outputs

Same box and engine as the README (3× V100, 0.1.42, 393k context).
`--spec 4` is the shipped config; `--spec 6` shown as reference where
measured (spec 6 wins greedy only and loses on sampled agent turns —
see README). Method: `bench_prefill.py` prompt ladder, server decode
rate from `/metrics` (`decode_tok_s`, excludes time-to-first-token).

| prompt (tokens) | spec 4 decode | spec 6 decode |
|---:|---:|---:|
| 2.5k | 101.8 tok/s | 107.1 tok/s |
| 8.6k | 107.9 | 116.8 |
| 33.6k | 100.8 | — |
| ~100k | 96.5 | 102.8 |
| ~195k | 91.8 | 104.3 (98.8 on rerun) |

Reading it: decode falls gently with depth (~108 → ~92 tok/s from 8k
to 200k on spec 4) as KV depth grows; draft acceptance holds ~87–90%
throughout, which is why deeper speculation keeps paying on greedy
text. The 200k points need a cold start — back-to-back deep reads on
heat-soaked cards die mid-prefill (retried clean at 38 °C start,
62 °C peak, RAM steady).
