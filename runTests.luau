--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage");

local IJW = require(ReplicatedStorage.Response.roblox_packages.ijw);
local TestRunner = IJW.TestRunner;

local tests = TestRunner:findTestsFromAncestors({ReplicatedStorage}, ".test");
local results = TestRunner:runTests(tests);

TestRunner:displayResults(results);

return results;