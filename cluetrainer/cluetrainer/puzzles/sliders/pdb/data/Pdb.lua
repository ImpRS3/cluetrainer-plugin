local base64 = require "zyklib/base64"
return {
  pdb = base64.decode(require("cluetrainer/puzzles/sliders/pdb/data/mtm_pdb_data"))
}