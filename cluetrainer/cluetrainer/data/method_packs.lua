-- method_packs.lua
--- All builtin method packs. When several methods exist for the same clue, the one in the earliest pack is used.
---@type MethodPack[]
return {
  require "cluetrainer/data/methods/easy_methods",
  require "cluetrainer/data/methods/medium_methods",
  require "cluetrainer/data/methods/hard_methods",
  require "cluetrainer/data/methods/compass_methods",
  require "cluetrainer/data/methods/scan_methods",
  require "cluetrainer/data/methods/tetracompass_methods",
  -- Parenthesised, because standard Lua's require also returns the file path, which would end up in this list.
  (require "cluetrainer/data/methods/master_methods"),
}
