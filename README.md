# AutoResearchClaw trial notes

![Illustration of a cell and ranked gene tokens beside anemonefish in a sea anemone, joined by a DNA helix](assets/banner.webp)

*Artwork reused from [Kaisar's research website](https://kays3.github.io/). AI-generated illustration, not a scientific result.*

A record of a two-day trial of [AutoResearchClaw](https://github.com/aiming-lab/AutoResearchClaw) (`researchclaw` 0.5.0, upstream commit `be4ba47`), a 23-stage pipeline that is meant to go from a research topic to a paper. We ran it on 5 and 6 November 2026 with a hosted model and with local models, on topics from our own work in genomics.

**Result in one line: no run produced a paper.** The literature and design stages were useful with a strong model. The code stages did not work with the local model we tried.

This repository is a trial record written so that others, including people who run local models only, can continue from where we stopped. It is not a fork of the tool and holds none of its code.

## What was tried

| Run | Date | Topic | Model | Stages asked | Outcome |
|---|---|---|---|---|---|
| Round 1 | 5 Nov | Transposable element age and intact ORFs in zebrafish | Local 8B model (`gemma4:e4b`, Ollama) | 1 to 9 | Completed, exit 0. Off topic: the stage 9 plan names an image dataset and image models |
| Arm A | 5 Nov | Geneformer in silico perturbation in tumour T cells | Claude through the agent protocol, co-pilot mode | 1 to 9 | On topic. Plan usable as a first draft. Stopped by us at the stage 9 gate |
| Arm B | 5 Nov | Same as arm A | Local Qwen3.6-35B-A3B, autonomous | 1 to 9 | Completed, exit 0. Literature mostly on topic; plan is the tool's fallback with image-domain content |
| Full run 1 | 5 to 6 Nov | A Geneformer paper from stored result tables | Claude to stage 15, then local Qwen | 1 to 23 | **Ended at stage 15 of 23.** The research-decision stage chose "refine" twice; no paper |
| Full run 2 | 5 to 6 Nov | A transposable element paper from an unpublished library | Claude to stage 9, then local Qwen | 1 to 23 | **Ended at stage 10 of 23.** The generated code never ran the analysis; no paper |

Details, stage by stage: [`docs/RESULTS.md`](docs/RESULTS.md).

## What we learned, in plain words

- **The model mattered more than the mode.** With Claude the pipeline stayed on the question through stage 9. With an 8B and a 35B local model the experiment plan fell back to a built-in template from image classification.
- **The tool's health flags did not catch this.** A run that used the fallback plan reported `degraded: false` and exit 0.
- **The most useful behaviour we saw** was at stage 15 under Claude: the tool judged its own experiment too weak to write up, and the reasons it gave held when we checked them against the run files.
- **With the local 35B model, the stages that write or edit multi-file code failed** in the tool's reply format. The causes we could identify are a fixed reply-length cap and the way file contents are parsed from replies.
- **Generated code runs with the user's full rights unless you isolate it.** The default sandbox is a plain subprocess. We ran generated code only in Docker with no network, after patching the tool's Docker defaults.
- **The free literature sources ran out.** A daily quota and rate limits left both full runs with candidates from nearly a single source (525 of 526 and 443 of 444 from arXiv), and full run 2 with an empty shortlist.

## Limits of this record

- Five runs, two days, one tool version, one group. Each configuration ran once. Nothing here measures run-to-run variation.
- Models were not compared under equal conditions. Claude was withdrawn from the tool part-way through both full runs by a decision of ours, so the hosted and local models never ran the same stages of the same run on the same inputs, except stages 13 to 15 of full run 1.
- **DeepSeek-R1-Distill-Llama-70B was planned as a fallback and was never run.** It appears in `docs/LOCAL-LLM.md` as an open task only.
- In every run a supervising AI agent, not a person, answered the tool's approval gates and made the listed interventions. A person set the topics, the data, the isolation rules and the caps.
- Token counts exist for arm A only. For the other runs they are unknown.
- The run files stay on the machines that produced them. No generated plan, code or text is reproduced here; see "Generated material" below.
- We did not report the issues upstream and did not check whether later versions fix them.

## How to reproduce

1. Read [`docs/SETUP.md`](docs/SETUP.md) for the install, the configuration and the measured times.
2. Read [`docs/LOCAL-LLM.md`](docs/LOCAL-LLM.md) before any run that reaches stage 10, where generated code starts to execute.
3. Start with stages 1 to 9 only (`--to-stage EXPERIMENT_DESIGN`) on a topic whose literature you know, and read the stage 5 shortlist and the stage 9 plan yourself.
4. Compare what you see with [`docs/ISSUES.md`](docs/ISSUES.md).
5. Pick a task from [`docs/NEXT-STEPS.md`](docs/NEXT-STEPS.md).

## Contents

| File | Content |
|---|---|
| [`docs/SETUP.md`](docs/SETUP.md) | Install, models, hardware class, measured time and cost |
| [`docs/RESULTS.md`](docs/RESULTS.md) | Each run, stage by stage, with where it failed |
| [`docs/ISSUES.md`](docs/ISSUES.md) | One entry per known problem: symptom, evidence, suspected cause, workaround, status |
| [`docs/NEXT-STEPS.md`](docs/NEXT-STEPS.md) | Continuation tasks with acceptance criteria |
| [`docs/LOCAL-LLM.md`](docs/LOCAL-LLM.md) | Running fully offline: model choice, context limits, isolation |
| [`examples/`](examples) | A Docker guard script and an agent deny list, written for this repository |

## Generated material

No machine-generated paper exists, because no run reached the writing stages. We include no excerpt of generated hypotheses, plans or code: the full runs worked on unpublished data, and the earlier outputs were not reviewed for release. Where this record describes generated content (for example "the plan names CIFAR-10"), it is our description of unreviewed machine output.

## Licence

Code under `examples/` is released under the MIT licence (`LICENSE`). Text is released under CC BY 4.0 (`LICENSE-DOCS.md`). AutoResearchClaw itself is a separate project under its own MIT licence.
