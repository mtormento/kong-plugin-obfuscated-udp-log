local BasePlugin = require "kong.plugins.base_plugin"
local serializer = require "kong.plugins.obfuscated-udp-log.serializer"
local obfuscator = require "kong.plugins.obfuscated-udp-log.obfuscator"
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

local function json_encode_safe(data)
  local value, errorMsg = cjson.encode(data)
  if not errorMsg then
    return value
  else
    ngx.log(ngx.ERR, LOG_TAG, "could not encode to json: ", errorMsg)
    return { obfuscatedUdpLogError=errorMsg }
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
      ngx.ctx.req_body = (conf.obfuscate_request_body and #conf.keys_to_obfuscate > 0) and obfuscator.obfuscate_return_table(body_data, conf.keys_to_obfuscate, conf.mask) or cjson.decode(body_data)
      if ngx.ctx.req_body then
        ngx.log(ngx.DEBUG, LOG_TAG, "obfuscated req_body is: ", ngx.ctx.req_body)
      end
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
      ngx.ctx.resp_body = (conf.obfuscate_response_body and #conf.keys_to_obfuscate > 0) and obfuscator.obfuscate_return_table(ngx.ctx.buffered, conf.keys_to_obfuscate, conf.mask) or cjson.decode(ngx.ctx.buffered)
      ngx.ctx.buffered = nil
      if ngx.ctx.resp_body then
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
