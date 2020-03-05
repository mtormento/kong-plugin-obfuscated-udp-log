local BasePlugin = require "kong.plugins.base_plugin"
local serializer = require "kong.plugins.obfuscated-udp-log.serializer"
local obfuscator = require "kong.plugins.obfuscated-udp-log.obfuscator"
local cjson = require "cjson"

local plugin_name = "obfuscated-udp-log"
local LOG_TAG = "[" .. plugin_name .. "] "

local timer_at = ngx.timer.at
local udp = ngx.socket.udp

local ObfuscatedUdpLogHandler = BasePlugin:extend{}

ObfuscatedUdpLogHandler.PRIORITY = 8
ObfuscatedUdpLogHandler.VERSION = "0.1.1"

local function is_json_body(content_type)
  return content_type and string.find(string.lower(content_type), "application/json", nil, true)
end

local function json_encode_safe(data)
  local status, value = pcall(cjson.encode, data)
  if status then
    return value
  else
    ngx.log(ngx.ERR, LOG_TAG, "could not encode to json: ", value)
    return cjson.encode({
      obfuscatedUdpLog = { 
        errorCode = "ENCODE_ERROR",
        errorMsg = value,
        originalData = data
      }
    })
  end
end

local function handle_data(data, obfuscate, keys_to_obfuscate, mask, original_body_on_error)
  local value, status
  if obfuscate and #keys_to_obfuscate > 0 then
    status, value = pcall(obfuscator.obfuscate_return_table, data, keys_to_obfuscate, mask)
  else
    status, value = pcall(cjson.decode, data)
  end
  if status then
    return value
  else
    ngx.log(ngx.ERR, LOG_TAG, "could not decode json: ", value)
    return {
      obfuscatedUdpLog = { 
        errorCode = "DECODE_ERROR",
        errorMsg = value,
        originalBody = original_body_on_error and data or "original_body_on_error is disabled"
      }
    }
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
    if body_data ~= nil then
      ngx.ctx.req_body = handle_data(body_data, conf.obfuscate_request_body, conf.keys_to_obfuscate, conf.mask, conf.original_body_on_error)
--      ngx.log(ngx.DEBUG, LOG_TAG, "final request body is: ", cjson.encode(ngx.ctx.req_body))
    else
      ngx.ctx.req_body = {
        obfuscatedUdpLog = { 
          noBody = true
        }
      }
    end
  else
    ngx.ctx.req_body = {
      obfuscatedUdpLog = { 
        notJson = true
      }
    }
  end
end

function ObfuscatedUdpLogHandler:header_filter(conf)
  ObfuscatedUdpLogHandler.super.header_filter(self)  

  local content_type = kong.response.get_header('Content-Type')
  if is_json_body(content_type) then
    -- Placeholder in case body_filter is not invoked because there's no body
    ngx.ctx.resp_body = {
      obfuscatedUdpLog = { 
        noBody = true
      }
    }
  else
    ngx.ctx.resp_body = {
      obfuscatedUdpLog = { 
        notJson = true
      }
    }
  end
end

function ObfuscatedUdpLogHandler:body_filter(conf)
  ObfuscatedUdpLogHandler.super.body_filter(self)  

  if not ngx.ctx.resp_body.obfuscatedUdpLog.notJson then
    local chunk = ngx.arg[1]
    local eof = ngx.arg[2]
    ngx.ctx.buffered = (ngx.ctx.buffered or "") .. chunk
    if eof then
      ngx.log(ngx.DEBUG, LOG_TAG, "response content-type is: ", content_type)
      -- ngx.log(ngx.DEBUG, LOG_TAG, "resp_body is: ", ngx.ctx.buffered)
      if ngx.ctx.buffered ~= "" then
        ngx.ctx.resp_body = handle_data(ngx.ctx.buffered, conf.obfuscate_response_body, conf.keys_to_obfuscate, conf.mask, conf.original_body_on_error)
        ngx.ctx.buffered = nil
--        ngx.log(ngx.DEBUG, LOG_TAG, "final response body is: ", cjson.encode(ngx.ctx.resp_body))
      else
        ngx.ctx.resp_body = {
          obfuscatedUdpLog = { 
            errorCode = "BODY_EXPECTED_ERROR",
            errorMsg = "Body was expected, but not found."
          }
        }
        ngx.log(ngx.WARN, LOG_TAG, "Response body was expected, but not found.")
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
