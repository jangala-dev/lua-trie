# Trie

A small Trie (prefix tree) for token sequences, supporting optional wildcard matching. The implementation is designed for use-cases such as topic routing and retained-message lookup, where wildcard semantics differ depending on whether wildcards are permitted in stored keys or in queries.

Tokens are provided as a **dense array** (a Lua table with integer keys `1..n` and no `nil` holes). Each token must be a **string** or **number**.

Iteration order is not defined: child traversal uses `pairs()`.

## Concepts

### Tokens

Keys and queries are arrays of tokens:

```lua
{"a", "b", "c"}
{10, 20, 30}
````

Empty token sequences (`{}`) are permitted. An empty key stores a value at the root node.

### Wildcards

Two wildcard symbols are supported when enabled:

* **Single-level wildcard** (default `+`): matches exactly one token at that level.
* **Multi-level wildcard** (default `#`): matches the remainder of the path, including zero tokens. It may appear **only as the final token**.

Wildcard symbols are configurable per instance and may be strings or numbers, but must be different from each other.

### Literal escape

If you need to treat a token that equals the configured wildcard symbol as a literal token (rather than a wildcard), wrap it with `Trie.literal(...)`:

```lua
Trie.literal("+")
Trie.literal("#")
```

This works for both stored keys and queries, depending on the instance mode (see below).

## Modes

The module provides three explicit modes.

### 1) `pubsub` mode (stored patterns, literal queries)

* Stored keys may use wildcard symbols and they are interpreted as wildcards.
* Queries are treated literally (no wildcard interpretation).

This matches publish/subscribe topic routing.

### 2) `retained` mode (literal keys, wildcard queries)

* Stored keys are always literal.
* Queries may use wildcard symbols and they are interpreted as wildcards.

This matches retained-message lookup and similar filtering.

### 3) `literal` mode (exact match only)

* No wildcard semantics.
* Stored keys and queries are treated literally.

## API

### Constructors

```lua
local Trie = require "trie"

local t1 = Trie.new_pubsub(single_sym, multi_sym)    -- defaults: "+", "#"
local t2 = Trie.new_retained(single_sym, multi_sym)  -- defaults: "+", "#"
local t3 = Trie.new_literal()
```

`single_sym` and `multi_sym`, if provided, must be strings or numbers and must be different.

### Methods

All instances provide the same methods.

#### `insert(key_tokens, value) -> true`

Insert or replace the value at `key_tokens`.

* `value` must not be `nil`.
* `key_tokens` must be a dense array of string/number tokens.
* In `pubsub`, wildcard symbols in `key_tokens` have wildcard meaning unless wrapped with `Trie.literal(...)`.
* In `retained` and `literal`, wildcard symbols are treated as ordinary tokens.

#### `retrieve(key_tokens) -> value|nil`

Exact lookup. Returns `nil` if the key does not exist.

Note: in `pubsub`, wildcard symbols in `key_tokens` are compiled as wildcards. If you intend a literal `+` or `#` in the key, wrap that token with `Trie.literal(...)`.

#### `delete(key_tokens) -> boolean`

Deletes the exact key and prunes now-unused nodes. Returns `true` if a value was removed, otherwise `false`.

The same token rules apply as for `retrieve`.

#### `each(query_tokens, visit_value) -> true`

Calls `visit_value(value)` for each matching value.

* `visit_value` must be a function.
* Matching behaviour depends on mode:

  * `pubsub`: `query_tokens` are literal; stored wildcard patterns may match them.
  * `retained`: stored keys are literal; `query_tokens` may include wildcards.
  * `literal`: exact match only (at most one call to `visit_value`).

No ordering guarantee is provided.

## Examples

### Pub/sub routing (stored patterns)

```lua
local Trie = require "trie"
local topics = Trie.new_pubsub("+", "#")

topics:insert({"a", "+", "c"}, "single")
topics:insert({"a", "#"}, "multi")
topics:insert({"a", Trie.literal("+"), "c"}, "literal-plus")

local out = {}
topics:each({"a", "b", "c"}, function(v) out[#out+1] = v end)
-- out contains: "single", "multi"

out = {}
topics:each({"a", "+", "c"}, function(v) out[#out+1] = v end)
-- out contains: "single", "multi", "literal-plus"
```

### Retained lookup (wildcard queries)

```lua
local Trie = require "trie"
local r = Trie.new_retained("+", "#")

r:insert({"a"}, "v0")
r:insert({"a", "b", "c"}, "v1")
r:insert({"a", "+", "c"}, "v2")  -- literal '+' in stored key

local out = {}
r:each({"a", "+", "c"}, function(v) out[#out+1] = v end)
-- out contains: "v1", "v2"

out = {}
r:each({"a", Trie.literal("+"), "c"}, function(v) out[#out+1] = v end)
-- out contains: "v2"

out = {}
r:each({"a", "#"}, function(v) out[#out+1] = v end)
-- out contains: "v0", "v1", "v2"
```

### Literal mode (exact match)

```lua
local Trie = require "trie"
local t = Trie.new_literal()

t:insert({"a", "+", "c"}, "v")
assert(t:retrieve({"a", "+", "c"}) == "v")

local seen = 0
t:each({"a", "+", "c"}, function(_) seen = seen + 1 end)
assert(seen == 1)
```

## Validation and errors

The implementation validates inputs and raises errors for:

* non-table token inputs
* token arrays that are not dense `1..n`
* token parts that are not strings or numbers
* `nil` values in `insert`
* use of multi-level wildcard (`#` by default) anywhere other than the final token in contexts where wildcards are enabled:

  * in stored keys for `pubsub`
  * in queries for `retained`

## Notes

* The trie stores values only at complete keys; it does not return intermediate nodes unless a value was stored there.
* Iteration order is undefined.
* `each` is callback-based and may visit zero, one, or many values depending on mode and query.
