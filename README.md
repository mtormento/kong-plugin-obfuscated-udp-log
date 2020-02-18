# Kong Obfuscated UDP Logging

A Kong plugin that allows logging to udp with optional obfuscation of request and response json bodies.

## Description

This plugin is useful when you want to log request and response json bodies but you need to mask sensitive data.

## Installation

### Development

Navigate to kong/plugins folder and clone this repo

<pre>
$ cd /path/to/kong/plugins
$ git clone https://github.com/mtormento/kong-plugin-obfuscated-udp-log obfuscated-udp-log
$ cd obfuscated-udp-log
$ luarocks make *.rockspec
</pre>

To make Kong aware that it has to look for the obfuscated-udp-log plugin, you'll have to add it to the custom_plugins property in your configuration file.

<pre>
custom_plugins:
    - obfuscated-udp-log
</pre>

Restart Kong and you're ready to go.

## luarocks

<pre>
$ luarocks install kong-plugin-obfuscated-udp-log
</pre>

## Author
Marco Tormento

## License
<pre>
The MIT License (MIT)
=====================

Copyright (c) 2020 Marco Tormento

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
</pre>
