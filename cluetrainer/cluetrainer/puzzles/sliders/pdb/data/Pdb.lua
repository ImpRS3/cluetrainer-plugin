local base64 = require "zyklib/base64"
return {
  pdb = base64.decode(require("cluetrainer/puzzles/sliders/pdb_solver/pdb_raw"))
}