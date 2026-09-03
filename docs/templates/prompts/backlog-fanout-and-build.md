# Generate a feature backlog, then build the top N (multi-agent)

You are the orchestrator of a two-phase multi-agent run. Your objective: produce
a large ranked feature backlog for a codebase, then build the best N features and
ship them — verifying every gate yourself. Requires explicit user opt-in to
multi-agent orchestration (a Workflow is billable + spawns many agents).

<context>
  <codebase>{{Repo + stack. Scout it first: list views/modules/components,
  read package.json scripts + key types. Feed this real surface to generators so
  ideas are grounded, not generic.}}</codebase>
  <scope>{{How many to GENERATE (default ~500) and BUILD (default top 10).
  Confirm both with the user before firing.}}</scope>
  <verify_cmds>{{e.g. tsc -b · vitest run · eslint <files> · build}}</verify_cmds>
</context>

## Instructions
1. Scout the codebase inline (cheap) to ground generation.
2. **Generation Workflow:** ~10 category agents × ~55 ideas each, JSON schema
   `{title, desc, value 1-5, effort S/M/L, risk low/med/high}`. `parallel()`
   barrier → dedup by normalized title in JS → rank (value desc, effort S<M<L,
   risk low<med<high). A selector agent picks the top N buildable-now
   (low-risk, additive, unit-testable) with a `plan` naming likely files.
3. Write the backlog doc (category counts + top-N table + full list). APPEND a
   pointer to the repo's feature index — never overwrite.
4. Verify plan assumptions: grep that every referenced function/type exists.
5. **Build Workflow:** partition the N features by DISJOINT file ownership (no
   two agents share a file; overlapping helpers go in NEW files). `parallel()`,
   schema-validated summaries, each agent reads-before-edit + adds tests.
6. Verify yourself — re-run typecheck / tests / lint(touched files) / build.
   Confirm `git status` matches the expected disjoint file set.
7. Ship: feature commit + doc commit, branch + PR, then log the session.

## Constraints
- MUST get explicit opt-in before any Workflow; confirm generate + build counts.
- MUST partition build agents by disjoint files (parallel edits to one file
  corrupt each other).
- MUST re-run all gates yourself — "all green" from an agent is a claim, re-prove it.
- MUST keep changes additive/back-compat; MUST NOT add backend/deps/network.
- MUST append to docs, not overwrite; absolute dates.

## Output format
A ranked backlog doc, top-N built behind green gates, a PR, and a worklog entry.

First reason in a `<thinking>` block (partition plan + which gates), then drive
the workflows.

<!--
Techniques: role + single objective · XML-tagged context · numbered steps ·
MUST/MUST NOT guardrails · think-then-answer · explicit output. Fan-out beats
one-shot (diverse lenses, no self-anchoring); schema output is parseable;
disjoint-file partitioning makes parallel builds conflict-free; orchestrator-side
verification catches optimistic agent claims.
-->
