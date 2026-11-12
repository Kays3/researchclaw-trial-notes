# Known issues

One entry per problem we met with `researchclaw` 0.5.0 (upstream commit `be4ba47`). Each has a symptom, the evidence, a suspected cause, a workaround and a status.

How to read the entries:

- **Evidence** is what we observed in the named run (`RESULTS.md`). Most entries rest on one or two observations.
- **Suspected cause** is our reading of behaviour and logs. Where we did not read the tool's source for an entry, the cause is a guess and the entry says so.
- **Status** "open" means: seen by us at this version, not reported upstream by us, and not re-checked on a later version.

| Group | Entries |
|---|---|
| Wrong or unflagged content | I-1 to I-3 |
| Literature | I-4, I-5 |
| Isolation and safety | I-6, I-10, I-11 |
| Co-pilot mode | I-7 to I-9 |
| Local models | I-12 to I-15 |
| Generated code and run control | I-16 to I-18 |
| Operations | I-19, I-20 |

---

### I-1. A fallback plan from another domain passes as a healthy run

- **Symptom:** the stage 9 experiment plan names an image dataset (CIFAR-10) and image models as baselines for a genomics topic. The run ends with exit 0 and `degraded: false`.
- **Evidence:** round 1 (8B model) and arm B (35B model). In both the model's own plan did not parse and the tool substituted a plan.
- **Suspected cause:** the fallback plan is a fixed template from machine-learning benchmarks, and the health summary does not count the use of a fallback as degradation.
- **Workaround:** read the stage 9 plan yourself. Search the plan for dataset and baseline names that do not belong to your field before approving anything after stage 9.
- **Status:** open.

### I-2. Template values leak into plans that are otherwise on topic

- **Symptom:** the compute section of a good plan assumes hardware and budgets nobody specified (one high-end GPU and 300 s in arm A; four data-centre GPUs for 72 h in arm B).
- **Evidence:** arm A (Claude) and arm B.
- **Suspected cause:** default values in the plan template or prompt are carried through when the model has no better information. Guess; source not read.
- **Workaround:** state your hardware and time budget in the topic or the configuration, and check the compute section at the stage 9 gate.
- **Status:** open.

### I-3. Screening with a small model drops the on-topic papers

- **Symptom:** the shortlist contains no paper on the organism in the question.
- **Evidence:** round 1. Of 508 candidates, 57 mentioned zebrafish; the 15-paper shortlist held none.
- **Suspected cause:** the 8B model's relevance scoring. Not separated from prompt or batching effects.
- **Workaround:** read the shortlist at the stage 5 gate; use a stronger model for stages 5 to 9; or stop after stage 4 and screen the candidate list yourself.
- **Status:** open. One observation.

### I-4. Free literature sources run out, leaving one source

- **Symptom:** nearly all candidates come from arXiv (525 of 526 and 443 of 444). Stage 4 takes long because of waits.
- **Evidence:** both full runs, started the same evening as three earlier runs. In arm A, stage 4 took 33 min, mostly HTTP 429 waits.
- **Suspected cause:** a daily request quota on OpenAlex and rate limits on Semantic Scholar, shared by all runs from one address.
- **Workaround:** space runs out; register for the sources' API keys or polite pools where offered; for fields that arXiv covers poorly (much of biology), supply a hand-built list of records.
- **Status:** open. A property of the sources as much as of the tool.

### I-5. An empty shortlist passes the gate, and the next stage fails

- **Symptom:** stage 5 returns no papers, the gate can still be passed, and stage 6 fails at once for lack of input.
- **Evidence:** full run 2.
- **Suspected cause:** no check that the shortlist is non-empty before the gate or before stage 6.
- **Workaround:** count the shortlist entries before answering the stage 5 gate.
- **Status:** open.

### I-6. The default sandbox does not isolate generated code

- **Symptom:** in `sandbox` mode, generated code runs as a plain subprocess with the user's rights. It can read the home folder, including ssh keys.
- **Evidence:** read before round 1. Two confinement methods we tried on that host also failed: bubblewrap stopped with "setting up uid map: Permission denied" (unprivileged user namespaces were blocked), and a user-level systemd unit did not enforce `ProtectHome` (a probe could still read the ssh folder).
- **Suspected cause:** by design; `sandbox` names a working directory, not a security boundary.
- **Workaround:** do not let stage 10 start in this mode on a machine with credentials. Use Docker mode with the changes in I-10, or a throwaway machine with no credentials and no network.
- **Status:** open.

### I-7. Co-pilot mode hangs without a real terminal

- **Symptom:** the run sits at its first prompt and never proceeds.
- **Evidence:** arm A, first attempt: one hour lost. The process had been stopped on a terminal read (SIGTTIN) under `timeout` without `--foreground`.
- **Suspected cause:** the prompts read from the controlling terminal.
- **Workaround:** run under `tmux`; use `timeout --foreground`; give each concurrent run its own tmux socket. A helper that waits for prompts must also detect a prompt that is already on screen.
- **Status:** open.

### I-8. Co-pilot mode stops at other stages than documented

- **Symptom:** the documentation names stages 7, 8, 9, 16 and 17. The run stopped at stages 1, 2, 3, 5, 7, 8 and 9, and not at 4 and 6.
- **Evidence:** arm A. Later stages were not reached in that run.
- **Suspected cause:** documentation behind the code. Guess.
- **Workaround:** expect a prompt after most stages.
- **Status:** open.

### I-9. The gate log says "Human chose" whoever answers

- **Symptom:** every record in the intervention log reads "Human chose: approve".
- **Evidence:** all co-pilot runs. In ours an AI agent answered every gate.
- **Suspected cause:** fixed wording.
- **Workaround:** keep your own log of who answered, and do not cite the tool's log as proof of human review.
- **Status:** open.

### I-10. Docker mode mounts caches and passes a token by default

- **Symptom:** as shipped, Docker mode mounts the dataset cache read-write and the Hugging Face cache read-only, and passes `HF_TOKEN` into the container. The figure renderer can fall back to a host subprocess.
- **Evidence:** read in the source before the full runs.
- **Suspected cause:** convenience defaults for benchmark experiments that download data.
- **Workaround:** we patched a local clone (one read-only data mount, no cache mount, no token, host execution raises an error) and put a guard in front of `docker` (`examples/docker-guard.sh`). Probe the result: the container should see no home contents, have no network, and fail to write to the data.
- **Status:** open.

### I-11. The agent route switches off the agent's permission prompts

- **Symptom:** with the ACP provider, the tool starts `acpx` with `--approve-all`. The coding agent would then run any tool call without asking.
- **Evidence:** read before arm A.
- **Suspected cause:** the pipeline is unattended, so prompts would block it.
- **Workaround:** a deny list in the work folder's project settings, which the agent adapter loads (`examples/agent-deny-settings.json`). Confirm with a probe that a shell command and a file write are refused.
- **Status:** open.

### I-12. Prompts exceed small context windows

- **Symptom:** HTTP 400 from the model server.
- **Evidence:** arm B at stage 5 with an 8,192-token context. Full run 1 at stage 13 with a 65,536 context: the prompt was 86,650 tokens. Our notes record stage 13 prompts of up to about 95,000 tokens.
- **Suspected cause:** stage prompts carry the whole shortlist or the whole code base.
- **Workaround:** at least 32,768 tokens for stages 1 to 9; 131,072 for stage 13 on a code base of about 300 KB.
- **Status:** open.

### I-13. A fixed reply cap cuts reasoning models off before any code

- **Symptom:** stage 13 runs for minutes and changes 0 lines.
- **Evidence:** full run 1, local 35B model with thinking on: every reply ended at the cap during the reasoning text.
- **Suspected cause:** the reply length (`max_tokens`) is fixed in the code per call (4,096 or 8,192), not taken from the configuration. Read in the source.
- **Workaround:** turn reasoning off on the server (for llama.cpp, the environment variable `LLAMA_ARG_REASONING=off`). This avoids the cut-off and leads to I-14. Raising the cap in the source was not tried.
- **Status:** open.

### I-14. A file's content is replaced by its name

- **Symptom:** after a refinement round, `main.py` holds the 7-byte text "main.py" and the program crashes.
- **Evidence:** full run 1, local 35B model with thinking off, three rounds out of three.
- **Suspected cause:** the model's reply does not follow the multi-file format the tool parses, and the parser accepts a file name as the file body. Whether the fault lies more with the model's formatting or the parser's tolerance was not separated.
- **Workaround:** none found. The tool kept the earlier code as the final version, so nothing was lost.
- **Status:** open.

### I-15. Generated code with an empty entry point ends the run

- **Symptom:** stage 10 reports done, but `main.py` never calls the analysis. Stage 12 then fails in under a second with zero metrics, and the pipeline stops.
- **Evidence:** full run 2, two attempts with the local 35B model.
- **Suspected cause:** two parts. The model wrote the modules and no working entry point. And a failed stage 12 ends the run: there is no repair turn, and stage 13 is not reached.
- **Workaround:** at the stage 10 output, check that the entry point calls the analysis before letting stage 12 start. Do not approve in the hope of a later repair.
- **Status:** open.

### I-16. A repair pass can leave a marker line in the code

- **Symptom:** a generated module starts with the literal line `filename:methods.py`, which is a syntax error and displaces a `__future__` import.
- **Evidence:** full run 1, stage 12, code written under Claude.
- **Suspected cause:** the file-name marker of the reply format was written into the file body.
- **Workaround:** remove the line. Related to I-14.
- **Status:** open. One observation.

### I-17. An experiment can "succeed" on weak evidence until stage 15

- **Symptom:** stage 12 writes metrics although its run record says "failed"; metrics are scraped from standard output; a seed does not reach the sampler, so replicates are identical.
- **Evidence:** full run 1. Stage 15 (research decision) named these faults itself and chose refine.
- **Suspected cause:** properties of the generated code, with no validity check between stages 12 and 15.
- **Workaround:** treat stage 15 as the only automatic check, and read the stage 12 run record and the code's seeding yourself.
- **Status:** open. Stage 15 catching it is the tool working as intended.

### I-18. Resume and checkpoint behaviour is easy to get wrong

- **Symptom:** a resume regenerates an approved plan, or skips an approved refine loop and enters the next stage.
- **Evidence:** full run 1 (both), full run 2 (checkpoint set by hand before the retry of stage 10).
- **Suspected cause:** resume starts after the stage in `checkpoint.json`. An interrupted refine rollback is not recorded there. Other behaviour read in the source or observed: a reject at a co-pilot gate stops the pipeline and passes no message back to the model; the number of decision pivots is limited to 2.
- **Workaround:** back up `checkpoint.json` and set the stage by hand before a resume; keep copies of approved plans and compare bytes after a resume.
- **Status:** open.

### I-19. Hosted-model limits stall long stages

- **Symptom:** a stage fails or waits for hours.
- **Evidence:** full runs: two session-limit hits in stage 10 of run 1 (the second with a wait of nearly three hours), one in run 2, and one DNS failure.
- **Suspected cause:** a subscription login shared with other work. Stage 10 alone ran 7,552 s.
- **Workaround:** one run at a time per account; retry after the reset; or use a metered key with a budget.
- **Status:** not a fault of the tool.

### I-20. No token accounting on the routes we used

- **Symptom:** token use is unknown for four of five runs.
- **Evidence:** the ACP route reports no counts to the tool; our local server logged none per client. Arm A's counts came from the agent's own transcripts.
- **Suspected cause:** accounting exists for metered APIs only (the tool has a `cost_budget_usd` setting, which we did not exercise).
- **Workaround:** log at the model server, or read the agent's transcripts.
- **Status:** open.
