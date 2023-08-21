package.path = "../src/?.lua;" .. package.path

local Trie = require "trie"  -- Replace with the path to your Trie module

-- 1. Initialization
local function test_initialization()
    local trie = Trie.new('+', '#')
    assert(trie, "Trie initialization failed with default parameters")

    local custom_separator_trie = Trie.new("+", "#", "/")
    assert(custom_separator_trie, "Trie initialization failed with custom parameters")
end

-- 2. Insertion
local function test_insertion()
    local trie = Trie.new('+', '#')
    assert(trie:insert("abcd", "value1"))
    assert(trie:insert("abcf", "value2"))

    local custom_separator_trie = Trie.new("+", "#", "/")
    assert(custom_separator_trie:insert("a/b/c/d", "value3"))
    assert(custom_separator_trie:insert("a/b/c/f", "value4"))

    -- Test wildcard insertion
    local status, err = trie:insert("a#b", "value5")
    assert(status == false, "Trie accepted wildcard insertion wrongly")

    status, err = custom_separator_trie:insert("a/b+#", "value6")
    assert(status == true, "Trie failed to insert a valid multi-level wildcard")
end

-- 3. Retrieval
local function test_retrieval()
    local trie = Trie.new('+', '#')
    trie:insert("abcd", "value1")

    assert(trie:retrieve("abcd") == "value1", "Failed to retrieve value for key")

    assert(trie:retrieve("abc") == nil, "Retrieved value for non-existent key")

    -- Test wildcards in retrieval
    trie:insert("ab+f", "value2")
    assert(trie:retrieve("ab+f") == "value2", "Failed to retrieve value for key with wildcard")
end

-- 4. Matching
local function test_matching()
    local trie = Trie.new("+", "#", "/")
    trie:insert("a/b/c/d", "value1")
    trie:insert("a/b/c/f", "value2")
    trie:insert("a/b/d/#", "value3")

    local matches = trie:match("a/b/c/d")
    assert(#matches == 1, "Incorrect number of matches returned")
    
    matches = trie:match("a/b/c/+")
    assert(#matches == 2, "Incorrect number of matches for single wildcard")

    matches = trie:match("a/b/+/d")
    assert(#matches == 2, "Incorrect number of matches for mix of wildcards and keys")

    matches = trie:match("a/b/+/#")
    assert(#matches == 3, "Incorrect number of matches for overlapping key patterns")
end

-- 5. Deletion
local function test_deletion()
    local trie = Trie.new('+', '#')
    trie:insert("abcd", "value1")
    trie:insert("abc", "value2")

    assert(trie:delete("abcd"), "Failed to delete key-value pair - part I")
    assert(trie:retrieve("abcd")==nil, "Failed to delete key-value pair")

    assert(trie:delete("abcd") == false, "Incorrectly deleted non-existent key")

    assert(trie:retrieve("abc") == "value2", "Deleted key that's a prefix of another key")
end

local function test_delete_leaf_node()
    local trie = Trie.new('+', '#')
    trie:insert("abcd", "value1")
    trie:insert("abcde", "value2")

    assert(trie:delete("abcd"), "Failed to delete leaf node")
    assert(trie:retrieve("abcd") == nil, "Failed to delete value of leaf node")
    assert(trie:retrieve("abcde") == "value2", "Affected other keys while deleting leaf node")
end

local function test_delete_internal_node()
    local trie = Trie.new('+', '#')
    trie:insert("abcd", "value1")
    trie:insert("abcde", "value2")

    assert(trie:delete("abcde"), "Failed to delete internal node")
    assert(trie:retrieve("abcde") == nil, "Failed to delete value of internal node")
    assert(trie:retrieve("abcd") == "value1", "Affected other keys while deleting internal node")
end

local function test_delete_with_wildcards()
    local trie = Trie.new('+', '#')
    trie:insert("ab+cd", "value1")
    trie:insert("ab+ce", "value2")

    assert(trie:delete("ab+cd"), "Failed to delete key with wildcard")
    assert(trie:retrieve("ab+cd") == nil, "Failed to delete value of key with wildcard")
    assert(trie:retrieve("ab+ce") == "value2", "Affected other keys with wildcards while deleting")
end

local function test_chain_deletion()
    local trie = Trie.new('+', '#')
    trie:insert("a", "value1")
    trie:insert("ab", "value2")
    trie:insert("abc", "value3")

    assert(trie:delete("abc"), "Failed to delete leaf node in chain")
    assert(trie:delete("ab"), "Failed to delete internal node in chain")
    assert(trie:retrieve("a") == "value1", "Affected root of the chain while deleting chained nodes")
    assert(trie:retrieve("ab") == nil, "Failed to chain delete correctly")
    assert(trie:retrieve("abc") == nil, "Failed to chain delete correctly")
end

local function test_delete_non_existent_key()
    local trie = Trie.new('+', '#')
    trie:insert("abcd", "value1")

    assert(trie:delete("abcde") == false, "Incorrectly deleted non-existent key")
end

-- 6. Edge Cases
local function test_edge_cases()
    local trie = Trie.new()
    
    assert(trie:insert("", "empty") == true, "Failed to insert empty key")
    assert(trie:retrieve("") == "empty", "Failed to retrieve empty key")
    
    local long_key = string.rep("a", 1000)
    assert(trie:insert(long_key, "value"), "Failed to insert long key")
    assert(trie:retrieve(long_key) == "value", "Failed to retrieve long key")

    local special_key = "a!@#$%^&*()-_=[]{}|;:',.<>?/~"
    local special_key = "a!@#$%^&*()-_=[]{}|;:',.<>?/~"
    assert(trie:insert(special_key, "value"), "Failed to insert key with special characters")
    assert(trie:retrieve(special_key) == "value", "Failed to retrieve key with special characters")

    local new_trie = Trie.new('+', '#')

    local status, err = new_trie:insert("a#b", "value")
    assert(status == false, "Accepted multi-level wildcard as single-level wildcard")
end

-- 8. Overlapping Keys
local function test_overlapping_keys_with_wildcards()
    local trie = Trie.new("+", "#", "/")
    
    assert(trie:insert("a/b/c/d", "value1"))
    assert(trie:insert("a/+/c/d", "value2"))
    assert(trie:insert("a/b/c/#", "value3"))
    assert(trie:insert("a/+/+/#", "value4"))

    local matches = trie:match("a/b/c/d")
    assert(#matches == 4, "Incorrect number of matches for overlapping keys with wildcards")
end

-- 9. Custom separator
local function test_custom_separator_edge_cases()
    local trie = Trie.new("+", "#", "*")
    
    assert(trie:insert("a*b*c*d", "value1"))
    local matches = trie:match("a*+*c*d")
    assert(#matches == 1, "Incorrect number of matches with custom separator")

    assert(trie:insert("a*b*+*#", "value2"))
    matches = trie:match("a*b*+*d")
    assert(#matches == 2, "Incorrect number of matches with custom separator and wildcards")
end


test_initialization()
test_insertion()
test_retrieval()
test_matching()
test_deletion()
test_edge_cases()
test_delete_leaf_node()
test_delete_internal_node()
test_delete_with_wildcards()
test_chain_deletion()
test_delete_non_existent_key()
test_overlapping_keys_with_wildcards()
test_custom_separator_edge_cases()


print("All tests passed!")