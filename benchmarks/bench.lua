package.path = "../src/?.lua;" .. package.path

local Trie = require "trie"

local N = 100000  -- Number of entries for benchmarking

-- Function to generate random array key
local function random_key(length)
    local res = {}
    for i = 1, length do
        res[i] = string.char(math.random(97, 122))
    end
    return res
end

-- Pre-generate dataset of random strings
local function generate_dataset()
    local dataset = {}
    for i = 1, N do
        table.insert(dataset, random_key(5))
    end
    return dataset
end

local keys = generate_dataset()

-- Benchmarking insertion
local function benchmark_insertion(trie)
    local start_time = os.clock()

    for i, key in ipairs(keys) do
        trie:insert(key, "value" .. i)
    end

    local end_time = os.clock()
    print("Time for insertion of " .. N .. " entries: " .. (end_time - start_time)/N .. " seconds per op")
end

-- Benchmarking retrieval (assuming all keys are known)
local function benchmark_retrieval(trie)
    local start_time = os.clock()

    for _, key in ipairs(keys) do
        trie:retrieve(key)
    end

    local end_time = os.clock()
    print("Time for retrieval of " .. N .. " entries: " .. (end_time - start_time)/N .. " seconds per op")
end

-- Benchmarking deletion (assuming all keys are known)
local function benchmark_deletion(trie)
    local start_time = os.clock()

    for _, key in ipairs(keys) do
        trie:delete(key)
    end

    local end_time = os.clock()
    print("Time for deletion of " .. N .. " entries: " .. (end_time - start_time)/N .. " seconds per op")
end

-- Benchmarking matching
local function benchmark_matching(trie)
    local start_time = os.clock()

    for _, key in ipairs(keys) do
        trie:match(key)
    end

    local end_time = os.clock()
    print("Time for matching " .. N .. " keys: " .. (end_time - start_time)/N .. " seconds per op")
end

-- Main benchmarking function
local function benchmark()
    local trie = Trie.new('+', '#')

    benchmark_insertion(trie)
    benchmark_retrieval(trie)
    benchmark_matching(trie)
    benchmark_deletion(trie)
end

benchmark()
