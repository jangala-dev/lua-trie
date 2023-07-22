local Trie = {}
Trie.__index = Trie

--- Function to create a new Trie.
-- @param singleWildcard The character to use as a single level wildcard. Default is '+'.
-- @param multiWildcard The character to use as a multi-level wildcard. Default is '#'.
-- @param separator The character to use as the key separator. Default is empty string "" (split by characters).
-- @return Returns a new Trie object.
-- @function new
local function new(singleWildcard, multiWildcard, separator)
    local trie = setmetatable({root = {}, singleWildcard = singleWildcard or '+', multiWildcard = multiWildcard or '#', separator = separator or ""}, Trie)
    return trie
end

local function split(str, separator)
    local result = {}
    local pattern = separator=="" and "." or "[^"..separator.."]+"
    for part in string.gmatch(str, pattern) do
        table.insert(result, part)
    end
    return result
end

--- Method to insert a new key/value in the Trie.
-- @param key A string representing the key. The string will be split by the separator defined at Trie initialization.
-- @param value The value to be inserted into the Trie.
-- @function Trie:insert
function Trie:insert(key, value)
    local node = self.root
    key = split(key, self.separator)
    for i, part in ipairs(key) do
        if part == self.multiWildcard and i ~= #key then
            error("Multi-level wildcard '"..self.multiWildcard.."' permitted only at the end of the key.")
        end
        node[part] = node[part] or setmetatable({}, Trie)
        node = node[part]
    end
    node.value = value
end

--- Method to retrieve the value associated with a key from the Trie. It accepts wildcards.
-- @param key A string representing the key. The string will be split by the separator defined at Trie initialization.
-- @return Returns the value associated with the key if it exists in the Trie.
-- @function Trie:retrieve
function Trie:retrieve(key)
    local node = self.root
    key = split(key, self.separator)
    for i, part in ipairs(key) do
        if not node[part] then return nil end
        node = node[part]
    end
    return node.value
end

--- Method to match keys in the Trie. It does not accept wildcards.
-- @param key A string representing the key. The string will be split by the separator defined at Trie initialization.
-- @return Returns a table of all values that match the key.
-- @function Trie:match
function Trie:match(key)
    local matches = {}
    key = split(key, self.separator)
    local function _match(node, i, keypart)
        for part, child in pairs(node) do
            if part == key[i] or part == self.singleWildcard then
                if i == #key and child.value then
                    table.insert(matches, child.value)
                end
                _match(child, i + 1, keypart..part..self.separator)
            end
        end
        if node[self.multiWildcard] then
            table.insert(matches, node[self.multiWildcard].value)
        end
    end
    _match(self.root, 1, "")
    return matches
end

--- Method to delete the value associated with a key from the Trie. If it's a leaf node, it will also delete all parent empty nodes.
-- @param key A string representing the key. The string will be split by the separator defined at Trie initialization.
-- @function Trie:delete
function Trie:delete(key)
    local parentStack = {self.root}
    local node = self.root
    key = split(key, self.separator)
    for i, part in ipairs(key) do
        if not node[part] then return end
        table.insert(parentStack, node)
        node = node[part]
    end
    if not node.value then return end
    node.value = nil
    for i = #key, 1, -1 do
        if next(node) then break end
        node = parentStack[#parentStack]
        table.remove(parentStack)
        node[key[i]] = nil
    end
end

return {
    new = new
}
