---@class ct.PatchNotes.ListItem
---@field text string
---@field children ct.PatchNotes.ListItem[]?

---@class ct.PatchNotes.Paragraph
---@field type "paragraph"
---@field text string

---@class ct.PatchNotes.Header
---@field type "header"
---@field text string

---@class ct.PatchNotes.List
---@field type "list"
---@field items ct.PatchNotes.ListItem[]

---@class ct.PatchNotes.Patch
---@field version string
---@field date string Release date in YYYY-MM-DD format.
---@field name string
---@field content (ct.PatchNotes.Paragraph|ct.PatchNotes.Header|ct.PatchNotes.List)[]

---@param text string
---@return ct.PatchNotes.Header
local function header(text)
  return { type = "header", text = text }
end

---@param text string
---@return ct.PatchNotes.Paragraph
local function paragraph(text)
  return { type = "paragraph", text = text }
end

---@param items ct.PatchNotes.ListItem[]
---@return ct.PatchNotes.List
local function list(items)
  return { type = "list", items = items }
end

---@param text string
---@param children ct.PatchNotes.ListItem[]?
---@return ct.PatchNotes.ListItem
local function item(text, children)
  return { text = text, children = children }
end

-- List releases from oldest to newest, including an entry for current_version.
-- Version strings are compared exactly; on a version change, entries after the
-- last opened release are shown. If it is absent or later, all entries through
-- the current release are shown.
-- Use header "Section", paragraph "Text", and list { item "Change" } in content.
return {
  -- Keep this in sync with the plugin manifest versions.
  current_version = "83",
  messages = {
    first_start =
    "Thanks for installing and Welcome to Clue Trainer! Clue Trainer is continuously iterated on, and this window will show whenever the plugin has received an update to keep you informed about the latest changes and improvements.",
    update =
    "Clue Trainer has been updated. If you enjoy Clue Trainer, please consider supporting continuous development at Ko-fi.com/zyklopmarco.<br><br>You can also join the Clue Chasers discord to leave praise and criticism, report issues, request features, get support or just come by and say hi in the #clue-trainer channel.",
    manual =
    "If you enjoy Clue Trainer, please consider supporting continuous development at Ko-fi.com/zyklopmarco.<br><br>You can also join the Clue Chasers discord to leave praise and criticism, report issues, request features, get support or just come by and say hi in the #clue-trainer channel.",
  },
  ---@type ct.PatchNotes.Patch[]
  patches = {
    {
      version = "84",
      date = "2026-11-20",
      name = "Bugfixes",
      content = {
        list {
          item "Fixed a bug that caused clue detection to stop working after a search clue.",
          item "Added improved error resiliency for several types of failures.",
          item "Optimized map performance in several to reduce issues with the plugin not enabling properly."
        },
      },
    }, {
    version = "83",
    date = "2026-11-19",
    name = "Clue Trainer (Plugin API)",
    content = {
      header "About this version",
      paragraph "This is the initial release of Clue Trainer for the official RuneScape Client plugin API. You may wonder why this version is labelled as version 83. Clue Trainer has a long history as a plugin for the Alt 1 toolkit, and this version is a direct continuation of that lineage, equipped with all the learnings from more than three years of development.",
      paragraph "You will notice that this version is still rough around the edges. The will be visual issues, glitches, suboptimal UX, and missing features. Just like with the previous 82 versions for the Alt 1 toolkit, we will continue to iterate on Clue Trainer to make it better than ever. Please feel free to report any feedback you have in the Clue Chasers discord, the Mod.io page, or directly on the plugin's issue tracker at Codeberg.",
      header "Patch Notes",
      list {
        item "Ported Clue Trainer to the official RuneScape Client plugin API.",
        item "Added in-game highlighting of dig spots, npcs, containers, and emote areas.",
        item "Added in-game rendering of paths as threedimensional shapes.",
        item "Automated detection of fairy ring favourites.",
        item "Eliminated issues with misreads of interface puzzles and compass angles.",
        item "Clue Trainer now supports any interface scaling.",
        item "Compass clues now automatically detect your position and the compass angle, no manual input required."
      },
    },
  },
  },
}
