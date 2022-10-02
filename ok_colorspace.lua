--[[
Copyright (c) 2021 Björn Ottosson

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]
--

---@alias srgb number[]
---@alias linear number[]
---@alias lab number[]
---@alias hsv number[]
---@alias hsl number[]
---@alias lc number[]
---@alias st number[]

local sqrt = math.sqrt
local pow = math.pow

---@param x number
---@return number
local function cbrt(x)
    return pow(x, 1 / 3)
end

local unpack = unpack or table.unpack

local k1 = 0.206
local k2 = 0.03
local k3 = (1 + k1) / (1 + k2)

---@param x number
---@return number
local function toe(x)
    return 0.5 * (k3 * x - k1 + sqrt((k3 * x - k1) ^ 2 + 4 * k2 * k3 * x))
end

---@param x number
---@return number
local function toe_inv(x)
    return (x ^ 2 + k1 * x) / (k3 * (x + k2))
end

---@param lc lc
---@return st
local function to_ST(lc)
    local l, c = unpack(lc)
    return { c / l, c / (1 - l) }
end

local M = {}

---@param x number
---@return number
local function _srgb_to_linear(x)
    if x <= 0.04045 then
        return x / 12.92
    end
    return ((x + 0.055) / 1.055) ^ 2.4
end

---@param rgb srgb
---@return linear
function M.srgb_to_linear(rgb)
    local r, g, b = unpack(rgb)
    return { _srgb_to_linear(r), _srgb_to_linear(g), _srgb_to_linear(b) }
end

---@param x number
---@return number
local function _linear_to_srgb(x)
    if x <= 0.0031308 then
        return 12.92 * x
    else
        return 1.055 * x ^ (1 / 2.4) - 0.055
    end
end

---@param linear linear
---@return srgb
function M.linear_to_srgb(linear)
    local r, g, b = unpack(linear)
    return { _linear_to_srgb(r), _linear_to_srgb(g), _linear_to_srgb(b) }
end

---@param rgb srgb
---@return lab
function M.rgb_to_oklab(rgb)
    local r, g, b = unpack(M.srgb_to_linear(rgb))

    local l = 0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b
    local m = 0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b
    local s = 0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b

    local l_ = cbrt(l)
    local m_ = cbrt(m)
    local s_ = cbrt(s)

    return {
        0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_,
        1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_,
        0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_,
    }
end

---@param lab lab
---@return srgb
function M.oklab_to_srgb(lab)
    local L, a, b = unpack(lab)

    local l_ = L + 0.3963377774 * a + 0.2158037573 * b
    local m_ = L - 0.1055613458 * a - 0.0638541728 * b
    local s_ = L - 0.0894841775 * a - 1.2914855480 * b

    local l = l_ ^ 3
    local m = m_ ^ 3
    local s = s_ ^ 3

    return {
        4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
        -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
        -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s,
    }
end

return M
