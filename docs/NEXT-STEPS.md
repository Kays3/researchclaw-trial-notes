# Next steps

Continuation tasks, each sized for one person or one local-model agent session, with acceptance criteria. Issue numbers point to `ISSUES.md`.

Conventions:

- **Size:** S = under two hours, M = half a day, L = more than a day.
- **Who:** "person" needs judgement or access; "agent" can be done by a coding agent under supervision; "local" needs a locally served model.
- Every task ends with a short written record: tool version and commit, model and quantisation, context size, what was run, what was seen. A task that fails its criteria is still a result; record it as failed.
- Use a public topic with public data, so that outputs can be shared.

## A. Check our findings on the current upstream version

| # | Task | Size | Who | Acceptance criteria |
|---|---|---|---|---|
| A1 | Re-test each issue in `ISSUES.md` on the latest upstream release | M | person or agent | A table with one row per issue: reproduced, not reproduced, or not tested, with the version and one line of evidence |
| A2 | Search the upstream issue tracker for each open issue and report the ones that are missing | M | person | A list of links for known issues; for each new one, a report with a minimal reproduction. Reports are filed by a person, not by an unattended agent |
| A3 | Confirm the co-pilot stop list (I-8) through all 23 stages | S | person | The observed list of stops for a full co-pilot run, set against the documentation |

## B. Make failures visible

| # | Task | Size | Who | Acceptance criteria |
|---|---|---|---|---|
| B1 | A checker script that reads a stage 9 plan and flags fallback or foreign-domain content (I-1, I-2) | S | agent | Given a plan file and a short list of field terms, exits non-zero for a plan that names CIFAR-10 or has no field term; passes a hand-written on-topic plan; has tests for both |
| B2 | A checker for the stage 5 shortlist: count, source mix, share of entries that match topic terms (I-3 to I-5) | S | agent | Exits non-zero for an empty shortlist and for a shortlist with no topic term; prints the count per source |
| B3 | A checker for the stage 10 output: does the entry point reach the analysis (I-15); is there a marker line or a file whose body is its own name (I-14, I-16) | M | agent | Flags each of the three faults on small fixtures; passes a working fixture |
| B4 | Propose upstream that the run summary marks any use of a fallback as degraded | S | person | An upstream issue or patch, with the round 1 symptom as the test case |

## C. Local models (results go to `LOCAL-LLM.md`)

| # | Task | Size | Who | Acceptance criteria |
|---|---|---|---|---|
| C1 | Stage 9 with a local model: find out why the plan does not parse | M | local, agent | The raw model reply and the parse error, saved from one run; a statement of which it is: wrong format, cut-off reply, or parser strictness |
| C2 | Raise or expose the reply cap (I-13) and re-run stage 13 with reasoning on | M | local, agent | With the cap raised, at least one stage 13 round that changes code, or a record that replies still end before code, with reply lengths |
| C3 | Reproduce I-14 on a small fixture: a two-file project and one refinement round | M | local, agent | A fixture that shows the file-name-as-body fault, or a record that it does not occur at the tested version; the raw reply saved |
| C4 | Run DeepSeek-R1-Distill-Llama-70B (or another 70B-class model) on stages 1 to 9 of a public topic | L | local, person | Shortlist and plan checked with B1 and B2; times, context and memory recorded. We never ran this model |
| C5 | Compare three local models on stage 5 screening alone, on a fixed candidate list | M | local, agent | For each model: how many of a hand-labelled set of on-topic papers reach the shortlist. One fixed list of at least 200 candidates, labels made before the runs |
| C6 | Stage 10 from a hand-corrected plan with a local model | L | local, person | A program whose entry point runs the analysis in a container with no network, or a record of the fault after two attempts |

## D. Isolation

| # | Task | Size | Who | Acceptance criteria |
|---|---|---|---|---|
| D1 | Turn our local patch of Docker mode (I-10) into an upstream proposal: read-only data mount, no token, no host fallback, as configuration options | M | person or agent | A patch against the current upstream with the three options and a test that the container has no network and no token |
| D2 | Test `examples/docker-guard.sh` against real `docker run` lines from a run | S | agent | Every line the tool issues in one full run passes; ten hostile lines are refused; the list of both is kept |
| D3 | Evaluate one rootless alternative (rootless Podman, or a virtual machine) for hosts where Docker is not allowed | M | person | The three probes of `LOCAL-LLM.md` section 3 pass, or a record of which failed |
| D4 | Check the agent deny list against the current agent adapter | S | person | Probes for shell, file write, file read and web access are each refused |

## E. Literature stage

| # | Task | Size | Who | Acceptance criteria |
|---|---|---|---|---|
| E1 | Measure how many runs a day the free sources allow from one address (I-4) | S | agent | Requests and failures per source for three runs spaced over a day |
| E2 | A way to supply a hand-built list of records to stage 5 without editing run files | M | agent | A documented procedure or patch; the supplied records appear in the shortlist and are marked as supplied by hand |
| E3 | Use stages 1 to 4 alone as a literature sweep and judge the candidate list | S | person | For a topic the person knows: how many of ten key papers are among the candidates |

## F. Evaluation

| # | Task | Size | Who | Acceptance criteria |
|---|---|---|---|---|
| F1 | Repeat one configuration three times on a public topic to see run-to-run variation | L | person | The same stage 5 and stage 9 checks for each run, reported side by side. We ran each configuration once |
| F2 | Complete all 23 stages once on a public dataset, with a model of your choice | L | person | Either a generated paper, labelled machine-generated and unreviewed, with every claim traced to a file of the run, or the stage and cause of failure |
| F3 | If F2 yields a paper: check its numbers and citations by hand | L | person | A table of claims: supported by the run files, unsupported, or wrong; and of citations: exists and says what is claimed, exists and does not, or does not exist |

## Suggested order

B1 to B3 first (small, and they make every later run cheaper to read), then C1 and C2 (they decide whether local models can pass stages 9 and 13 at all), then D2, then F2.
