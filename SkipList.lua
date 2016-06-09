-- Based on https://love2d.org/wiki/Skip_list
--[[------------------------------------------------------------------
--The MIT License
-- 
-- Original Python version Copyright (c) 2009 Raymond Hettinger 
-- see http://code.activestate.com/recipes/576930/
--  
-- Lua conversion + extensions Copyright (c) 2010 Pierre-Yves Gérardy
--   
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--    
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--     
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.
--]]

local log, floor, random = math.log, math.floor, math.random

-- Nodal structure: {value(any unique), size(number), next(list or nodes), width(list of numbers)}
local _size = setmetatable( {}, {__mode = 'k'} )
local _head = setmetatable( {}, {__mode = 'k'} )
local _maxlevel = setmetatable( {}, {__mode = 'k'} )
local _first = setmetatable( {}, {__mode = 'k'} )
local _values = setmetatable( {}, {__mode = 'k'} )

local Nil = {{}, 0, {}, {}}

local function remove( self, k )
	if _values[self][k] ~= nil then
		local node, maxlevel, chain = _head[self], _maxlevel[self], {}
		for level = maxlevel, 1, -1 do
			while node[3][level] ~= Nil and node[3][level][1] < k do
				node = node[3][level] 
			end
			chain[level] = node
		end

		local nodelevel = chain[1][3][1][2]
		for level = 1, nodelevel do
			prevnode = chain[level]
			prevnode[4][level] = prevnode[4][level] + prevnode[3][level][4][level] - 1
			prevnode[3][level] = prevnode[3][level][3][level]
		end
		for level = nodelevel+1, maxlevel do
			chain[level][4][level] = chain[level][4][level] - 1
		end
		_size[self] = _size[self] - 1
		_values[self][k] = nil
	end
end

local function insert( self, k, v )
	if _values[self][k] == nil then
		local node, maxlevel = _head[self], _maxlevel[self]
		local chain, levelsteps = {}, {}
		for i = 1, maxlevel do 
			levelsteps[i] = 0 
		end
		for level = maxlevel, 1, -1 do
			while node[3][level] ~= Nil and node[3][level][1] <= k do
				levelsteps[level] = ( levelsteps[level] or 0 ) + node[4][level]
				node = node[3][level]
			end
			chain[level] = node
		end

		local nodelevel = -floor( log( random(), 2 ))
		nodelevel = nodelevel > maxlevel and maxlevel or nodelevel
		local newNode = {k, nodelevel, {}, {}, v}
		local steps, prevnode = 0
		for level = 1, nodelevel do
			prevnode = chain[level]
			newNode[3][level] = prevnode[3][level]
			prevnode[3][level] = newNode
			newNode[4][level] = prevnode[4][level] - steps
			prevnode[4][level] = steps + 1
			steps = steps + levelsteps[level]
		end
		for level = nodelevel + 1, maxlevel do
			chain[level][4][level] = chain[level][4][level] + 1
		end
		_size[self] = _size[self] + 1
	end
	
	_values[self][k] = v
end

local SkipListMt = {
	__index = function( self, k )
		return _values[self][k]
	end,

	__newindex = function( self, k, v )
		if v == nil then
			remove( self, k )	
		else
			insert( self, k, v )
		end
	end,
	
	__ipairs = function ( self )
		return function( _, k )
			k = k or 0
			local v = self[k+1]
			if v then
				return k+1, v
			end
    end
  end,
  
	__pairs = function( self )
		local node, count, size, values = _head[self], 0, _size[self], _values[self]
		return function()
			if count < size then      
				node, count = node[3][1], count + 1
				return node[1], values[node[1]]
			end
    end
  end,
  
  __len = function( self )
		return _size[self]
	end,
}

local SkipList = {}

function SkipList.new( tbl_, expectedsize_ )
	local self = setmetatable( {}, SkipListMt )
	local expectedsize = expectedsize_ or 16
	local maxlevel = floor( log( expectedsize, 2 ))
	local head = {{}, maxlevel, {}, {}}
	for i = 1, maxlevel do
		head[3][i] = Nil
		head[4][i] = 1
	end

	_size[self] = 0
	_head[self] = head
	_maxlevel[self] = maxlevel
	_first[self] = first
	_values[self] = {}

	if tbl_ then
		for k, v in pairs( tbl_ ) do
			self[k] = v
		end
	end

	return self
end

return setmetatable( SkipList, {
	__call = function( _, tbl, expectedsize )
		return SkipList.new( tbl, expectedsize )
	end
})
