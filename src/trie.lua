--- Trie implementation with single and multi-level wildcard support.
-- @module Trie

local Trie = {}
Trie.__index = Trie

--- Create a new Trie instance.
-- @tparam string s_wild Single-level wildcard.
-- @tparam string m_wild Multi-level wildcard. It can only be placed at the end of a key.
-- @tparam[opt=""] string separator The separator used to split the key. Default is characterwise splitting.
-- @treturn table Returns a new Trie instance.
local function new(s_wild, m_wild, separator)
    local trie = setmetatable({
        root = {children = {}},
        s_wild = s_wild,
        m_wild = m_wild,
        separator = separator or ""
    }, Trie)
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

--- Insert a key-value pair into the Trie.
-- @tparam string key The key to be inserted.
-- @param value The value associated with the key.
-- @treturn boolean Indicates whether the insertion was successful or not.
-- @treturn[opt] string Error message in case of failure.
function Trie:insert(key, value)
    local node = self.root
    key = split(key, self.separator)
    for i, part in ipairs(key) do
        if part == self.m_wild and i ~= #key then
            return false, "error: multi-level wildcard '"..self.m_wild.."' permitted only at the end of the key."
        end
        node.children[part] = node.children[part] or {children = {}}
        node = node.children[part]
    end
    node.value = value
    return true
end

--- Retrieve a value based on the given key from the Trie.
-- @tparam string key The key to retrieve the value for.
-- @return The value associated with the given key or nil if not found.
function Trie:retrieve(key)
    local node = self.root
    key = split(key, self.separator)
    for i, part in ipairs(key) do
        if not node.children[part] then return nil end
        node = node.children[part]
    end
    return node.value
end

local function collect_all(startNode, startKeypart, matches, separator)
    local stack = {{node=startNode, keypart=startKeypart}}

    while #stack > 0 do
        local current = table.remove(stack)
        local node, keypart = current.node, current.keypart
        
        if node.value then
            table.insert(matches, {['key']=keypart..current.keypart, ['value']=node.value})
        end

        for k, v in pairs(node.children) do
            -- Push child node to the stack
            table.insert(stack, {node=v, keypart=keypart .. k .. separator})
        end
    end
end

--- Matches the given key against the Trie and returns all matches.
-- The function supports single and multi-level wildcards.
-- @tparam string key The key to match.
-- @treturn table A table containing all matching key-value pairs.
function Trie:match(key)
    local matches = {}

    key = split(key, self.separator)
    local stack = {{node=self.root, i=1, keypart=""}}

    while #stack > 0 do
        local current = table.remove(stack)
        local node, i, keypart = current.node, current.i, current.keypart
        local keyNode = node.children[key[i]]
        local s_wildNode = node.children[self.s_wild]
        local m_wildNode = node.children[self.m_wild]

        if key[i] == self.m_wild then
            collect_all(node, keypart, matches, self.separator)
        elseif key[i] == self.s_wild then
            for k, child_node in pairs(node.children) do
                if i == #key and child_node.value then
                    table.insert(matches, {['key']=keypart..k, ['value']=child_node.value})
                elseif i < #key then
                    table.insert(stack, {node=child_node, i=i+1, keypart=keypart..k..self.separator})
                end
            end
        else
            if keyNode then
                if i == #key and keyNode.value then
                    table.insert(matches, {['key']=keypart..key[i], ['value']=keyNode.value})
                end
                table.insert(stack, {node=keyNode, i=i+1, keypart=keypart..key[i]..self.separator})
            end

            if s_wildNode then
                if i == #key and s_wildNode.value then
                    table.insert(matches, {['key']=keypart..self.s_wild, ['value']=s_wildNode.value})
                end
                table.insert(stack, {node=s_wildNode, i=i+1, keypart=keypart..self.s_wild..self.separator})
            end

            if m_wildNode then
                table.insert(matches, {['key']=keypart..self.m_wild, ['value']=m_wildNode.value})
            end
        end

    end

    return matches
end

--- Deletes a key from the Trie.
-- @tparam string key The key to delete.
-- @treturn boolean Indicates whether the deletion was successful or not.
function Trie:delete(key)
    local parentStack = {self.root}
    local node = self.root
    key = split(key, self.separator)
    for i, part in ipairs(key) do
        if not node.children[part] then return false end
        table.insert(parentStack, node.children[part])
        node = node.children[part]
    end
    if not node.value then return false end
    node.value = nil

    for i = #key, 1, -1 do
        if node.value or next(node.children) then break end
        node = parentStack[#parentStack]
        table.remove(parentStack)
        node.children[key[i]] = nil
    end
    return true
end

return {
    new = new
}
