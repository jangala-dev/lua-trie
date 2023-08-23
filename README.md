# Trie Library README

This library provides a Trie implementation with support for single-level (`+`) and multi-level (`#`) wildcards. Wildcards are permitted in both Trie entries (with `insert()`) and in Trie searches (with `match()`). Tries are commonly used for looking up keys efficiently and can be extended to support wildcard queries. The library is designed to be flexible with the delimiter used to split the keys.

## Key Features:
- **Insertion** of key-value pairs into the Trie.
- **Retrieval** of values using exact key matches, treating wildcards as literals.
- **Matching** with wildcards to retrieve multiple values.
- **Deletion** of keys from the Trie, prunes uneeded nodes.
  
## Usage:

### 1. Initialisation:
```lua
local Trie = require "trie"  -- Path to the Trie module

-- Use wildcard characters '+' and '#'
local trie = Trie.new("+", "#")

-- Use custom separator
local custom_separator_trie = Trie.new("+", "#", "/")
```

### 2. Insertion:
Insert a key-value pair into the Trie.
```lua
trie:insert("abcd", "value1")
custom_separator_trie:insert("a/b/c/d", "value3")
```
Wildcards can be used in entries:
- The multi-level wildcard (`#`) can only be used at the end of a key.
- The single-level wildcard (`+`) can be used at any level.

```lua
trie:insert("ab+f", "value2")  -- Acceptable usage of single-level wildcard
trie:insert("ab+", "value3")  -- Another acceptable usage
status, err = trie:insert("a#b", "value5")  -- Will error out due to incorrect wildcard usage
```

### 3. Retrieval:
Retrieve a value from the Trie using an exact key.
```lua
value = trie:retrieve("abcd")  -- Returns "value1"
```

### 4. Matching:
Retrieve values matching a given pattern with potential wildcards.
```lua
matches = trie:match("ab+f")  -- Will match entries like "abcf", "abdf", etc.
matches = custom_separator_trie:match("a/b/+/#")  -- Returns matches for keys like "a/b/c/d", "a/b/d/e", "+/b/e/#", etc.
```
- Use the single-level wildcard (`+`) to match any single level of the key.
- Use the multi-level wildcard (`#`) to match zero or more levels at the end of the key.

### 5. Deletion:
Delete a key from the Trie.
```lua
trie:delete("abcd")
```

### 6. Edge Cases:
The library can handle a variety of edge cases, such as empty keys, very long keys, and keys with special characters. Tests have been written to cover these scenarios.

## Wildcards:
- **Single-Level Wildcard (`+`)**: Matches any single part of a key. For example, "ab+c" could match "abc" or "abcd", but not "abbc" or "abcc".

- **Multi-Level Wildcard (`#`)**: Matches zero or more parts of a key at the end. For example, "ab#" could match "ab", "abc", "abcd", etc.

When using `trie:match()`, both wildcards can be part of the match key. This allows for complex queries to retrieve multiple entries that match the given pattern.
