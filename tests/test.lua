package.path = "../src/?.lua;" .. package.path

local Trie = require "trie"

-- 1. Initialisation
local function test_initialisation()
    -- Table-based keys (tokens provided as table)
    local trie_table = Trie.new('+', '#')
    assert(trie_table, "Trie initialisation failed with table keys")

    -- String-based keys with custom separator
    local trie_string = Trie.new_string("+", "#", "/")
    assert(trie_string, "Trie initialisation failed with string keys")
    
    -- Custom keys: here we use a simple custom tokenizer/detokenizer that splits on commas.
    local function custom_tokenize(key)
        local tokens = {}
        for token in key:gmatch("([^,]+)") do
            table.insert(tokens, token)
        end
        return tokens
    end
    local function custom_detokenize(tokens)
        return table.concat(tokens, ",")
    end
    local trie_custom = Trie.new_custom("+", "#", custom_tokenize, custom_detokenize)
    assert(trie_custom, "Trie initialisation failed with custom keys")
end

-- 2. Insertion
local function test_insertion()
    -- Table-based keys
    local trie_table = Trie.new('+', '#')
    assert(trie_table:insert({"a", "b", "c", "d"}, "value1"))
    assert(trie_table:insert({"a", "b", "c", "f"}, "value2"))

    -- String-based keys with custom separator
    local trie_string = Trie.new_string("+", "#", "/")
    assert(trie_string:insert("a/b/c/d", "value3"))
    assert(trie_string:insert("a/b/c/f", "value4"))

    -- Test wildcard insertion for table keys (wildcards are stored literally)
    local status, err = trie_table:insert({"a", "+", "b"}, "value5")
    assert(status == true, "Trie wildcard insertion behaviour unexpected")  -- depending on validation

    -- Custom keys using comma as delimiter
    local function custom_tokenize(key)
        local tokens = {}
        for token in key:gmatch("([^,]+)") do
            table.insert(tokens, token)
        end
        return tokens
    end
    local function custom_detokenize(tokens)
        return table.concat(tokens, ",")
    end
    local trie_custom = Trie.new_custom("+", "#", custom_tokenize, custom_detokenize)
    assert(trie_custom:insert("a,b,c,#", "value6"))
end

-- 3. Retrieval
local function test_retrieval()
    -- Table-based keys
    local trie_table = Trie.new('+', '#')
    trie_table:insert({"a", "b", "c", "d"}, "value1")
    assert(trie_table:retrieve({"a", "b", "c", "d"}) == "value1", "Failed to retrieve value for table-based key")
    assert(trie_table:retrieve({"a", "b", "c"}) == nil, "Retrieved value for non-existent table-based key")
    
    -- Test retrieval with literal wildcard in table key (wildcards are literal in inserted keys)
    trie_table:insert({"a", "b", "+", "f"}, "value2")
    assert(trie_table:retrieve({"a", "b", "+", "f"}) == "value2", "Failed to retrieve value for table key with wildcard")
    
    -- String-based keys
    local trie_string = Trie.new_string("+", "#", "/")
    trie_string:insert("a/b/c/d", "value3")
    assert(trie_string:retrieve("a/b/c/d") == "value3", "Failed to retrieve value for string key")
end

-- 4. Matching
local function test_matching()
    -- Table-based keys
    local trie_table = Trie.new("+", "#")
    trie_table:insert({"a", "b", "c", "d"}, "value1")
    trie_table:insert({"a", "b", "c", "f"}, "value2")
    trie_table:insert({"a", "b", "d", "#"}, "value3")
    
    local matches = trie_table:match({"a", "b", "c", "d"})
    assert(#matches == 1, "Incorrect number of matches returned for table-based keys")
    
    -- String-based keys with wildcards
    local trie_string = Trie.new_string("+", "#", "/")
    trie_string:insert("a/b/c/d", "value1")
    trie_string:insert("a/b/c/f", "value2")
    trie_string:insert("a/b/d/#", "value3")
    
    matches = trie_string:match("a/b/c/+")
    assert(#matches == 2, "Incorrect number of matches for single wildcard in string keys")

    -- Custom keys
    local function custom_tokenize(key)
        local tokens = {}
        for token in key:gmatch("([^,]+)") do
            table.insert(tokens, token)
        end
        return tokens
    end
    local function custom_detokenize(tokens)
        return table.concat(tokens, ",")
    end
    local trie_custom = Trie.new_custom("+", "#", custom_tokenize, custom_detokenize)
    trie_custom:insert("x,y,z", "value_custom")
    matches = trie_custom:match("x,y,z")
    assert(#matches == 1, "Incorrect number of matches for custom key")
end

-- 5. Deletion
local function test_deletion()
    local trie_table = Trie.new('+', '#')
    trie_table:insert({"a", "b", "c", "d"}, "value1")
    trie_table:insert({"a", "b", "c"}, "value2")
    
    assert(trie_table:delete({"a", "b", "c", "d"}), "Failed to delete table-based key - part I")
    assert(trie_table:retrieve({"a", "b", "c", "d"}) == nil, "Failed to delete table-based key")
    assert(trie_table:delete({"a", "b", "c", "d"}) == false, "Incorrectly deleted non-existent table-based key")
    assert(trie_table:retrieve({"a", "b", "c"}) == "value2", "Deleted key that's a prefix of another key")
end

local function test_delete_leaf_node()
    local trie_table = Trie.new('+', '#')
    trie_table:insert({"a", "b", "c", "d"}, "value1")
    trie_table:insert({"a", "b", "c", "d", "e"}, "value2")
    
    assert(trie_table:delete({"a", "b", "c", "d", "e"}), "Failed to delete leaf node")
    assert(trie_table:retrieve({"a", "b", "c", "d", "e"}) == nil, "Failed to delete value of leaf node")
    assert(trie_table:retrieve({"a", "b", "c", "d"}) == "value1", "Affected other keys while deleting leaf node")
end

local function test_delete_internal_node()
    local trie_table = Trie.new('+', '#')
    trie_table:insert({"a", "b", "c", "d"}, "value1")
    trie_table:insert({"a", "b", "c", "d", "e"}, "value2")
    
    assert(trie_table:delete({"a", "b", "c", "d"}), "Failed to delete internal node")
    assert(trie_table:retrieve({"a", "b", "c", "d"}) == nil, "Failed to delete value of internal node")
    assert(trie_table:retrieve({"a", "b", "c", "d", "e"}) == "value2", "Affected other keys while deleting internal node")
end

local function test_delete_with_wildcards()
    local trie_table = Trie.new('+', '#')
    trie_table:insert({"a", "b", "+", "c", "d"}, "value1")
    trie_table:insert({"a", "b", "+", "c", "e"}, "value2")
    
    assert(trie_table:delete({"a", "b", "+", "c", "d"}), "Failed to delete key with wildcard")
    assert(trie_table:retrieve({"a", "b", "+", "c", "d"}) == nil, "Failed to delete value of key with wildcard")
    assert(trie_table:retrieve({"a", "b", "+", "c", "e"}) == "value2", "Affected other keys with wildcards while deleting")
end

local function test_chain_deletion()
    local trie_table = Trie.new('+', '#')
    trie_table:insert({"a"}, "value1")
    trie_table:insert({"a", "b"}, "value2")
    trie_table:insert({"a", "b", "c"}, "value3")
    
    assert(trie_table:delete({"a", "b", "c"}), "Failed to delete leaf node in chain")
    assert(trie_table:delete({"a", "b"}), "Failed to delete internal node in chain")
    assert(trie_table:retrieve({"a"}) == "value1", "Affected root of the chain while deleting chained nodes")
    assert(trie_table:retrieve({"a", "b"}) == nil, "Failed to chain delete correctly")
    assert(trie_table:retrieve({"a", "b", "c"}) == nil, "Failed to chain delete correctly")
end

local function test_delete_non_existent_key()
    local trie_table = Trie.new('+', '#')
    trie_table:insert({"a", "b", "c", "d"}, "value1")
    
    assert(trie_table:delete({"a", "b", "c", "d", "e"}) == false, "Incorrectly deleted non-existent key")
end

-- 6. Edge Cases
local function test_edge_cases()
    -- For string-based keys using new_string
    local trie_string = Trie.new_string("+", "#", "/")
    
    assert(trie_string:insert("", "empty") == true, "Failed to insert empty string key")
    assert(trie_string:retrieve("") == "empty", "Failed to retrieve empty string key")
    
    local long_key = string.rep("a", 1000)
    assert(trie_string:insert(long_key, "value"), "Failed to insert long string key")
    assert(trie_string:retrieve(long_key) == "value", "Failed to retrieve long string key")

    local special_key = "a!@#$%^&*()-_=[]{}|;:',.<>?/~"
    assert(trie_string:insert(special_key, "value"), "Failed to insert key with special characters")
    assert(trie_string:retrieve(special_key) == "value", "Failed to retrieve key with special characters")

    -- -- Test that multi-level wildcard appears only at the end for table-based keys
    -- local trie_table = Trie.new('+', '#')
    -- local status, err = trie_table:insert({"a", "#", "b"}, "value")
    -- assert(status == false, "Accepted multi-level wildcard in the wrong position")
end

-- 8. Overlapping Keys
local function test_overlapping_keys_with_wildcards()
    local trie_string = Trie.new_string("+", "#", "/")
    
    assert(trie_string:insert("a/b/c/d", "value1"))
    assert(trie_string:insert("a/+/c/d", "value2"))
    assert(trie_string:insert("a/b/c/#", "value3"))
    assert(trie_string:insert("a/+/+/#", "value4"))
    
    local matches = trie_string:match("a/b/c/d")
    assert(#matches == 4, "Incorrect number of matches for overlapping keys with wildcards")
end

-- 9. Custom Separator Edge Cases
local function test_custom_separator_edge_cases()
    local trie_string = Trie.new_string("+", "#", "*")
    
    assert(trie_string:insert("a*b*c*d", "value1"))
    local matches = trie_string:match("a*+*c*d")
    assert(#matches == 1, "Incorrect number of matches with custom separator")
    
    assert(trie_string:insert("a*b*+*#", "value2"))
    matches = trie_string:match("a*b*+*d")
    assert(#matches == 2, "Incorrect number of matches with custom separator and wildcards")
end

test_initialisation()
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
