package.path = "../src/?.lua;" .. package.path

local Trie = require 'trie'

local trie = Trie.new("+", "#", "/")

-- Test basic insertion and retrieval
trie:insert("sensor/data/temperature", "value1")
assert(trie:retrieve("sensor/data/temperature") == "value1", "Retrieve failed after insertion")

-- Test basic wildcard ("+") insertion and retrieval
trie:insert("sensor/+/humidity", "value2")
assert(trie:retrieve("sensor/data/humidity") == nil, "Retrieve should not match single level wildcard")
assert(trie:retrieve("sensor/+/humidity") == "value2", "Retrieve failed on single level wildcard")
assert(#trie:match("sensor/data/humidity") == 1, "Single level wildcard match failed")

-- Test wildcard ("#") at the end of a key
trie:insert("sensor/data/#", "value3")
assert(#trie:match("sensor/data/pressure") == 1, "Multi-level wildcard match failed at the end of a key")
assert(trie:retrieve("sensor/data/#") == "value3", "Retrieve failed on multi-level wildcard")

-- Test single wildcard ("+") in the middle of a key
trie:insert("sensor/+/brightness/level", "value4")
assert(#trie:match("sensor/camera/brightness/level") == 1, "Single wildcard in the middle of a key match failed")
assert(trie:retrieve("sensor/+/brightness/level") == "value4", "Single wildcard retrieval failed")
trie:delete("sensor/+/brightness/level")
assert(#trie:match("sensor/camera/brightness/level") == 0, "Single wildcard deletion failed")

-- Test wildcards ("+" and "#") in the same key
trie:insert("sensor/+/motion/#", "value5")
assert(#trie:match("sensor/bedroom/motion/detected") == 1, "Wildcards '+' and '#' in the same key match failed")

-- Test multiple matches
assert(#trie:match("sensor/data/temperature") == 2, "Multiple match failed")

-- Test deletion
trie:delete("sensor/data/temperature")
assert(trie:retrieve("sensor/data/temperature") == nil, "Retrieve failed after deletion")
assert(#trie:match("sensor/data/temperature") == 1, "Match should still succeed after deletion due to multi-level wildcard")
trie:delete("sensor/data/#")
assert(#trie:match("sensor/data/temperature") == 0, "Match should no longer succeed")

print("All tests passed successfully!")
