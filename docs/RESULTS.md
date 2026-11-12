# Results

Five runs on 5 and 6 November 2026. No run produced a paper. All times are UTC. Issue numbers (I-1 and so on) point to `ISSUES.md`.

Descriptions of generated content are ours and the content itself is unreviewed machine output. "The supervising agent" is an AI agent that answered the tool's gates and made the listed interventions; no person answered a gate.

## 1. Round 1: local 8B model, stages 1 to 9

- **Topic:** "Do young transposable element copies in zebrafish carry intact ORFs more often than old copies?"
- **Set-up:** `gemma4:e4b` through Ollama, `--auto-approve`, `--to-stage EXPERIMENT_DESIGN`, 1-hour cap.
- **Outcome:** 9 of 9 stages done, 0 failed, exit 0, 35 min, 1.8 MB of output. The content went off topic.

| Stage | What it produced |
|---|---|
| 4 Literature collection (17.8 min) | 508 candidates with 508 BibTeX entries. 57 mention zebrafish, including a paper on zebrafish transposable element age and expression |
| 5 Screening | A 15-paper shortlist with **0 papers on zebrafish** (brown algae, maize, Drosophila, a mouse SINE family, fungi, a bird population) (I-3) |
| 8 Hypotheses | Three hypotheses written as a debate between three personas. The first proposes a score built from chromatin marks within 5 kb and predicts a correlation of at least 0.35 with an "ORF score". It reads fluently and rests on no data |
| 9 Experiment design | **Wrong domain.** The model's plan failed to parse. The fallback plan names CIFAR-10 as the dataset and three image-generation models as baselines, with placeholder metrics (I-1) |

The tool's summary said `degraded: False`.

We stopped at stage 9 on purpose: on this host, generated code would have run as a plain subprocess with access to the user's ssh keys (I-6).

## 2. Round 2: one topic, two arms, stages 1 to 9

- **Topic:** "Do Geneformer in silico deletion and overexpression shifts in donor-held-out lung adenocarcinoma T cells separate curated T-cell genes from random expressed genes?"
- **Yardstick:** we had already done this study, so we could compare each plan with a design we know. Our design used a random expressed-gene null matched on expression, held-out donors, and both operations. One of its findings is that deletion and overexpression shifts of random genes are anti-correlated (Spearman rho -0.593 in lung T cells; public data, reported in our separate methods repository `geneformer-research-methods`). We did not test what causes that correlation.
- The topic sentence already names held-out donors, both operations and random genes. Part of any plan's closeness to our design is therefore built into the prompt.

### Arm A: co-pilot mode, Claude through ACP

| Stage | What it produced |
|---|---|
| 1 Topic | Restated the goal with matched random genes, held-out donors, both operations, and rank and expression as confounds |
| 4 Literature (33 min) | Mostly waits on OpenAlex rate limits (HTTP 429) |
| 5 Screening | 16 papers; 14 on Geneformer or single-cell in silico perturbation, several on lung adenocarcinoma or T cells. Two off topic (a kidney cancer mechanism paper, a 2020 lung metastasis atlas) |
| 7 Synthesis | Five gaps: a random-gene null in tumour T cells, held-out donors, paired operations against the null, defined metrics, gene-set provenance |
| 8 Hypotheses | Treats "curated beats random" as expected and uninformative, because curated markers are highly expressed and co-expressed, and proposes a ladder of harder nulls. One hypothesis predicts that overexpression shifts track a gene's original rank |
| 9 Experiment design | A public lung adenocarcinoma atlas (GEO GSE131907); donors with at least 100 T cells as the unit; an expression- and detection-matched null with 1,000 draws; a covariate-only ridge baseline; ablations for pooled-cell pseudoreplication and rank stratification; gene sets frozen before the run |

- **Stage reached:** 1 to 8 approved, 9 written. We aborted at the stage 9 gate so that stage 10 could not start. The tool reports this as "7/9 done, 1 failed".
- **Our reading:** a fair first draft of a design, close to what we did. The rank hypothesis is related to our anti-correlation finding but is not the same result.
- **Weak points of the plan:** the compute section assumes one high-end GPU and a 300 s budget, which comes from the tool's template (I-2); it picks the 6-layer Geneformer checkpoint; one baseline is cited as "to be verified"; there is no power calculation for a named target gene.

### Arm B: autonomous, local Qwen3.6-35B-A3B

| Stage | What it produced |
|---|---|
| 1 Topic | Renamed the topic to a general title about "perturbation fidelity in foundation models", with benchmark claims the tool itself flagged as unverified |
| 5 Screening | 12 of 15 papers on single-cell foundation models or in silico perturbation. The first attempt failed here with HTTP 400 at an 8,192-token context; a rerun from scratch at 32,768 finished (I-12) |
| 8 Hypotheses | Written in invented terms (for example a "trajectory determinism ratio") |
| 9 Experiment design | No parsable plan from the model, so the plan is the tool's fallback. Objectives and methods are on topic. Datasets list CIFAR-10, baselines are two image domain-adaptation methods, compute is four data-centre GPUs for 72 h (I-1, I-2) |

- **Stage reached:** 9 of 9, 0 failed, exit 0, `degraded: false`. Stage time 33 min.
- **Our reading:** the plan does not mention the rank confound, matching of the null genes, or power. It could not go to code generation without rewriting.

## 3. Full run 1: a Geneformer paper from stored tables

- **Set-up:** co-pilot mode under tmux. The topic restricted the run to stored per-gene result tables of an earlier Geneformer study: no new perturbation, no GPU for experiments. Generated code ran only in CPU containers with no network (see `SETUP.md` section 5).
- **Models:** Claude for stages 1 to 15. On 6 November at about 05:55 we withdrew Claude from the tool (a decision about our hosted-model use, not a failure of the run). The re-entry into stage 13 and the second pass through stages 14 and 15 ran on local Qwen3.6-35B-A3B.
- **Outcome:** ended at stage 15 of 23. Wall time 13 h 48 min; stage time about 15,000 s (4.2 h).

| Stage | Model | Duration (s) | Outcome |
|---|---|---|---|
| 1 Topic | Claude | 66 | done |
| 2 Problem tree | Claude | 131 | done |
| 3 Search strategy | Claude | 63 | done |
| 4 Literature collection | Claude | 206 | done; 525 of 526 candidates from arXiv alone (I-4) |
| 5 Screening (gate) | Claude | 8 to the gate | approved after a manual correction: one off-topic paper (on electric guitars) removed, 5 added, 19 in total |
| 6 Knowledge extraction | Claude | 111 | done |
| 7 Synthesis | Claude | 125 | done |
| 8 Hypotheses | Claude | 302 | done; the real table columns and the list of missing covariates were appended by hand |
| 9 Experiment design (gate) | Claude | 2 to the gate | approved with a correction appended (the plan had read a "control" label as positive controls; it means matched controls) |
| 10 Code generation | Claude | 7,552 | done after two session-limit failures (I-19) |
| 11 Resource planning | Claude | 42 | done |
| 12 Experiment run | generated code | 43 | metrics written, but the run record says "failed"; ran after a one-line manual fix (I-16) |
| 13 Iterative refinement | Claude | 3,023 | stopped on the wall-clock cap; no improvement |
| 14 Result analysis | Claude | 1,455 | done |
| 15 Research decision | Claude | 54 | **refine** |
| 13 again, try 1 | Qwen, thinking on | 725 | no change: every reply was cut at the tool's 4,096-token cap before any code (I-13). A first call failed with HTTP 400 because the 86,650-token prompt exceeded a 65,536 context (I-12) |
| 13 again, try 2 | Qwen, thinking off | 772 | three rounds; each replaced `main.py` with the 7-byte text "main.py" and crashed; the final code is the unchanged earlier code (I-14) |
| 14 again | Qwen | 365 | done; outputs not checked |
| 15 again | Qwen | 12 | **refine**; not approved; run ended |

**Why it ended.** The first stage 15 judged the experiment too weak to write up. Its reasons, which we checked against the stage 12 files and found correct:

- the run ended as "failed" after 43 s against a planned 1,410 s;
- metrics were scraped from standard output, not read from a results file;
- six of seven arms had one effective replicate, because the seed did not reach the null sampler;
- the primary metric was an absolute log ratio, which hides the direction of an error.

The refine loop then fell to the local model, which could not edit the six-file code base (about 300 KB) in the tool's reply format. The second stage 15 chose refine again on the same evidence. Our rule was to end the run at a second refine.

**Interventions:** 12, all by the supervising agent, among them the shortlist and plan corrections above, restarts after limits, one manual line removal, and resetting the checkpoint by hand twice (I-18). Two were our own faults: a wait helper that missed an existing prompt cost about 50 min, and a first resume entered stage 16 for under two minutes before we stopped it.

**Claims:** none. The stage 12 metrics and both stage 14 analyses were never checked against our own records.

## 4. Full run 2: a transposable element paper

- **Set-up:** as full run 1. The data were an unpublished transposable element library and genome annotation for one fish species, mounted read-only. The topic asked for sequence divergence by superfamily and for the effect of library redundancy and provisional class labels on the repeat landscape.
- **Models:** Claude for stages 1 to 9, then local Qwen3.6-35B-A3B (131,072 context, thinking off).
- **Outcome:** ended at stage 10 of 23. Wall time 14 h 36 min; stage time about 5,600 s (1.6 h).

| Stage | Model | Duration (s) | Outcome |
|---|---|---|---|
| 1 to 3 | Claude | 65, 72, 59 | done |
| 4 Literature collection | Claude | 519 | done; 443 of 444 candidates from arXiv alone (I-4) |
| 5 Screening (gate) | Claude | 113 | the automatic screen returned **no papers**. The run passed the gate with an empty shortlist and stage 6 failed at once (I-5). A 23-paper shortlist was then built by hand from Crossref and Semantic Scholar records and used |
| 6 to 8 | Claude | 211, 100, 418 | done |
| 9 Experiment design (gate) | Claude | 206 | approved |
| 10 Code generation | Claude | 781 | failed on a session limit (I-19) |
| 10, try 1 | Qwen | 1,345 | done, but `main.py` never called the analysis; approved in the expectation of a later repair (I-15) |
| 11 Resource planning | Qwen | 18 | done |
| 12 Experiment run | generated code | 0.45 | failed: the program printed that the data existed and exited; zero metrics. The tool stops here; there is no repair turn (I-15) |
| 10, try 2 | Qwen | 1,728 | `main.py` is a configuration class only, with no entry point; not approved; run ended |

**Interventions:** 8, all by the supervising agent. One was our own fault: a pattern in our Docker guard meant to block `--pid=host` also refused the tool's harmless `--pids-limit` flag, and stage 12 was refused once before we narrowed the pattern.

**Claims:** none. No experiment produced a number. No synthetic data ran: the first generated program had a synthetic-data branch that runs only if the data are missing, and they were present.

## 5. Summary table

| | Full run 1 | Full run 2 |
|---|---|---|
| Furthest stage | 15 of 23 | 10 of 23 (stage 12 failed once) |
| Why it ended | Research decision chose refine twice | Generated code never ran the analysis, twice |
| Wall time | 13 h 48 min | 14 h 36 min |
| Stage time | about 4.2 h | about 1.6 h |
| Interventions | 12 | 8 |
| GPU for experiments | 0 h | 0 h |
| Local model server | about 0.65 h | about 0.9 h |
| Tokens | unknown | unknown |
| Checked claims | none | none |

## 6. What the results do not show

- They do not rank the models. Each configuration ran once, on different stages.
- They do not show that a local model cannot drive the code stages. One 35B model failed in one tool version, with a fixed reply cap that we did not change (I-13). A larger cap, a different model or a different reply format was not tried.
- They do not show that the tool's papers would be wrong. No paper was written, so the writing, review and citation stages are untested here.
- Arm A's plan quality is one sample on a topic whose answer we already knew and partly stated in the prompt.
