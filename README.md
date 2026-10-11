# strata-config — tuned Strata setup for 3× Tesla V100

A ready-to-use, measured configuration for running
[Strata](https://github.com/Niko1221/Strata) (Qwen3.8-Flash-Next `IQ3_XXS`)
on three NVIDIA Tesla V100 16 GB cards with 63 GB of host RAM.
Machine-specific values (usernames, Tailscale IPs) are stripped — set your
own paths/host where marked.

## Measured on

- 3× Tesla V100-PCIE-16GB (sm_70), driver 580, CUDA 12.6 toolkit for the build
- 2× Xeon E5-2690 v4 (2 sockets × 14 cores), 63 GB RAM
- Strata v0.1.42, engine built locally with `-DSTRATA_EXPERIMENTAL_SM60=ON`
  (Volta needs the experimental CUDA 12 engine — see Strata's
  `docs/OLDER_GPUS.md`), model `IQ3_XXS`, context 393216 (YaRN ×1.5)

## The tuning that matters

`strata-iq3_xxs.json` (all other flags are setup's): `--spec 8→4`,
`--spec-min-p 0.5`, `--kv int8 --kv-resident 20480`,
`--vram-reserve-mib 700`, `--remote-expert-opt`, `--trim-stage-weights`,
`--vision`, `--gpus 0,1,2 --layer-split 18,34`, `--prefill auto`. Solo
serving (no `parallel` — batch slots don't fit 63 GB of RAM at 393k
context; two stuck expert loads and one freeze proved it).

Why `--spec 4`, measured A/B on engine 0.1.42 (same box, same prompts):

| workload | spec 2 | spec 4 | spec 6 | spec 8 |
|---|---|---|---|---|
| coding-agent turns, sampled (8 turns, 2–52k tok) | 74.4 tok/s | **84.9 (×1.10, 7/8)** | 80.9 (×1.04) | 73.9 (×0.99) |
| greedy prose, 8k | 81.1 | 105.9 | 116.8 | 118.7 |
| greedy, 100k | — | 96.2 | 102.8 | — |
| greedy, ~195k | — | 91.8 | 104.3 | — |

Deep draft windows pay on greedy text and waste work on sampled
reasoning — spec 8 is +46% greedy but flat on agent turns. Spec 4 is the
only setting that never loses, and it's the best where latency matters.
`--pool-workers 13` was tried (2-socket tip): slower, keep the default 27.
`--spec-min-p 0.3`: more drafts at worse acceptance, slower.

## How to run it

1. Install Strata per its `docs/AI_SETUP.md` (clone, `./setup.sh --yes
   --family qwen --model IQ3_XXS --no-start`). On Pascal/Volta, setup
   builds the CUDA 12 engine (needs `STRATA_EXPERIMENTAL_SM60=1`, a CUDA
   12.x toolkit, 10–20 min, once).
2. Copy `strata-iq3_xxs.json` over the one setup wrote (adjust `--pack`,
   `--native`, `--ple-gguf`, `--mtp`, `tokenizer` to your paths, `host`
   to `127.0.0.1` or your tailnet IP — never `0.0.0.0` without an
   `--api-key`), and `run-iq3_xxs.sh` next to it (`chmod +x`).
3. Run it: `./run-iq3_xxs.sh`, or as a service:
   `sudo cp strata.service /etc/systemd/system/strata.service` (fix
   `User=`/`%h` first), `sudo systemctl enable --now strata`.
4. Verify: `curl http://127.0.0.1:8080/health` → `"loaded": true`
   (~1 min after start; the 40 GB expert load makes the PC sluggish —
   normal). UI: `http://127.0.0.1:8080/` in a browser.

## Operating notes (earned the hard way)

- One deep (≥100k) run per heat cycle; cards start hot after back-to-back
  runs and deep reads die on heat-soaked GPUs.
- Watch `MemAvailable`: a loaded server holds ~50 GB. Never restart into
  <10 GB free; batch slots at long context need ~5 GB pinned RAM each
  and will swap-kill a 64 GB box.
- Queuing baseline here: 4× 100k concurrent = 237 s wall (4th waits
  ~3 min), combined ~15 tok/s. Slots would fix waiting, not speed.
