-- This file creates a logging node 
-- and binds the message passing functions
-- to a RPC interface for network wide access

-- FIXME: when typed ^C into stdin the next operation gets the interrupt
-- when typed ^C^C into stdin the lua interpreter is interrupted


require ('LogNode')
require ('rpc')
local argparse = require "argparse"
require ('Net')

local parser = argparse("runLogger", "Run a minimalistic RPC enabled message logging node")

parser:argument("filename", "Filename for logging.")
parser:option ("--port", "RPC port", "12347" )
parser:flag ("--use_stdout", "Log to stdout additionally", false )
parser:flag ("-a --append", "Open log file in append mode", false )

parser:option ("--log_if", "RPC Interface name", "eth0" )

local args = parser:parse ()
local node = LogNode:create ( "Logger", args.filename, args.use_stdout, args.append )
node:send_info ( node.name, node:__tostring() )

-- shortcut to logger instance to simplify access
function send_info ( from, msg ) node:send_info ( from, msg ) end

-- shortcut to logger instance to simplify access
function send_warning ( from, msg ) node:send_warning ( from, msg ) end

-- shortcut to logger instance to simplify access
function send_error ( from, msg) node:send_error ( from, msg ) end

-- shortcut to logger instance to simplify access
function send_debug ( from, msg) node:send_debug ( from, msg ) end

-- shortcut to logger instance to simplify access
function set_cut () node:set_cut () end

function stop ( ... ) node:stop ( ... ) end

-- make all functions available via RPC
print ( node:run ( args.port ) )
