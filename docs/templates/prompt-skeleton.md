<!--
Prompt skeleton — the structure every prompt in this library follows. Copy it,
fill the {{placeholders}}, delete what you don't need. These techniques are what
make Claude's output consistent and reliable.
-->
# <Task name>

You are <role/persona>. Your objective is <single, specific goal>.

<context>
  <!-- Wrap every input in its own XML-style tag so the model never confuses
       data with instructions. This is the most reliable structuring technique. -->
  <input_a>{{...}}</input_a>
  <input_b>{{...}}</input_b>
</context>

## Instructions
1. <ordered, explicit step>
2. <ordered, explicit step>

## Constraints
- MUST <hard requirement>
- MUST NOT <guardrail — e.g. don't fabricate, don't change public APIs>

## Output format
<exact shape of the answer: a table, a diff, JSON, paste-ready code, …>

First reason in a `<thinking>` block, then produce the output above.

<!--
Techniques used here:
- Role + single objective         → focus and quality bar
- XML-tagged, delimited context   → no instruction/data confusion
- Numbered instructions           → deterministic steps
- MUST / MUST NOT guardrails      → safety and scope control
- Think-then-answer               → better reasoning on hard tasks
- Explicit output format          → paste-ready, parseable results
- (add a few-shot example when the desired format is subtle)
-->
