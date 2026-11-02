local window = require("cluetrainer_devtool/DevtoolWindow").open()

function PluginShutdown()
  window:Destroy()
end
