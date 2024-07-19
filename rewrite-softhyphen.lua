---- rewrite-softhyphen.lua
---- Copyright 2024 Marcel F. Krüger
--
-- This work may be distributed and/or modified under the
-- conditions of the LaTeX Project Public License, either version 1.3
-- of this license or (at your option) any later version.
-- The latest version of this license is in
--   http://www.latex-project.org/lppl.txt
-- and version 1.3 or later is part of all distributions of LaTeX
-- version 2005/12/01 or later.
--
-- This work has the LPPL maintenance status `maintained'.
-- 
-- The Current Maintainer of this work is Marcel F. Krüger
--
-- This work consists of the file rewrite-softhyphen.lua.

local disc_id = node.id'disc'
local explicit_sub = 1
local regular_sub = 3
local properties = node.get_properties_table()
local is_soft_hyphen_prop = 'rewrite-softhyphen.is_soft_hyphen'
local hyphen_char = 0x2D
local soft_hyphen_char = 0xAD

local softhyphen_fonts = setmetatable({}, {__index = function(t, fid)
  local fdir = font.getfont(fid)
  print(fid, fdir, fdir.format, fdir.characters[soft_hyphen_char])
  local result = true
  local format = fdir.format
  result = result and (format == 'opentype' or format == 'truetype')
  local characters = fdir.characters
  result = result and (characters and characters[soft_hyphen_char]) ~= nil
  t[fid] = result
  return result
end})

local function process_pre(head, _context, _dir)
  for disc, sub in node.traverse_id(disc_id, head) do
    if sub == explicit_sub or sub == regular_sub then
      for n, _ch, _f in node.traverse_char(disc.pre) do
        local props = properties[n]
        if not props then
          props = {}
          properties[n] = props
        end
        props[is_soft_hyphen_prop] = true
      end
    end
  end
  return true
end

local function process_post(head, _context, _dir)
  for disc, sub in node.traverse_id(disc_id, head) do
    for n, ch, fid in node.traverse_glyph(disc.pre) do
      local props = properties[n]
      if softhyphen_fonts[fid] and ch == hyphen_char and props and props[is_soft_hyphen_prop] then
        n.char = soft_hyphen_char
        props.glyph_info = nil
      end
    end
  end
  return true
end

luatexbase.add_to_callback('pre_shaping_filter', process_pre, 'rewrite-softhyphen')
luatexbase.add_to_callback('post_shaping_filter', process_post, 'rewrite-softhyphen')
