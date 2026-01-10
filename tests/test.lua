package.path = "../src/?.lua;" .. package.path

local Trie = require "trie"

local function as_set(list)
    local s = {}
    for _, v in ipairs(list) do s[v] = true end
    return s
end

local function collect_each(t, query)
    local out = {}
    t:each(query, function(v) out[#out + 1] = v end)
    return out
end

local function assert_set_eq(actual_list, expected_list, msg)
    local a = as_set(actual_list)
    local e = as_set(expected_list)
    for k in pairs(e) do
        assert(a[k], (msg or "set mismatch") .. ": missing " .. tostring(k))
    end
    for k in pairs(a) do
        assert(e[k], (msg or "set mismatch") .. ": unexpected " .. tostring(k))
    end
end

local function assert_raises(f, msg)
    local ok = pcall(f)
    assert(not ok, msg or "expected error")
end

--------------------------------------------------------------------------------
-- 1. Initialisation
--------------------------------------------------------------------------------
local function test_initialisation()
    assert(Trie.new_pubsub("+", "#"))
    assert(Trie.new_retained("+", "#"))
end

--------------------------------------------------------------------------------
-- 2. Insert / retrieve / delete
--------------------------------------------------------------------------------
local function test_storage()
    local t = Trie.new_retained("+", "#")

    assert(t:insert({"a","b"}, "v1"))
    assert(t:retrieve({"a","b"}) == "v1")
    assert(t:retrieve({"a"}) == nil)

    assert(t:delete({"a","b"}) == true)
    assert(t:delete({"a","b"}) == false)

    assert_raises(function() t:insert({"x"}, nil) end, "nil values must raise")
    assert_raises(function() t:insert({"x", true}, "v") end, "non string/number token must raise")
    assert_raises(function() t:insert("not-a-table", "v") end, "non-table tokens must raise")
end

--------------------------------------------------------------------------------
-- 3. Pubsub engine (stored patterns; literal queries)
--------------------------------------------------------------------------------
local function test_pubsub()
    local topics = Trie.new_pubsub("+", "#")

    topics:insert({"a", "+", "c"}, "sw_pat")
    topics:insert({"a", Trie.literal("+"), "c"}, "lit_pat")
    topics:insert({"a", "#"}, "mw_pat")

    assert_set_eq(collect_each(topics, {"a","b","c"}), {"sw_pat","mw_pat"}, "pubsub a/b/c")
    assert_set_eq(collect_each(topics, {"a","+","c"}), {"sw_pat","lit_pat","mw_pat"}, "pubsub a/+/c")
    assert_set_eq(collect_each(topics, {"a"}), {"mw_pat"}, "pubsub a/# matches a")

    assert_raises(function() topics:insert({"a","#","b"}, "bad") end, "non-terminal # in key must raise")
end

--------------------------------------------------------------------------------
-- 4. Retained engine (literal keys; wildcard queries)
--------------------------------------------------------------------------------
local function test_retained()
    local r = Trie.new_retained("+", "#")

    r:insert({"a"}, "m0")
    r:insert({"a","b","c"}, "m1")
    r:insert({"a","+","c"}, "m2") -- literal '+' in stored key

    assert_set_eq(collect_each(r, {"a","+","c"}), {"m1","m2"}, "retained wildcard +")
    assert_set_eq(collect_each(r, {"a",Trie.literal("+"),"c"}), {"m2"}, "retained literal +")
    assert_set_eq(collect_each(r, {"a","#"}), {"m0","m1","m2"}, "retained # under a")
    assert_set_eq(collect_each(r, {"#"}), {"m0","m1","m2"}, "retained global #")

    assert_raises(function() r:each({"a","#","b"}, function() end) end, "non-terminal # in query must raise")
end

--------------------------------------------------------------------------------
-- Run
--------------------------------------------------------------------------------
test_initialisation()
test_storage()
test_pubsub()
test_retained()

print("All tests passed!")
