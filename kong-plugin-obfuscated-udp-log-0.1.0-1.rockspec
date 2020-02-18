package = "kong-plugin-obfuscated-udp-log"

version = "0.1.0-1"

-- The version '0.1.0' is the source code version, the trailing '1' is the version of this rockspec.
-- whenever the source version changes, the rockspec should be reset to 1. The rockspec version is only
-- updated (incremented) when this file changes, but the source remains the same.

local pluginName = package:match("^kong%-plugin%-(.+)$")  -- "obfuscated-udp-log"
supported_platforms = {"linux", "macosx"}

source = {
  url = "https://gitlab.vipera.com/vipera-cloud/kong-plugin-obfuscated-udp-log",
  tag = "0.1.0"
}

description = {
  summary = "A Kong plugin that allows logging to udp with optional obfuscation of request and response json bodies.",
  license = "MIT"
}

dependencies = {
  "lua >= 5",
	"lua-cjson >= 2.1"
}

build = {
  type = "builtin",
  modules = {
    ["kong.plugins.obfuscated-udp-log.serializer"] = "src/serializer.lua",
    ["kong.plugins.obfuscated-udp-log.obfuscator"] = "src/obfuscator.lua",
    ["kong.plugins.obfuscated-udp-log.handler"] = "src/handler.lua",
    ["kong.plugins.obfuscated-udp-log.schema"] = "src/schema.lua",
    ["kong.plugins.obfuscated-udp-log.json"] = "src/json.lua"
  }
}
