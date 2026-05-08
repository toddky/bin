# Ruby Coding Guidelines

Style rules for all Ruby code.

## Naming

- No abbreviated locals. Use `output` not `out`, `last_line` not `last`, `message` not `msg` in new code.
- Never use the `_path` suffix. Use `_file` or `_dir` for path variables, or the extension as the suffix (`_md`, `_txt`, `_json`). Example: `url_file`, `runtime_dir`, `readme_md`, `config_txt`. Not `url_path` or bare `url`.
- Name generic helpers after the binary or concept they wrap: a tmux pass-through is `tmux(...)`, not `run_tmux(...)` or `tmux_cmd(...)`.
- Generic command wrappers take an explicit array of args, not a variadic splat or a string. Call as `tmux([...])`, not `tmux(...)` or `tmux("...")`. This makes it visually obvious that args are a list and avoids accidental shell-style string interpolation:

  ```ruby
  tmux(['send-keys', '-t', pane, message])
  tmux(['capture-pane', '-t', pane, '-p'])
  ```

  Not:

  ```ruby
  tmux('send-keys', '-t', pane, message)
  tmux("send-keys -t #{pane} #{message}")
  ```

## Control Flow

- Use explicit `return` statements in helpers, even when Ruby's implicit return would do the same thing. Multiple `return [nil, false]` / `return [output, true]` paths are preferred over a single trailing expression.
- Hoist loop-invariant values out of the loop. If a value doesn't change between iterations, compute it once above the loop:

  ```ruby
  messages = result['messages'] || []
  messages.each do |message|
      ...
  end
  ```

  Not:

  ```ruby
  (result['messages'] || []).each do |message|
      ...
  end
  ```
- Hoist nested chains into named locals before they're used. Write:

  ```ruby
  lines = (message['blocks'] || []).dig(0, 'text', 'text').to_s.lines
  first_line = lines.first.to_s.chomp
  ```

  Not:

  ```ruby
  first_line = (message['blocks'] || []).dig(0, 'text', 'text').to_s.lines.first.to_s.chomp
  ```

## Defensive Coercion

Apply coercions at the lookup site, not deferred to a later guard clause.

- `|| []` immediately after a hash lookup that may be nil and is about to be iterated.
- `.to_s` immediately after `.dig(...)` so subsequent string methods don't blow up on nil.
- Drop fallbacks when the caller now guarantees the value. `ENV.fetch('XDG_RUNTIME_DIR')` with no default; let it raise.

## Comments and Section Structure

- Use a small set of standard up-front headers, then describe the steps the code actually performs.
- Standard up-front sections, in this order when present: `ARGUMENTS`, `ENVIRONMENT`, `HELPERS`.
- After those, name each remaining section after the step it performs in the code (`GET MESSAGES`, `SEND MESSAGES`, `POLL`, etc.). If the main section is really small, just call it `MAIN` instead of describing what it does.
- Headers are all caps and no more than two words.
- Keep header order matching reading order.
- Each header is a `#` followed by a space and 78 `=` characters, then the title line, then another `#` and 78 `=` characters:

  ```
  # ==============================================================================
  # ENVIRONMENT
  # ==============================================================================
  ```
