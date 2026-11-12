# Setup

What we installed, how we configured it, which models ran, and what each run cost in time. All times are UTC. Everything was read at `researchclaw` 0.5.0, upstream commit `be4ba47`; later versions may differ.

## 1. The tool

AutoResearchClaw runs 23 stages:

| Stages | Work |
|---|---|
| 1 to 3 | Topic, problem tree, search strategy |
| 4 to 5 | Literature collection (OpenAlex, Semantic Scholar, arXiv) and screening |
| 6 to 8 | Knowledge extraction, synthesis, hypotheses |
| 9 | Experiment design |
| 10 to 13 | Code generation, resource planning, experiment run, iterative refinement |
| 14 to 15 | Result analysis, research decision (proceed, refine or pivot) |
| 16 to 23 | Paper draft, review, revision, LaTeX export, citation check |

Stages 5, 9 and 20 are approval gates. `--auto-approve` skips them. `--mode co-pilot` pauses for input at more stages (see I-8 in `ISSUES.md` for the stops we observed). We reached no stage beyond 15, so nothing here describes stages 16 to 23.

## 2. Install

- A separate Python virtual environment per run folder, from a clone of the upstream repository.
- We did **not** run `researchclaw setup`. It installs an extra coding agent and checks Docker and LaTeX. We wrote the configuration by hand from the shipped example and turned the extra coding agent off.
- No paid API key was used in any run.

## 3. Model back ends

The tool accepts an OpenAI-compatible endpoint, the Anthropic API, or an agent through the Agent Client Protocol (ACP).

| Model | Route | Used in | Notes |
|---|---|---|---|
| `gemma4:e4b` (8B, 4-bit) | Ollama, OpenAI-compatible, loopback | Round 1 | Already served on the workstation |
| Qwen3.6-35B-A3B (Q4_K_XL) | llama.cpp server, OpenAI-compatible, loopback, 1 slot | Arm B; full runs after the hosted model was withdrawn | Context 8,192 failed; 32,768 worked for stages 1 to 9; stage 13 needed 131,072 |
| Claude (transcripts show mostly Sonnet 5.5, some Opus turns) | ACP: `acpx` 0.21.1 with `claude-agent-acp`, on a subscription login | Arm A; full runs to stage 15 and stage 9 | Needs the deny list in section 5 |
| DeepSeek-R1-Distill-Llama-70B | not run | none | Planned as a local fallback (about 43 GB download); never fetched or run |

## 4. Hardware class

- Two workstations of the same class: one NVIDIA GB10 system each (integrated GPU with unified memory).
- The 35B model at 131,072 context and one slot held about 24 GiB of GPU memory.
- All experiment containers were CPU only (the host with working Docker had no NVIDIA container runtime), with an 8 GB memory limit.
- No experiment used GPU time. The GPU served the local model only.

## 5. Isolation we applied

Before stage 10 (see `LOCAL-LLM.md` for the reasons):

- Generated code ran only in Docker: `--network none`, a memory limit, the experiment folder as the only writable mount, one read-only data folder, no home folder, no token.
- We patched our local clone: the dataset cache mount became one read-only folder, the Hugging Face cache mount and the `HF_TOKEN` pass-through were removed, and host execution (the subprocess sandbox and the figure renderer's host fallback) raises an error.
- A guard script in front of `docker` refused any run that broke these rules and logged every call. `examples/docker-guard.sh` is a generic version.

For the ACP route:

- The tool calls `acpx` with `--approve-all`, so the agent would accept any tool call without asking.
- A project settings file in the work folder denied shell, file and web tools. `examples/agent-deny-settings.json` is a minimal version. We confirmed by probe that a shell command and a file write were refused. In arm A the agent made 9 tool calls, all to a tool-search function.

## 6. Running co-pilot mode

Co-pilot mode reads from a terminal. Run it under `tmux` and, if you wrap it in `timeout`, use `timeout --foreground`. Without that flag our first attempt hung for an hour at its first prompt (I-7). Give each concurrent run its own tmux socket.

## 7. Measured time and cost

API fees were $0 in every run. Wall time includes waits; stage time is the sum of the tool's per-stage durations.

| Run | Wall time | Stage time | Largest part | Tokens |
|---|---|---|---|---|
| Round 1 (8B, stages 1 to 9) | 35 min | 35 min | Stage 4, 17.8 min | not logged |
| Arm A (Claude, stages 1 to 9) | 1 h 49 min, of which 1 h was a hung first attempt | 43 min + 2 min of gate answers | Stage 4, 33 min, mostly rate-limit waits | 83,289 output; 353,646 cache-write, 638,195 cache-read, 118 uncached input (upper bound: includes our probe sessions) |
| Arm B (35B, stages 1 to 9) | not recorded | 33 min | Stage 4, 14 min; stage 9, 6.5 min | not logged |
| Full run 1 | 13 h 48 min | about 4.2 h | Stage 10, 7,552 s; stage 13, 3,023 s | unknown |
| Full run 2 | 14 h 36 min | about 1.6 h | Stage 10 attempts, 1,345 s and 1,728 s | unknown |

Notes on the table:

- Arm A's tokens were not converted to money. The agent ran on a subscription login.
- Most of the full runs' wall time was waiting: two hosted-model session-limit events (three counting by run, since the first stopped both runs), one run held while the other used the account, and holds for decisions. Full run 2 stood behind full run 1 for most of its wall time.
- The local model server ran for about 0.65 h (full run 1) and 0.9 h (full run 2).
- The gates in arm A cost 122 s over seven interventions by the tool's own count.
