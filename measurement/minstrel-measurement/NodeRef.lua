require ('NetIF')

NodeRef = { name = nil
          , ctrl = nil
          , rpc = nil
          , wifis = nil
          , wifi_cur = nil
          , addrs = nil
          , macs = nil
          , ssid = nil
          , refs = nil
          , stats = nil
          , iperf_s_proc = nil
          }

function NodeRef:new (o)
    local o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function NodeRef:create ( name, ctrl, port )
    local o = NodeRef:new({ name = name, ctrl = ctrl, wifis = {}, ssid = nil
                          , addrs = {}, macs = {}, ssid = nil, stations = {}
                          , refs = {} })
    self.wifis = self.ref.rpc.wifi_devices()
    for _, phy in ipairs ( self.wifis ) do
        if (self.rpc ~= nil) then
            self.addrs [ phy ] = self.rpc.get_addr ( phy )
            self.macs [ phy ] = self.rpc.get_mac ( phy )
        end
    end
    return o
end

function NodeRef:connect ( port )
    function connect_rpc ()
        local l, e = rpc.connect ( self.ctrl.addr, port )
        return l, e
    end
    local status, slave, err = pcall ( connect_rpc )
    if (status == false) then
        print ( "Err: Connection to node failed" )
        print ( "Err: no node at address: " .. self.ctrl.addr .. " on port: " .. port )
        return
    end
    self.rpc = slave
end

function NodeRef:add_wifi ( phy )
    error ("deprecated")
end

function NodeRef:set_wifi ( phy )
    self.wifi_cur = phy
end

function NodeRef:get_addr ()
    return self.addrs [ self.wifi_cur ]
end

function NodeRef:get_mac ( )
    return self.macs [ self.wifi_cur ]
end

function NodeRef:__tostring() 
    local out = ""
    out = out .. self.name .. " :: " 
          .. "ctrl: " .. tostring ( self.ctrl ) .. "\n\t"
    if ( self.rpc ~= nil ) then
        out = out .. "rpc connected\n\t"
    else
        out = out .. "rpc not connected\n\t"
    end
    out = out .. "wifis: "
    if ( self.wifis == {} ) then
        out = out .. " none"
    else
        for i, wifi in ipairs ( self.wifis ) do
            if ( i ~= 1 ) then out = out .. ", " end
            local addr = self.addrs [ wifi ]
            if ( addr == nil ) then addr = "none" end
            out = out .. wifi .. ", addr " .. addr
        end
    end
    return out        
end

-- waits until all stations appears on ap
-- not precise, sta maybe not really connected afterwards
-- but two or three seconds later
-- not used
function NodeRef:wait_station ()
    repeat
        print ("wait for stations to come up ... ")
        os.sleep(1)
        local wifi_stations_cur = self.rpc.stations( self.wifi_cur )
        local miss = false
        for _, str in ipairs ( wifi_stations ) do
            if ( table.contains ( wifi_stations_cur, str ) == false ) then
                miss = true
                break
            end
        end
    until miss
end

-- wait for station is linked to ssid
function NodeRef:wait_linked ()
    local connected = false

    repeat
        local ssid = self.rpc.get_linked_ssid ( self.wifi_cur )
        if (ssid == nil) then 
            print ("Waiting: Station " .. self.name .. " not connected")
            os.sleep (1)
        else
            print ("Station " .. self.name .. " connected to " .. ssid)
            connected = true
        end
    until connected
end

function NodeRef:create_measurement()
    self.stats = Measurement:create ( self )
end

function NodeRef:restart_wifi( )
end

function NodeRef:add_monitor( )
    self.rpc.add_monitor ( self.wifi_cur )
end

function NodeRef:remove_monitor( )
    self.rpc.remove_monitor ( self.wifi_cur )
end
function NodeRef:start_measurement( key )
    self.stats:start ( self.wifi_cur, key )
end

function NodeRef:stop_measurement( key )
    self.stats:stop ()
    -- collect traces
    self.stats:fetch ( self.wifi_cur, key )
end

function NodeRef:start_iperf_server()
    local iperf_s_proc_str = self.rpc.start_tcp_iperf_s()
    self.iperf_server_proc = parse_process ( iperf_s_proc_str )
end

function NodeRef:stop_iperf_server()
    self.rpc.stop_iperf_server( self.iperf_server_proc['pid'] )
end
