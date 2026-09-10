# B3GET — context for Claude

This file orients any Claude session working in this repo. Read it first.

## What this is

B3GET simulates populations of virtual organisms evolving over generations, modeling life
history trade-offs, fighting ability and aggression, sperm competition, infanticide, and
competition over food and mates. It's a NetLogo agent-based model built by Kristy Crouse
(University of Minnesota), with a companion published methods paper and an ODD protocol
(`docs/B3GET-odd-protocol.pdf`) describing it formally.

Citation: Crouse, K. N., Miller, C. M., & Wilson, M. L. (2019). New approaches to modeling
primate socioecology: Does small female group size BEGET loyal males? *Journal of Human
Evolution*, 137, 102671.

Licensed GPL-2.0, © Regents of the University of Minnesota.

## Related projects (don't conflate these)

- **B3GET** (this repo) — the core model.
- **GenoScope** — a *different* NetLogo model Kristy works on (gene regulation inside a
  cell). Not related to B3GET's organism-population simulation. Lives in its own Dropbox
  folder, not this repo.
- **Quantum Chimp** — funded work (JGI / FormationQ contract) adding quantum-computing-based
  calibration to B3GET. This work happens in the *private* companion repo
  `kncrouse/B3GET-quantum-chimp` (seeded from this repo's history), not here, until Kristy
  decides it's ready to be public. If you're unsure which repo you're in, check the remote:
  `git remote -v`.

## Repository layout

- `code/` — the NetLogo model (`B3GET.nlogox`) and its extension modules (`code/extensions/*.nls`)
- `data/` — starting genotype and population files
- `docs/` — the ODD protocol and other reference documentation
- `results/` — example model output
- `Version history/` — older numbered snapshots (`b3get_v1.2.0`, etc.) kept for reference

## The `.nls` extension files, what each one does

| File | Role |
|---|---|
| `data.nls` | Reading/writing files in `data/`: the metafile (timestamped log of interface button clicks), population CSV import/export, genotype TXT import/export |
| `interface.nls` | User interactions with the model's interface — parameter settings, commands, button clicks |
| `results.nls` | Generating output data during a run, gated by the `OUTPUT-RESULTS` switch; calls into `data.nls` for import/export and `verification.nls` for checks |
| `selection.nls` | Artificial selection on populations, gated by the `SELECTION-ON?` switch |
| `verification.nls` | Runtime verification/assertion checks during simulation; produces a "tape" of verification measurements (requires the profiler running) |
| `gat3s.nls` | One of two genotype-to-decision-vector systems (GAT3S) — more expansive/complex, harder to learn |
| `sta2us.nls` | The other genotype-to-decision-vector system (STA2US) — simpler, the recommended starting point for new users |
| `analysis.nls` | Analysis setup routines for specific research uses (e.g. `thesis-setup`) |

Every `.nls` file and `B3GET.nlogox` carries a UMN copyright/GPL header — keep it intact when
editing.

## How to work in this repo

1. **Never push directly to `master`.** Create a branch, make the change, open a Pull Request.
   Kristy reviews every PR before merging — that review is the whole point of this workflow.
2. **Write the PR description like a lab notebook entry**, not a diff summary: what changed,
   *why* (the scientific or functional reason), and what you checked before calling it done.
   This is the documentation that everything else — papers, reports, future-you — draws from
   later, so don't skimp on it.
3. **Comment new or changed procedures** with a short header: purpose, parameters, what state
   it reads or mutates. NetLogo has no docstring convention, so this repo's convention is a
   `;` comment block immediately above the `to ...` line.
4. **Update `CHANGELOG.md`** as part of the same PR — one line per merged change, in plain
   language, filed under `Unreleased` until a version is cut.
5. **If a change affects model behavior** (new rule, changed parameter, new genotype codon,
   etc.), flag in the PR description that `docs/B3GET-odd-protocol.pdf` may need a matching
   update — don't silently let the protocol drift out of sync with the code.
6. **Validation tooling**: there's an existing Python pipeline (`parse_b3get.py`,
   `edges_b3get.py`, `assemble.py`) that parses this codebase into a structured validation
   table, currently living outside this repo in Kristy's local files. Not yet migrated in —
   ask before assuming it's here.

## Style notes

- `.nlogox` is NetLogo's XML-based format — it diffs poorly in git. Prefer making logic
  changes in the `.nls` extension files (plain text, diffs cleanly) over the main `.nlogox`
  file where possible.
- Kristy reviews as a domain expert, not necessarily a git expert — keep PR descriptions
  readable without assuming familiarity with git jargon.
