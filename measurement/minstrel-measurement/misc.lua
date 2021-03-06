
local poll = require 'posix.poll'
local stdio = require 'posix.stdio'
local unistd = require 'posix.unistd'

require ('lfs')
require ('lpc')

Misc = {}

function table_size ( tbl )
    local count = 0
    for _ in pairs ( tbl ) do count = count + 1 end
    return count
end

function table_tostring ( tbl, max_line_size, delim )
    if ( tbl == nil ) then return "none" end
    if ( delim == nil ) then delim = ", " end
    local count = 1
    local lines = {}
    lines [ count ] = ""
    for i, elem in ipairs ( tbl ) do
        local elem_str = tostring ( elem )
        if ( i ~= 1 ) then lines [ count ] = lines [ count ] .. delim end
        if ( max_line_size ~= nil and ( ( string.len ( lines [ count ] ) + string.len ( elem_str ) ) >= max_line_size ) ) then
            count = count + 1
            lines [ count ] = ""
        end
        lines [ count ] = lines [ count ] .. elem_str
    end
    if ( count > 1 ) then
        local all = ""
        for i, line in ipairs ( lines ) do
            all = all .. line
            if ( i ~= table_size ( lines ) ) then
                all = all .. '\n'
            end
        end
        return all
    else
        return lines [ 1 ]
    end
end

Misc.write_table = function ( table, fname )
    if ( not isFile ( fname ) ) then
        local file = io.open ( fname, "w" )
        if ( file ~= nil ) then
            for i, j in ipairs ( table ) do
                if ( i ~= 1 ) then file:write (" ") end
                    file:write ( tostring ( j ) )
                end
                file:write("\n")
                file:close()
            end
        end
end

Misc.index_of = function ( value, table )
    for i, v in ipairs ( table ) do
        if ( v == value ) then return i end
    end
    return nil
end

Misc.key_of = function ( value, table )
    for k, v in pairs ( table ) do
        if ( v == value ) then return k end
    end
    return nil
end

Misc.Set = function ( list )
      local set = {}
      for _, l in ipairs ( list ) do set [ l ] = true end
      return set
end

Misc.Set_count = function ( list )
      local set = {}
      for _, l in ipairs ( list ) do
        local count = 1
        if ( set [ l ] ~= nil ) then
            count = set [ l ] + 1
        end
        set [ l ] = count
      end
      return set
end

function copy_map ( from )
    local to = {}
    if ( from ~= nil ) then
        for key, data in pairs ( from ) do
            to [ key ] = data
        end
    end
    return to
end

function merge_map ( from, to )
    if ( from ~= nil and to ~= nil ) then
        for key, data in pairs ( from ) do
            to [ key ] = data
        end
    end
end

-- https://stackoverflow.com/questions/1426954/split-string-in-lua
function split ( s, delimiter )
    local result = {};
    if ( s == nil or delimiter == nil ) then return result end
    for match in ( s .. delimiter ):gmatch ( "(.-)" .. delimiter ) do
        table.insert ( result, match )
    end
    return result;
end


-- https://stackoverflow.com/questions/5303174/how-to-get-list-of-directories-in-lua
-- Lua implementation of PHP scandir function
function scandir ( directory )
    local i, t, popen = 0, {}, io.popen
    local pfile = popen ( 'ls -a "' .. directory .. '"' )
    for filename in pfile:lines () do
        i = i + 1
        t[i] = filename
    end
    pfile:close ()
    return t
end


-- https://stackoverflow.com/questions/4990990/lua-check-if-a-file-exists

-- no function checks for errors.
-- you should check for them

function isFile ( name )
    if ( name == nil ) then
        io.stderr:write ( "Error: filename argument is not set\n" )
        return false 
    end
    if type ( name ) ~= "string" then 
        io.stderr:write ( "Error: filename argument should be a string\n" )
        return false 
    end
    if not isDir ( name ) then
        local exists = os.rename ( name, name )
        if ( exists ~= nil and exists == true ) then
            return true
        else 
            --io.stderr:write ( "Error: file doesn't exists " .. name .. "\n" )
            return false
        end
    end
    --io.stderr:write ( "Error: not a file but a directory " .. name .. "\n" )
    return false
end


function isFileOrDir ( name )
    if type ( name ) ~= "string" then return false end
    return os.rename ( name, name ) and true or false
end


function isDir ( name )
    if type ( name ) ~= "string" then return false end
    local cd = lfs.currentdir ()
    local is = lfs.chdir ( name ) and true or false
    lfs.chdir ( cd )
    return is
end

-- https://stackoverflow.com/questions/2282444/how-to-check-if-a-table-contains-an-element-in-lua
function table.contains ( table, element )
  for _, value in pairs ( table ) do
    if value == element then
      return true
    end
  end
  return false
end

function print_globals ()
    for k, v in pairs ( _G ) do
        if ( type ( v ) ~= "function" ) then
            print ( k  .. " " .. ": " .. type ( v ) )
        end
    end
end

-- syncronize time (date MMDDhhmm[[CC]YY][.ss])
function set_date_core ( year, month, day, hour, min, second )
    local date = string.format ( "%02d", month )
                 .. string.format ( "%02d", day )
                 .. string.format ( "%02d", hour )
                 .. string.format ( "%02d", min )
                 .. string.format ( "%04d", year )
                 .. string.format ( "%02d", second )
    local date2, exit_code = Misc.execute ( "date", date )
    if ( exit_code ~= 0 ) then
        return nil, date
    else
        return date, nil
    end
end

-- syncronize time (date [YYYY.]MM.DD-hh:mm[:ss])
function set_date_bb ( year, month, day, hour, min, second )
    local date = string.format ( "%04d", year ) .. "."
                 .. string.format ( "%02d", month ) .. "."
                 .. string.format ( "%02d", day ) .. "-"
                 .. string.format ( "%02d", hour ) .. ":"
                 .. string.format ( "%02d", min ) .. ":"
                 .. string.format ( "%02d", second )
    local result, exit_code = Misc.execute ( "date", date )
    if ( exit_code ~= 0 ) then
        return nil, result
    else
        return result, nil
    end
end

function Misc.nanosleep( s )
  local ntime = os.clock() + s
  repeat until os.clock() > ntime
end

-- LPC child error: No such file or directory
function Misc.execute ( ... )
    io.stderr:write( table_tostring ( { ... }, nil, " " ) .. "\n")

    local pid, stdin, stdout = lpc.run ( ... )
    stdin:close()
    if ( pid ~= nil ) then
        local exit_code = lpc.wait ( pid )
        if ( exit_code == 0 ) then
            local content = stdout:read ("*a")
            stdout:close()
            return content, exit_code
        else
            return nil, exit_code
        end
    end
    return nil, nil
end

function Misc.spawn ( ... )
    io.stderr:write( table_tostring ( { ... }, nil, " " ) .. "\n")
    return lpc.run ( ... )
end

function Misc.read_nonblock ( fh, ms, sz, debug_node )
    if ( fh == nil ) then return nil end
    if ( ms == nil ) then ms = 100 end
    if ( sz == nil ) then sz = 4096 end
    --if ( sz == nil ) then sz = 1024 end
    local lines = ""
    local fd = stdio.fileno ( fh )
    repeat
        local r = poll.rpoll ( fd, ms )
        if ( debug_node ~= nil ) then
            debug_node:send_debug ( "misc.read_nonblock repeat rpoll: " .. tostring ( r ) )
        end
        if ( r == 1 ) then
            local res = unistd.read ( fd, sz )
            if ( res ~= nil and res ~= "" ) then
                lines = lines .. res
                if ( string.len ( lines ) > sz ) then
                    break
                end
            else
                break
            end
        end
    until ( r == 0 )
    if ( lines ~= "" ) then
        if ( debug_node ~= nil ) then
            debug_node:send_debug ( "misc.read_nonblock bytes: " .. tostring ( string.len ( lines ) ) )
        end
        return lines
    else
        return nil
    end
end

function Misc.execute_nonblock ( ms, sz, ... )
    local pid, stdin, stdout = lpc.run ( ... )
    stdin:close ()
    local content = nil
    if ( stdout ~= nil ) then
        content = Misc.read_nonblock ( stdout, ms, sz )
    end
    local exit_code = lpc.wait ( pid )
    if ( stdout ~= nil ) then
        local tail = Misc.read_nonblock ( stdout, ms, sz )
        if ( tail ~= nil ) then
            content = ( content or "" ) .. tail
        end
    end
    if ( stdout ~= nil ) then
        stdout:close()
    end
    return content, exit_code
end


function Misc.randomize_list ( list )
    math.randomseed ( os.time() )
    local set = {}
    local randomized = {}
    while table_size ( randomized ) < table_size ( list ) do
        local nxt = math.random (1, table_size ( list ) )
        if ( set [ nxt ] ~= true ) then
            set [ nxt ] = true
            randomized [ #randomized + 1 ] = list [ nxt ]
        end
    end
    return randomized
end

function Misc.round ( num, numDecimalPlaces )
    local mult = 10 ^ ( numDecimalPlaces or 0 )
    return math.floor ( num * mult + 0.5 ) / mult
end


function Misc.all_true ( table )
    if ( table_size ( table ) == 0 ) then return false end
    local result = true
    for _, value in ipairs ( table ) do
        result = result and value
    end
    return result
end


return Misc
