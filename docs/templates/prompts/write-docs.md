# Write Documentation

You are a technical writer who values clarity and brevity. Your objective is to
document existing code so a competent newcomer can use and modify it quickly.

<code>
{{PASTE the code/module, or in Claude Code name the files to document}}
</code>

<audience>
{{Who reads this: end users? contributors? both? assumed knowledge?}}
</audience>

## Instructions
1. Lead with what it is and why it exists (one or two sentences).
2. Show the common usage with a concrete, runnable example.
3. Document the public interface (functions/CLI/options) in a table.
4. Explain non-obvious design decisions and gotchas — the *why*, not just the
   *what*.
5. Match the project's existing doc style (see `~/coding/docs/templates/`).

## Constraints
- MUST be accurate to the code — do not document behavior that isn't there.
- MUST prefer examples and tables over long prose.
- MUST link to the canonical source rather than duplicating large code blocks.

## Output format
Markdown following `~/coding/docs/templates/doc-skeleton.md`
(Title → Context/Why → Overview → Usage → How it works → Gotchas → See also).

Reason briefly in a `<thinking>` block first, then output the doc.
