# Running fully offline with a local model

What we know, and do not know, about running AutoResearchClaw 0.5.0 with no hosted model. Issue numbers point to `ISSUES.md`.

**State of evidence.** We ran two local models: an 8B model for stages 1 to 9 once, and a 35B model for stages 1 to 9 once and for stages 10 to 15 in parts of two runs. No local run produced a usable experiment plan or working code. This page is a starting point for someone who wants to change that, not a recipe that worked.

"Fully offline" needs one qualification: stage 4 searches literature services on the internet. Offline here means the model, the code execution and your data stay on your machine.

## 1. Model choice

| Model | What we saw | What we did not test |
|---|---|---|
| `gemma4:e4b` (8B, 4-bit, Ollama) | Stages 1 to 9 complete in 35 min. Screening dropped every on-topic paper (I-3); the plan was the wrong-domain fallback (I-1) | Any stage after 9 |
| Qwen3.6-35B-A3B (Q4_K_XL, llama.cpp, 1 slot) | Stages 1 to 9 complete in 33 min of stage time; literature mostly on topic; plan was the fallback (I-1). Stage 10 wrote code with an empty entry point twice (I-15). Stage 13 changed nothing with thinking on (I-13) and broke files with thinking off (I-14). Stage 15 reached the same "refine" decision as the hosted model on the same evidence | Other quantisations; a raised reply cap; a second seed |
| DeepSeek-R1-Distill-Llama-70B | **Not run.** It was our planned fallback and was never fetched | Everything. As a reasoning model it would meet I-13 unless reasoning is off or the cap is raised |

What this suggests, with the caution that each cell is one run:

- Stages 1 to 8 are within reach of a 35B model. Stage 9 was not: the plan did not parse.
- Short decision stages worked (stage 15 took 12 s and agreed with the hosted model).
- The stages that write or edit several files are where the local model failed, and at least part of the cause is in the tool's reply handling, not only in the model.

## 2. Context and reply limits

- **Context:** 8,192 tokens fails at stage 5 (HTTP 400). 32,768 was enough for stages 1 to 9. Stage 13 sent 86,650 tokens for a six-file, 300 KB code base and needs 131,072 (I-12).
- **Memory:** the 35B model at 131,072 context and one slot held about 24 GiB of GPU memory.
- **Reply cap:** the tool fixes `max_tokens` per call at 4,096 or 8,192 in its code (I-13). A reasoning model spends that on reasoning. Either turn reasoning off at the server (llama.cpp: `LLAMA_ARG_REASONING=off`) or change the cap in the source and test.
- **Slots:** with one slot, run one pipeline at a time.

## 3. Isolation: read this before stage 10

From stage 10 the tool executes code that a model wrote. Treat that code as untrusted.

**What the defaults give you**

- `sandbox` mode is a plain subprocess in the work folder. It has your user's rights: your home folder, your ssh keys, your cloud tokens, your network (I-6).
- `docker` mode, as shipped, mounts a dataset cache read-write and a model cache read-only, passes `HF_TOKEN` into the container, and lets one component fall back to host execution (I-10).

**What did not work for us as a substitute for Docker**

- bubblewrap: failed where unprivileged user namespaces are blocked.
- A user-level systemd unit with `ProtectHome`: not enforced; a probe still read the ssh folder.

**What we ran**

- Docker with `--network none`, a memory limit, the experiment folder as the only writable mount, one read-only data copy, no home folder and no token.
- A guard in front of `docker` that refuses anything else and logs each call (`examples/docker-guard.sh`).
- A probe before the first run: from inside a container, list the home folder (should be absent), open a network connection (should fail), write to the data folder (should fail).

**If Docker is not available to your account**

Stop at stage 9 (`--to-stage EXPERIMENT_DESIGN`), or use a separate machine or virtual machine that holds no credentials and no data you care about. Being added to the `docker` group is equivalent to root on that host; that is a decision for the machine's owner.

**Other cautions**

- With no network in the container, generated code cannot download datasets or packages. Build the image with the packages in advance and mount the data read-only.
- Work on a copy of your data.
- Check afterwards that nothing outside the work folder changed (for example with `find -newer` against a marker file).
- If you use a coding agent as the model back end, its permission prompts are switched off by the tool (I-11). Use a deny list.
- A guard is a list of patterns, and patterns go wrong in both directions. Ours once refused a harmless flag. Test every rule for one case it must refuse and one it must pass.

## 4. A minimal offline procedure

1. Serve the model on a loopback address with at least 32,768 tokens of context. Point the tool's OpenAI-compatible provider at it.
2. Run stages 1 to 9 with `--auto-approve --to-stage EXPERIMENT_DESIGN`.
3. Read the stage 5 shortlist (count the entries; I-5) and the stage 9 plan (search for content from another field; I-1, I-2).
4. If the plan is the fallback, stop. Rewrite the plan by hand or change the model; do not continue to stage 10.
5. Before stage 10: Docker isolation in place and probed; context raised to 131,072; reasoning off or the reply cap raised.
6. After stage 10: open the entry point and confirm that it calls the analysis (I-15) before stage 12 runs.
7. Keep your own log of every manual change. The tool's log will say a human approved (I-9).

## 5. What would change this page

The tasks in `NEXT-STEPS.md` marked "local" are the ones whose results belong here: a parsable stage 9 plan from a local model, a stage 10 program that runs, and any stage 13 round that improves code.
