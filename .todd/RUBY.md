# Ruby Coding Guidelines

Style rules for all Ruby code.

## Naming

- No abbreviated locals. Use `output` not `out`, `last_line` not `last`, `message` not `msg` in new code.
- Never use the `_path` suffix. Use `_file` or `_dir` for path variables, or the extension as the suffix (`_md`, `_txt`, `_json`). Example: `url_file`, `runtime_dir`, `readme_md`, `config_txt`. Not `url_path` or bare `url`.
- Name generic helpers after the binary or concept they wrap: a tmux pass-through is `tmux(...)`, not `run_tmux(...)` or `tmux_cmd(...)`.

## Generic Wrappers

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

  Same for a guarded collection before iterating. Write:

  ```ruby
  rows = logs.is_a?(Array) ? logs : []
  rows.each do |row|
      ...
  end
  ```

  Not:

  ```ruby
  (logs.is_a?(Array) ? logs : []).each do |row|
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

## Arrays Over Concatenation

When building a string from multiple parts (query params, command flags, CSV fields, etc.), collect the parts in an array with `.append` and join. Do not concatenate with `\` line continuations or `+`, and don't build the array as one giant literal.

```ruby
params = []
params.append("target_branch=#{target_encoded}")
params.append('state=all')
params.append('per_page=100')
params.append("page=#{page}")
endpoint = "projects/#{PROJECT_ID}/merge_requests?#{params.join('&')}"

flags = []
flags.append('-v')
flags.append('-u', username)
flags.append('--timeout', timeout.to_s)
result = run(flags.join(' '))
```

Not:

```ruby
endpoint = "projects/#{PROJECT_ID}/merge_requests" \
           "?target_branch=#{target_encoded}" \
           "&state=all"
```

## Defensive Defaults

Apply defaults and conversions at the lookup site, not deferred to a later guard clause.

- `|| []` immediately after a hash lookup that may be nil and is about to be iterated.
- `.to_s` immediately after `.dig(...)` so subsequent string methods don't blow up on nil.
- Drop fallbacks when the caller now guarantees the value. `ENV.fetch('XDG_RUNTIME_DIR')` with no default; let it raise.
- Default and convert at *each* level that can be nil, not once at the end. When chaining lookups, every type transition gets its own guard:

  ```ruby
  lines = (message['blocks'] || []).dig(0, 'text', 'text').to_s.lines
  ```

  `|| []` at the array level so `.dig` works; `.to_s` at the string level so `.lines` works. One guard at the end is not enough.

## No Aligned Continuations

Don't align continuation lines under a receiver. Break long chains into separate statements with named locals.

```ruby
grouped = entries.group_by { |entry| entry.kind }
counts = grouped.transform_values(&:length)
```

Not:

```ruby
counts = entries.group_by { |entry| entry.kind }
                .transform_values(&:length)
```

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
