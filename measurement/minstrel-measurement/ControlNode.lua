
--pprint = require ('pprint')

local ps = require ('posix.signal') --kill
local posix = require ('posix') -- sleep
local lpc = require 'lpc'
local misc = require 'misc'
local net = require ('Net')

require ('NodeBase')

require ('NetIF')
require ('misc')
require ('Uci')

require ('parsers/ex_process')

require ('AccessPointRef')
require ('StationRef')

require ('tcpExperiment')
require ('udpExperiment')
require ('mcastExperiment')

ControlNode = NodeBase:new()

function ControlNode:create ( name, ctrl, port, log_port, log_file, output_dir )
    local o = ControlNode:new ( { name = name
                                , ctrl = ctrl
                                , port = port
                                , log_port = log_port
                                , log_file = log_file
                                , output_dir = output_dir
                                , log_addr = ctrl.addr
                                , ap_refs = {}     -- list of access point nodes
                                , sta_refs = {}    -- list of station nodes
                                , node_refs = {}   -- list of all nodes
                                , stats = {}   -- maps node name to statistics
                                , pids = {}    -- maps node name to process id of lua node
                                } )

    if ( o.ctrl.addr == nil ) then
        o.ctrl:get_addr ()
        o.log_addr = o.ctrl.addr
    end

    if ( log_port ~= nil and log_file ~= nil ) then
        local pid, _, _ = misc.spawn ( "lua", "/usr/bin/runLogger", log_file 
                                    , "--port", log_port )
        o.pids = {}
        o.pids ['logger'] = pid
    end

    return o
end


function ControlNode:__tostring()
    local net = "none"
    if ( self.ctrl ~= nil ) then
        net = self.ctrl:__tostring()
    end
    local out = "control if: " .. net .. "\n"
    out = out .. "control port: " .. ( self.port or "none" ) .. "\n"
    out = out .. "log file: " .. ( self.log_file or "none" ) .."\n"
    out = out .. "log port: " .. ( self.log_port or "none" ) .. "\n"
    for i, ap_ref in ipairs ( self.ap_refs ) do
        out = out .. '\n'
        out = out .. ap_ref:__tostring()
    end
    out = out .. '\n'
    for i, sta_ref in ipairs ( self.sta_refs ) do
        out = out .. '\n'
        out = out .. sta_ref:__tostring()
    end
    return out
end

function ControlNode:get_ctrl_addr ()
    return net.get_addr ( self.ctrl.iface )
end

function ControlNode:add_ap ( name, ctrl_if, rsa_key )
    self:send_info ( " add access point " .. name )
    local ctrl = NetIF:create ( ctrl_if )
    local ref = AccessPointRef:create ( name, ctrl, rsa_key, self.output_dir )
    self.ap_refs [ #self.ap_refs + 1 ] = ref 
    self.node_refs [ #self.node_refs + 1 ] = ref
end

function ControlNode:add_sta ( name, ctrl_if, rsa_key )
    self:send_info ( " add station " .. name )
    local ctrl = NetIF:create ( ctrl_if )
    local ref = StationRef:create ( name, ctrl, rsa_key, self.output_dir )
    self.sta_refs [ #self.sta_refs + 1 ] = ref 
    self.node_refs [ #self.node_refs + 1 ] = ref
end

function ControlNode:list_aps ()
    local names = {}
    for _,v in ipairs ( self.ap_refs ) do names [ #names + 1 ] = v.name end
    return names
end

function ControlNode:list_stas ()
    local names = {}
    for _,v in ipairs ( self.sta_refs ) do names [ #names + 1 ] = v.name end
    return names
end

function ControlNode:list_nodes ()
    self:send_info ( " query nodes" )
    local names = {}
    for _,v in ipairs ( self.node_refs ) do names [ #names + 1 ] = v.name end
    return names
end

function ControlNode:list_phys ( name )
    local node_ref = self:find_node_ref ( name )
    if ( node_ref == nil ) then return {} end
    return node_ref.rpc.phy_devices ()
end

function ControlNode:set_phy ( name, wifi )
    local node_ref = self:find_node_ref ( name )
    node_ref.wifi_cur = wifi
end

function ControlNode:get_phy ( name )
    local node_ref = self:find_node_ref ( name )
    return node_ref.wifi_cur
end

function ControlNode:enable_wifi ( name, enabled )
    local node_ref = self:find_node_ref ( name )
    return node_ref:enable_wifi ( enabled ) 
end

function ControlNode:link_to_ssid ( name, ssid )
    self:send_info ( "link to ssid " .. (name or "none" ) )
    local node_ref = self:find_node_ref ( name )
    if ( node_ref ~= nil ) then
        self:send_info ( "link to ssid " .. (node_ref.name or "none" ) )
    end
    node_ref:link_to_ssid ( ssid, node_ref.wifi_cur )
end

function ControlNode:get_ssid ( name )
    self:send_info ( "get ssid " .. (name or "none" ) )
    local node_ref = self:find_node_ref ( name )
    if ( node_ref ~= nil ) then
        self:send_info ( "get ssid node_ref " .. ( node_ref.name or "none" ) )
    end
    return node_ref.rpc.get_ssid ( node_ref.wifi_cur )
end

function ControlNode:add_station ( ap, sta )
    local ap_ref = self:find_node_ref ( ap )
    local sta_ref = self:find_node_ref ( sta )
    if ( ap_ref == nil or sta_ref == nil ) then return nil end
    local mac = sta_ref.rpc.get_mac ( sta_ref.wifi_cur )
    ap_ref:add_station ( mac, sta_ref )
end

function ControlNode:list_stations ( ap )
    local ap_ref = self:find_node_ref ( ap )
    return ap_ref.stations
end

function ControlNode:set_ani ( name, ani )
    local node_ref = self:find_node_ref ( name )
    node_ref.rpc.set_ani ( node_ref.wifi_cur, ani )
end

function ControlNode:find_node_ref( name ) 
    for _, node in ipairs ( self.node_refs ) do 
        if node.name == name then return node end 
    end
    return nil
end

function ControlNode:set_nameservers ( nameserver )
    for _, node_ref in ipairs ( self.node_refs ) do
        node_ref:set_nameserver ( nameserver )
    end
end

function ControlNode:check_bridges ()
    local no_bridges = true
    for _, node_ref in ipairs ( self.node_refs ) do
        local has_bridge = node_ref:check_bridge ()
        self:send_info ( node_ref.name .. " has no bridged setup" )
        no_bridges = no_bridges and not has_bridge
    end
    if ( no_bridges == false ) then
        self:send_error ( "One or more nodes have a bridged setup" )
    end
    return no_bridges
end

function ControlNode:get_stats()
    return self.stats
end

function ControlNode:reachable ()
    function node_reachable ( ip )
        local ping, exit_code = misc.execute ( "ping", "-c1", ip)
        return exit_code == 0
    end

    local reached = {}
    for _, node in ipairs ( self.node_refs ) do
        local addr = net.lookup ( node.name )
        if ( addr == nil ) then
            break
        end
        node.ctrl.addr = addr
        if node_reachable ( addr ) then
            reached [ node.name ] = true
        else
            reached [ node.name ] = false
        end
    end
    return reached
end

function ControlNode:start( log_addr, log_port )

    function start_node ( node_ref, log_addr )

        local remote_cmd = "lua /usr/bin/runNode"
                    .. " --name " .. node_ref.name 
                    .. " --ctrl_if " .. node_ref.ctrl.iface

        if ( log_addr ~= nil ) then
            remote_cmd = remote_cmd .. " --log_ip " .. log_addr 
        end
        self:send_info ( remote_cmd )
        local pid, _, _ = misc.spawn ( "ssh", "-i", node_ref.rsa_key, 
                                      "root@" .. node_ref.ctrl.addr, remote_cmd )
        return pid
    end

    for _, node_ref in ipairs ( self.node_refs ) do
        self.pids [ node_ref.name ] = start_node( node_ref, log_addr )
    end
    return true
end

function ControlNode:connect_nodes ( ctrl_port )
    
    for _, node_ref in ipairs ( self.node_refs ) do
        local slave = net.connect ( node_ref.ctrl.addr, ctrl_port, 10, node_ref.name, 
                                    function ( msg ) self:send_error ( msg ) end )
        if ( slave == nil ) then 
            return false
        else
            self:send_info ( "Connected to " .. node_ref.name)
            node_ref:init ( slave )
        end
    end

    -- query lua pid before closing rpc connection
    -- maybe to kill nodes later
    for _, node_ref in ipairs ( self.node_refs ) do 
        self.pids [ node_ref.name ] = node_ref.rpc.get_pid ()
    end

    return true
end

function ControlNode:disconnect_nodes()
    for _, node_ref in ipairs ( self.node_refs ) do 
        net.disconnect ( node_ref.rpc )
    end
end

-- kill all running nodes with two times sigint(2)
-- (default kill signal is sigterm(15) )
function ControlNode:stop()

    --fixme: move to log node
    function stop_logger ( pid )
        if ( pid == nil ) then
            self:send_error ( "logger not stopped: pid is not set" )
        else
            self:send_info ( "stop logger with pid " .. pid )
            ps.kill ( pid, ps.SIGINT )
            ps.kill ( pid, ps.SIGINT )
            lpc.wait ( pid )
        end
    end

    -- fixme: nodes should implement a stop function and kill itself with getpid
    -- and wait
    for i, node_ref in ipairs ( self.node_refs ) do
        if ( node_ref.rpc == nil ) then break end
        self:send_info ( "stop node at " .. node_ref.ctrl.addr .. " with pid " .. self.pids [ node_ref.name ] )
        local ssh
        local exit_code
        local remote = "root@" .. node_ref.ctrl.addr
        local remote_cmd = "/usr/bin/kill_remote " .. self.pids [ node_ref.name ] .. " --INT -i 2"
        ssh, exit_code = misc.execute ( "ssh", "-i", node_ref.rsa_key, remote, remote_cmd )
        if ( exit_code ~= 0 ) then
            self:send_debug ( "send signal -2 to remote pid " .. self.pids [ node_ref.name ] .. " failed" )
        end
    end
    stop_logger ( self.pids['logger'] )
end

-- runs experiment 'exp' for all nodes 'ap_refs'
-- in parallel
-- see run_experiment in Experiment.lua for
-- a sequential variant
-- fixme: exp userdata over rpc not possible
function ControlNode:run_experiments ( command, args, ap_names, is_fixed )

    function check_mem ( mem, name )
        -- local warn_threshold = 40960
        local warn_threshold = 10240
        local error_threshold = 8192
        -- local error_threshold = 20280
        if ( mem < error_threshold ) then
            self:send_error ( name .. " is running out of memory. stop here" )
            return false
        elseif ( mem < warn_threshold ) then
            self:send_warning ( name .. " has low memory." )
        end
        return true
    end

    function find_rate ( rate_name, rate_names, rate_indices )
        rate_name = string.gsub ( rate_name, " ", "" )
        rate_name = string.gsub ( rate_name, "MBit/s", "M" )
        rate_name = string.gsub ( rate_name, "1M", "1.0M" )
        --print ( "'" .. rate_name .. "'" )
        for i, name in ipairs ( rate_names ) do
            if ( name == rate_name ) then return rate_indices [ i ] end
        end
        self:send_warning ( "rate name doesn't match: '" .. rate_name .. "'" )
        return nil
    end

    self:send_info ("")

    local exp
    if ( command == "tcp") then
        exp = TcpExperiment:create ( self, args, is_fixed )
    elseif ( command == "mcast") then
        exp = McastExperiment:create ( self, args, is_fixed )
    elseif ( command == "udp") then
        exp = UdpExperiment:create ( self, args, is_fixed )
    else
        return false
    end

    local ret = true
    local ap_refs = {}
    for _, name in ipairs ( ap_names ) do
        local ap_ref = self:find_node_ref ( name )
        ap_refs [ #ap_refs + 1 ] = ap_ref
    end

    self:send_info ("*** Prepare measurement ***")
    for _, ap_ref in ipairs ( ap_refs ) do
        exp:prepare_measurement ( ap_ref )
    end

    self:send_info ("*** Generate measurement keys ***")
    local keys = {}
    for i, ap_ref in ipairs ( ap_refs ) do
        keys[i] = exp:keys ( ap_ref )
    end

    local stop = false
    local num_keys = #keys[1]
    local counter = 1
    self:send_info ( "Run " .. num_keys .. " experiments." )
    for _, key in ipairs ( keys[1] ) do -- fixme: smallest set of keys

        self:send_info ("**********************************************")
        self:send_info ("Start experiment " .. counter .. " of " .. num_keys .. ".")
        self:send_info ("**********************************************")

        for _, ap_ref in ipairs ( ap_refs ) do
            local free_m = ap_ref:get_free_mem ()
            if ( check_mem ( free_m, ap_ref.name ) == false ) then
                return ret
            end
            for _, sta_ref in ipairs ( ap_ref.refs ) do
                local free_m = sta_ref:get_free_mem ()
                if ( check_mem ( free_m, sta_ref.name ) == false ) then
                    return ret
                end
            end
        end

        self:send_info ("*** Settle measurement ***")
        for _, ap_ref in ipairs ( ap_refs ) do
            -- self:send_debug ( ap_ref:__tostring() )
            -- for _, station in ipairs ( ap_ref.rpc.visible_stations( ap_ref.wifi_cur ) ) do
            --     self:send_debug ( "station: " .. station )
            -- end
            if ( exp:settle_measurement ( ap_ref, key, 10 ) == false ) then
                self:send_error ( "experiment aborted, settledment failed. please check the wifi connnections." )
                return ret
            end
            -- for _, station in ipairs ( ap_ref.rpc.visible_stations( ap_ref.wifi_cur ) ) do
            --     self:send_debug ( "station: " .. station )
            -- end

            local rate_names = ap_ref.rpc.tx_rate_names ( ap_ref.wifi_cur, ap_ref.stations[1] )
            self:send_debug( "rates names: " .. table_tostring ( rate_names ) )
            local rates = ap_ref.rpc.tx_rate_indices ( ap_ref.wifi_cur, ap_ref.stations[1] )
            self:send_debug( "rates names: " .. table_tostring ( rates ) )

            for i, sta_ref in ipairs ( ap_ref.refs ) do

                local rate_name = sta_ref.rpc.get_linked_rate_idx ( sta_ref.wifi_cur )
                if ( rate_name ~= nil ) then
                    local rate_idx = find_rate ( rate_name, rate_names, rates )
                    self:send_debug ( " rate_idx: " .. ( rate_idx or "unset" ) )
                end

                local signal = sta_ref.rpc.get_linked_signal ( sta_ref.wifi_cur )
            end

        end

        self:send_info ( "Waiting one extra second for initialised debugfs" )
        posix.sleep (1)

        self:send_info ("*** Start Measurement ***" )
        -- -------------------------------------------------------
        for _, ap_ref in ipairs ( ap_refs ) do
             exp:start_measurement (ap_ref, key )
        end

        -- -------------------------------------------------------
        -- Experiment
        -- -------------------------------------------------------

        self:send_info ("*** Start Experiment ***" )
        for _, ap_ref in ipairs ( ap_refs ) do
             exp:start_experiment ( ap_ref, key )
        end
    
        self:send_info ("*** Wait Experiment ***" )
        for _, ap_ref in ipairs ( ap_refs ) do
            exp:wait_experiment ( ap_ref, 5 )
        end

        -- -------------------------------------------------------

        self:send_info ("*** Stop Measurement ***" )
        for _, ap_ref in ipairs ( ap_refs ) do
            exp:stop_measurement (ap_ref, key )
        end

        self:send_info ("*** Fetch Measurement ***" )
        for _, ap_ref in ipairs ( ap_refs ) do
            exp:fetch_measurement (ap_ref, key )
        end

        self:send_info ("*** Unsettle measurement ***" )
        for _, ap_ref in ipairs ( ap_refs ) do
            exp:unsettle_measurement ( ap_ref, key )
        end

        counter = counter + 1
    end

    self:send_info ( "*** Copy stats from nodes. ***" )
    for _, ap_ref in ipairs ( ap_refs ) do
        self:copy_stats ( ap_ref )
    end

    self:send_info ("*** Transfer Measurement Result")
    return ret

end

function ControlNode:copy_stats ( ap_ref )

    self.stats [ ap_ref.name ] = {}
    self.stats [ ap_ref.name ] [ 'regmon_stats' ] = copy_map ( ap_ref.stats.regmon_stats )
    self.stats [ ap_ref.name ] [ 'tcpdump_pcaps' ] = copy_map ( ap_ref.stats.tcpdump_pcaps )
    self.stats [ ap_ref.name ] [ 'cpusage_stats' ] = copy_map ( ap_ref.stats.cpusage_stats )
    self.stats [ ap_ref.name ] [ 'rc_stats' ] = copy_map ( ap_ref.stats.rc_stats )

    for _, sta_ref in ipairs ( ap_ref.refs ) do
        self.stats [ sta_ref.name ] = {} 
        self.stats [ sta_ref.name ] [ 'regmon_stats' ] = copy_map ( sta_ref.stats.regmon_stats )
        self.stats [ sta_ref.name ] [ 'tcpdump_pcaps' ] = copy_map ( sta_ref.stats.tcpdump_pcaps )
        self.stats [ sta_ref.name ] [ 'cpusage_stats' ] = copy_map ( sta_ref.stats.cpusage_stats )
        self.stats [ sta_ref.name ] [ 'rc_stats' ] = copy_map ( sta_ref.stats.rc_stats )
    end

end

-- -------------------------
-- Hardware
-- -------------------------

function ControlNode:get_boards ()
    local map = {}
    for _, node_ref in ipairs ( self.node_refs ) do
       local board = node_ref:get_board () 
       map [ node_ref.name ] = board
    end
    return map
end

-- -------------------------
-- date
-- -------------------------

function ControlNode:set_dates ()
    local time = os.date( "*t", os.time() )
    for _, node_ref in ipairs ( self.node_refs ) do
        local cur_time
        local err
        cur_time, err = node_ref:set_date ( time.year, time.month, time.day, time.hour, time.min, time.sec )
        if ( err == nil ) then
            self:send_info ( "Set date/time to " .. cur_time )
        else
            self:send_error ( "Set date/time failed: " .. err )
            self:send_error ( "Time is: " .. cur_time )
        end
    end
end
