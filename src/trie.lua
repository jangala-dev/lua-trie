--- A Trie (prefix tree) implementation for storing key-value pairs.
-- 
-- Keys can be arrays of strings or numbers, strings splittable by a provided delimiter,
-- or even wholly custom types with user-provided tokeniser and detokeniser functions.
-- 
-- Wildcard matching follows these semantics:
--   * In search prefixes, a single-level wildcard (eg. "+") matches all children at that level.
--   * A multi-level wildcard (eg. "#") matches all key–value pairs at that level and below.
--   * Multi-level wildcards can only be the final element of a key or prefix.
-- 
-- In inserted keys, wildcards are treated literally.
-- 
-- @module trie

-- For older Lua versions:
table.unpack = table.unpack or unpack

local Trie = {}
Trie.__index = Trie

--- Tokenises a key that is already a table.
-- @tparam table key A table of tokens.
-- @treturn table tokens The original key if valid.
-- @treturn nil|string nil, an error message if key is not a table.
local function table_tokenise(key)
    if type(key) ~= 'table' then return nil, "key must be a table of tokens" end
    return key, nil
end

--- Detokenises a table of tokens back into a key.
-- @tparam table tokens The tokens to detokenise.
-- @treturn table tokens The original tokens.
local function table_detokenise(tokens)
    return tokens, nil
end

--- Returns a function that tokenises a string using a provided delimiter.
-- @tparam string delim The delimiter used to split the string.
-- @treturn function A function that converts a string into an array of tokens.
local function string_tokenise(delim)
    return function(key)
        if type(key) ~= 'string' then return nil, "key must be a string" end
        local tokens = {}
        local pattern = (delim == "" and ".") or ("([^" .. delim .. "]+)")
        for token in key:gmatch(pattern) do
            table.insert(tokens, token)
        end
        return tokens, nil
    end
end

--- Returns a function that detokenises an array of tokens into a string using a provided delimiter.
-- @tparam string delim The delimiter to join the tokens.
-- @treturn function A function that converts an array of tokens back into a string.
local function string_detokenise(delim)
    return function(tokens)
        return table.concat(tokens, delim)
    end
end

--- Validates that each token is a string or number and that the multi-level wildcard only appears at the end.
-- @tparam table tokens An array of tokens.
-- @treturn table tokens On success, the validated tokens.
-- @treturn nil|string nil, an error message if validation fails.
function Trie:validate_tokens(tokens)
    for i, part in ipairs(tokens) do
        if type(part) ~= "string" and type(part) ~= "number" then
            return nil, "Token parts must be strings or numbers"
        end
        if part == self.multi_wild and i < #tokens then
            return nil, "Multi-level wildcard can only appear at the end of a key"
        end
    end
    return tokens, nil
end

--- Converts a key into tokens using the tokeniser and validates them.
-- @tparam any key The key to be tokenised.
-- @treturn table tokens The tokenized key.
-- @treturn nil|string nil, an error message if tokenisation fails.
function Trie:_key_to_tokens(key)
    local tokens, err = self:tokenise(key)
    if not tokens then return nil, err end
    return self:validate_tokens(tokens)
end

--- Converts an array of tokens back into the original key form.
-- @tparam table tokens The tokens to detokenise.
-- @treturn any key The detokenised key.
function Trie:_tokens_to_key(tokens)
    return self:detokenise(tokens)
end

--- Inserts a key-value pair into the Trie.
-- @tparam any key The key to insert. This can be a table of tokens, a string, or a custom type.
-- @tparam any value The value associated with the key.
-- @treturn boolean true if insertion is successful.
-- @treturn nil|string nil, an error message if insertion fails.
function Trie:insert(key, value)
    local tokens, err = self:_key_to_tokens(key)
    if not tokens then return nil, err end
    local node = self
    for _, part in ipairs(tokens) do
        node.children[part] = node.children[part] or { children = {}, value = nil }
        node = node.children[part]
    end
    node.value = value
    return true, nil
end

--- Retrieves the value associated with a given key.
-- @tparam any key The key to retrieve.
-- @treturn any value The value stored at the key, or nil if not found.
-- @treturn nil|string nil, an error message if tokenisation fails.
function Trie:retrieve(key)
    local tokens, err = self:_key_to_tokens(key)
    if not tokens then return nil, err end
    local node = self
    for _, part in ipairs(tokens) do
        node = node.children[part]
        if not node then return nil end
    end
    return node.value, nil
end

--- Deletes a key from the Trie.
-- @tparam any key The key to delete.
-- @treturn boolean true if deletion was successful.
-- @treturn nil|string nil, an error message if deletion fails.
function Trie:delete(key)
    local tokens, err = self:_key_to_tokens(key)
    if not tokens then return nil, err end
    local node, stack = self, {}

    for _, part in ipairs(tokens) do
        if not node.children[part] then return false end  -- Key not found
        table.insert(stack, { node = node, part = part })
        node = node.children[part]
    end

    if node.value == nil then return false end  -- Key not found
    node.value = nil  -- Remove value

    -- Prune empty nodes
    for i = #stack, 1, -1 do
        local parent = stack[i].node
        local part = stack[i].part
        if parent.children[part].value == nil and next(parent.children[part].children) == nil then
            parent.children[part] = nil
        else
            break
        end
    end

    return true, nil
end

--- Builds the full key path from a linked list representation.
-- @tparam table linked A linked list representing the path.
-- @treturn table tokens An array of tokens forming the complete key.
local function build_path(linked)
    local arr = {}
    while linked do
        table.insert(arr, 1, linked[2])
        linked = linked[1]
    end
    return arr
end

--- Yields key-value pairs from a subtree starting at the given node.
-- @tparam table node The subtree root node.
-- @tparam any path The current path represented as a linked list.
-- @tparam function yield_fn A function to call with each key and value.
function Trie:_yield_subtree(node, path, yield_fn)
    local sub_stack = { { node = node, path = path } }
    while #sub_stack > 0 do
        local sub = table.remove(sub_stack)
        if sub.node.value ~= nil then
            yield_fn(self:_tokens_to_key(build_path(sub.path)), sub.node.value)
        end
        for child_part, child_node in pairs(sub.node.children) do
            table.insert(sub_stack, { node = child_node, path = { sub.path, child_part } })
        end
    end
end

--- Iteratively searches the Trie for keys matching the wildcard pattern.
-- @tparam table prefix An array of tokens representing the search prefix.
-- @tparam function yield_fn Function that will be called with each matching key and value.
-- @tparam[opt=true] boolean is_prefix_search If true, yields all key–value pairs in the subtree.
function Trie:_iterative_wildcard_search(prefix, yield_fn, is_prefix_search)
    is_prefix_search = is_prefix_search ~= false  -- default to true

    local stack = { { node = self, i = 1, path = nil } }

    --- Helper function to push a new state onto the stack.
    -- @tparam table child_node The child node to push.
    -- @tparam number next_index The next index in the prefix.
    -- @tparam any token The token for the current child.
    -- @tparam any current_path The current path in the traversal.
    local function push(child_node, next_index, token, current_path)
        table.insert(stack, {
            node = child_node,
            i = next_index,
            path = { current_path, token }
        })
    end
    
    while #stack > 0 do
        local state = table.remove(stack)
        local node, i, path = state.node, state.i, state.path

        if i > #prefix then
            if is_prefix_search then
                self:_yield_subtree(node, path, yield_fn)
            elseif node.value ~= nil then
                yield_fn(self:_tokens_to_key(build_path(path)), node.value)
            end
        else
            local part = prefix[i]
            if part == self.multi_wild then
                self:_yield_subtree(node, path, yield_fn)
            else
                if part == self.single_wild then
                    for child_part, child_node in pairs(node.children) do
                        push(child_node, i + 1, child_part, path)
                    end
                else
                    if node.children[part] then
                        push(node.children[part], i + 1, part, path)
                    end
                    if node.children[self.single_wild] then
                        push(node.children[self.single_wild], i + 1, self.single_wild, path)
                    end
                end
                if node.children[self.multi_wild] then
                    self:_yield_subtree(node.children[self.multi_wild], {path, self.multi_wild}, yield_fn)
                end
            end
        end
    end
end

--- Returns an iterator that yields key-value pairs matching the given prefix pattern.
-- @tparam any pattern The search pattern, which can be a table or string.
-- @treturn function An iterator function yielding key and value.
function Trie:prefix_iter(pattern)
    local tokens, err = self:_key_to_tokens(pattern)
    if err then return nil, err end
    return coroutine.wrap(function()
        self:_iterative_wildcard_search(tokens, function(key, value)
            coroutine.yield(key, value)
        end)
    end)
end

--- Returns an iterator that yields keys matching the given prefix pattern.
-- @tparam any pattern The search pattern.
-- @treturn function An iterator function yielding keys.
function Trie:prefix_keys_iter(pattern)
    local tokens, err = self:_key_to_tokens(pattern)
    if err then return nil, err end
    return coroutine.wrap(function()
        self:_iterative_wildcard_search(tokens, function(key, _)
            coroutine.yield(key)
        end)
    end)
end

--- Returns an iterator that yields values matching the given prefix pattern.
-- @tparam any pattern The search pattern.
-- @treturn function An iterator function yielding values.
function Trie:prefix_values_iter(pattern)
    local tokens, err = self:_key_to_tokens(pattern)
    if err then return nil, err end
    return coroutine.wrap(function()
        self:_iterative_wildcard_search(tokens, function(_, value)
            coroutine.yield(value)
        end)
    end)
end

--- Returns an iterator that yields key-value pairs that exactly match the wildcard pattern.
-- @tparam any pattern The pattern to match.
-- @treturn function An iterator function yielding matching key and value pairs.
function Trie:match_iter(pattern)
    local tokens = self:tokenise(pattern) or {}
    return coroutine.wrap(function()
        self:_iterative_wildcard_search(tokens, function(path, value)
            coroutine.yield(path, value)
        end, false)  -- is_prefix_search = false
    end)
end

--- Returns an iterator that yields keys that exactly match the wildcard pattern.
-- @tparam any pattern The pattern to match.
-- @treturn function An iterator function yielding matching keys.
function Trie:match_keys_iter(pattern)
    local tokens = self:tokenise(pattern) or {}
    return coroutine.wrap(function()
        for key, _ in self:match_iter(tokens) do
            coroutine.yield(key)
        end
    end)
end

--- Returns an iterator that yields values that exactly match the wildcard pattern.
-- @tparam any pattern The pattern to match.
-- @treturn function An iterator function yielding matching values.
function Trie:match_values_iter(pattern)
    local tokens = self:tokenise(pattern) or {}
    return coroutine.wrap(function()
        for _, value in self:match_iter(tokens) do
            coroutine.yield(value)
        end
    end)
end

--- Returns all key-value pairs that match the given wildcard pattern.
-- @tparam any pattern The pattern to match.
-- @treturn table matches An array of tables, where each sub-table is of the form {key, value}.
function Trie:match(pattern)
    local matches = {}
    for key, value in self:match_iter(pattern) do
        table.insert(matches, {key, value})
    end
    return matches
end

--- Returns all keys that match the given wildcard pattern.
-- @tparam any pattern The pattern to match.
-- @treturn table keys An array of matching keys.
function Trie:match_keys(pattern)
    local keys = {}
    for key in self:match_keys_iter(pattern) do
        table.insert(keys, key)
    end
    return keys
end

--- Returns all values that match the given wildcard pattern.
-- @tparam any pattern The pattern to match.
-- @treturn table values An array of matching values.
function Trie:match_values(pattern)
    local values = {}
    for _, value in self:match_values_iter(pattern) do
        table.insert(values, value)
    end
    return values
end

--- Creates a new custom Trie instance with user-provided tokeniser and detokeniser functions.
-- @tparam any single_wild The token representing a single-level wildcard.
-- @tparam any multi_wild The token representing a multi-level wildcard.
-- @tparam function tokenise A function that converts a key into an array of tokens.
-- @tparam function detokenise A function that converts an array of tokens back into a key.
-- @treturn Trie A new Trie instance.
local function new_custom(single_wild, multi_wild, tokenise, detokenise)
    assert(type(tokenise) == 'function' and type(detokenise) == 'function', "tokenise and detokenise functions must be provided")
    local self = { children = {}, value = nil }  -- root node
    self.single_wild = single_wild
    self.multi_wild = multi_wild
    self.tokenise = function(self, key) return tokenise(key) end
    self.detokenise = function(self, tokens) return detokenise(tokens) end
    return setmetatable(self, Trie)
end

--- Creates a new Trie instance that uses string keys split by the given delimiter.
-- @tparam any single_wild The token representing a single-level wildcard.
-- @tparam any multi_wild The token representing a multi-level wildcard.
-- @tparam string delim The delimiter used for tokenising string keys.
-- @treturn Trie A new Trie instance.
local function new_string(single_wild, multi_wild, delim)
    assert(type(delim) == 'string', "delimiter string must be provided")
    return new_custom(single_wild, multi_wild, string_tokenise(delim), string_detokenise(delim))
end

--- Creates a new Trie instance that uses table keys.
-- @tparam any single_wild The token representing a single-level wildcard.
-- @tparam any multi_wild The token representing a multi-level wildcard.
-- @treturn Trie A new Trie instance.
local function new(single_wild, multi_wild)
    return new_custom(single_wild, multi_wild, table_tokenise, table_detokenise)
end

return {
    new = new,
    new_string = new_string,
    new_custom = new_custom
}
