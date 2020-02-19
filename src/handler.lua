local BasePlugin = require "kong.plugins.base_plugin"
local serializer = require "kong.plugins.obfuscated-udp-log.serializer"
local obfuscator = require "kong.plugins.obfuscated-udp-log.obfuscator"
local JSON = require "kong.plugins.obfuscated-udp-log.json" 
local cjson = require "cjson.safe"

local plugin_name = "obfuscated-udp-log"
local LOG_TAG = "[" .. plugin_name .. "] "

local timer_at = ngx.timer.at
local udp = ngx.socket.udp

local ObfuscatedUdpLogHandler = BasePlugin:extend{}

ObfuscatedUdpLogHandler.PRIORITY = 8
ObfuscatedUdpLogHandler.VERSION = "0.1.0"

local function is_json_body(content_type)
  return content_type and string.find(string.lower(content_type), "application/json", nil, true)
end

local function get_obfuscator_fn(conf)
    local obfuscator_fn = "" 
    if conf.body_in_json_format then
      obfuscator_fn = obfuscator.obfuscate_return_table
    else
      obfuscator_fn = obfuscator.obfuscate
    end
    return obfuscator_fn
end

local function json_encode_safe(data)
  local objectToSerialize = serializer.serialize(ngx)
  local status, value = pcall(JSON.encode, JSON, objectToSerialize)
  if status then
    return value
  else
    ngx.log(ngx.WARN, LOG_TAG, "could not encode to json with good escaping, fallback to safe encoding library: ", value)
    -- Wonky escaping but should work everytime
    local value, errorMsg = cjson.encode(objectToSerialize)
    if not errorMsg then
      return value
    else
      ngx.log(ngx.ERR, LOG_TAG, "could not encode to json even with safe encoding library: ", errorMsg)
      return { obfuscatedUdpLogError=errorMsg }
    end
  end
end

local function log(premature, conf, str)
  if premature then
    return
  end

  local sock = udp()
  sock:settimeout(conf.timeout)

  local ok, err = sock:setpeername(conf.host, conf.port)
  if not ok then
    ngx.log(ngx.ERR, LOG_TAG, "could not connect to ", conf.host, ":", conf.port, ": ", err)
    return
  end

  ok, err = sock:send(str)
  if not ok then
    ngx.log(ngx.ERR, LOG_TAG, "could not send data to ", conf.host, ":", conf.port, ": ", err)
  else
    ngx.log(ngx.DEBUG, LOG_TAG, "sent: ", str)
  end

  ok, err = sock:close()
  if not ok then
    ngx.log(ngx.ERR, LOG_TAG, "could not close ", conf.host, ":", conf.port, ": ", err)
  end
end

function ObfuscatedUdpLogHandler:new()
  ObfuscatedUdpLogHandler.super.new(self, plugin_name)
end

function ObfuscatedUdpLogHandler:access(conf)
  ObfuscatedUdpLogHandler.super.access(self)  

  local content_type = kong.request.get_header("Content-Type")
  ngx.log(ngx.DEBUG, LOG_TAG, "request content-type is: ", content_type)
  if is_json_body(content_type) then
    ngx.req.read_body()
    local body_data = ngx.req.get_body_data()
    -- ngx.log(ngx.DEBUG, LOG_TAG, "req_body is: ", body_data)
    if body_data then
      local obfuscator_fn = get_obfuscator_fn(conf)
      ngx.ctx.req_body = (conf.obfuscate_request_body and #conf.keys_to_obfuscate > 0) and obfuscator_fn(body_data, conf.keys_to_obfuscate, conf.mask) or (conf.body_in_json_format and cjson.decode(body_data) or body_data)
      ngx.log(ngx.DEBUG, LOG_TAG, "obfuscated req_body is: ", ngx.ctx.req_body)
    end
  end
end

function ObfuscatedUdpLogHandler:body_filter(conf)
  ObfuscatedUdpLogHandler.super.body_filter(self)  

  local content_type = ngx.header['Content-Type']
  if is_json_body(content_type) then
    local chunk = ngx.arg[1]
    local eof = ngx.arg[2]
    ngx.ctx.buffered = (ngx.ctx.buffered or "") .. chunk
    if eof then
      ngx.log(ngx.DEBUG, LOG_TAG, "response content-type is: ", content_type)
      -- ngx.log(ngx.DEBUG, LOG_TAG, "resp_body is: ", ngx.ctx.buffered)
      if ngx.ctx.buffered then
        local obfuscator_fn = get_obfuscator_fn(conf)
        ngx.ctx.resp_body = (conf.obfuscate_response_body and #conf.keys_to_obfuscate > 0) and obfuscator_fn(ngx.ctx.buffered, conf.keys_to_obfuscate, conf.mask) or (conf.body_in_json_format and cjson.decode(ngx.ctx.buffered) or ngx.ctx.buffered)
        ngx.ctx.buffered = nil
        ngx.log(ngx.DEBUG, LOG_TAG, "obfuscated resp_body is: ", ngx.ctx.resp_body)
      end
    end
  end
end

function ObfuscatedUdpLogHandler:log(conf)
  ObfuscatedUdpLogHandler.super.log(self)  

  local ok, err = timer_at(0, log, conf, json_encode_safe(serializer.serialize(ngx)))
  if not ok then
    ngx.log(ngx.ERR, LOG_TAG, "could not create timer: ", err)
  end
end

return ObfuscatedUdpLogHandler
