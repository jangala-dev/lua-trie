# Trie

This library provides a highly flexible Trie (prefix tree) implementation with support for both single-level and multi-level wildcards. The Trie can store key–value pairs and is designed to work with various key formats. Keys can be simple arrays (tables) of tokens, strings that are split by a delimiter, or even fully custom types when you provide your own tokeniser/detokeniser functions.

Wildcards in search prefixes follow these semantics:

- **Single-level Wildcard (`+`):** Matches any token at that level.
- **Multi-level Wildcard (`#`):** Matches all key–value pairs at that level and below. (It must appear only as the final token in a search pattern.)

When inserting keys, any wildcard characters are treated as literal tokens.


## Key Features

- **Insertion:**  
  Insert key–value pairs into the Trie. The key can be provided as a table (array) of tokens, a string (which will be split using a specified delimiter), or a custom type if you supply your own tokeniser.
  
- **Retrieval:**  
  Retrieve a value using an exact key match (wildcards in stored keys are taken literally).
  
- **Deletion:**  
  Remove keys from the Trie. After deletion, the Trie prunes any nodes that become unnecessary.
  
- **Wildcard Matching:**  
  Perform searches using wildcards:
  - Use `+` to match a single token at a given level.
  - Use `#` to match zero or more tokens (only allowed as the last token) and traverse entire subtrees.
  
- **Iteration:**  
  Several iterator functions allow you to traverse matching keys or values:
  - `prefix_iter`, `prefix_keys_iter`, and `prefix_values_iter` yield entries in the entire subtree under a matching prefix.
  - `match_iter`, `match_keys_iter`, and `match_values_iter` return only exact matches according to the wildcard pattern.

- **Customisability:**  
  In addition to built-in support for string or table keys, you can define your own tokeniser/detokeniser functions via `new_custom`.


## Usage

### 1. Initialization

Require the module and create a Trie instance using one of the available constructors:

- **Using Table Keys:**  
  Use this if you want to work directly with arrays of tokens.

  ```lua
  local Trie = require "trie"  -- Adjust the module path as needed
  local trie = Trie.new("+", "#")
  ```

- **Using String Keys with a Custom Delimiter:**  
  When working with strings, use the `new_string` constructor. For example, to split keys on the forward slash (`/`):

  ```lua
  local Trie = require "trie"
  local custom_separator_trie = Trie.new_string("+", "#", "/")
  ```

- **Using Custom Tokenisation:**  
  If you require a different format or complex key structures, provide your own tokeniser and detokeniser:

  ```lua
  local tokeniser = function(key)
      -- Custom tokenisation logic here
      return { key }  -- Example: treat the entire key as one token
  end

  local detokeniser = function(tokens)
      -- Custom detokenisation logic here
      return tokens[1]  -- Example: return the first token
  end

  local custom_trie = Trie.new_custom("+", "#", tokeniser, detokeniser)
  ```

### 2. Insertion

Insert key–value pairs into the Trie. Keys may be strings, tables, or custom types (depending on your Trie instance).

```lua
trie:insert({"a","b", "c", "d"}, "value1")
custom_separator_trie:insert("a/b/c/d", "value3")
```

Wildcards may be used in inserted keys; however, note that when storing keys, wildcards are treated literally. Acceptable usage includes:

```lua
trie:insert({"a", "b", "+", "f", "value2"})  -- '+' is part of the key token
trie:insert({"a", "b", "+", "value3"})   -- also acceptable
```

Incorrect usage (eg. placing a multi-level wildcard in the middle of a key) will result in an error:

```lua
local status, err = trie:insert({"a", "#", "b", "value5"})  -- Error: multi-level wildcard can only appear at the end
```

### 3. Retrieval

Retrieve a value from the Trie using an exact key match:

```lua
local value = trie:retrieve({"a", "b", "c", "d"})  -- Returns "value1" if the key exists
```

### 4. Matching

Use wildcard patterns to match multiple keys or values.

- **Wildcard Matching:**  
  When calling `match()`, the wildcards in the search pattern are interpreted according to the matching rules:
  
  ```lua
  local matches = trie:match("a", "b", "+", "f")  -- Matches entries like {"a", "b", "c", f"}, {"a", "b", "d", "f"}, etc.
  ```
  
- **Using Custom Separators:**  
  For Tries created with `new_string` and a custom delimiter:

  ```lua
  local matches = custom_separator_trie:match("a/b/+/#")
  -- This could match keys like "a/b/c/d" or "a/b/d/e/g/h" depending on the inserted entries.
  ```

- **Iterators:**  
  The module provides various iterators:
  - `prefix_iter(pattern)` – yields key–value pairs under the prefix.
  - `prefix_keys_iter(pattern)` – yields only the keys.
  - `prefix_values_iter(pattern)` – yields only the values.
  - `match_iter(pattern)` – yields only the exact matches (if the end node holds a value).
  - `match_keys_iter(pattern)` and `match_values_iter(pattern)` – similar but yield only keys or values respectively.

### 5. Deletion

Remove a key from the Trie. If the key is found, the corresponding value is cleared and unnecessary nodes are pruned:

```lua
local success, err = trie:delete({"a", "b", "c", "d"})
if success then
    print("Key deleted.")
else
    print("Key not found or error:", err)
end
```

### 6. Edge Cases

This library has been tested with various edge cases including empty keys, very long keys, and keys with special characters. It ensures that token validation is performed so that only strings or numbers are used as tokens, and that wildcards are used correctly.


## Wildcard Details

- **Single-Level Wildcard (`+`):**  
  In search patterns, this wildcard matches any single token. For example, the pattern `{"a", "b", "+", "c"}` will match keys like `{"a", "b", "c", "c"}` or `{"a", "b", "e", "c"`, where the token in the wildcard position can be any valid token.

- **Multi-Level Wildcard (`#`):**  
  This wildcard matches zero or more tokens at the end of a key. For instance, in a string-keyed table, `"ab#"` will match `"abc"`, `"abcd"`, `"abcdefgh"`, etc. Note that in search patterns, `#` must be the final token.

*Remember:*  
- When inserting keys, wildcards are stored as literal characters.  
- When searching, wildcards have their special meaning, allowing for flexible queries.


## LDoc Annotations

The source code is annotated with LDoc tags such as `@tparam` and `@treturn` to help generate detailed documentation. For example, each function documents its parameters and return types, ensuring that users understand how to work with the module.
