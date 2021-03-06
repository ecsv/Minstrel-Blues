require ('Experiment')

TcpExperiment = Experiment:new()

function TcpExperiment:create ( control, data, is_fixed )
    local o = TcpExperiment:new( { control = control, runs = data[1]
                                 , tx_powers = data[2], tx_rates = data[3]
                                 , tcpdata = data[4] 
                                 , is_fixed = is_fixed
                                 } )
    return o
end

function TcpExperiment:keys ( ap_ref )
    local keys = {}
    if ( self.is_fixed == true ) then
        if ( self.tx_rates == nil ) then
            self.tx_rates = ap_ref.rpc.tx_rate_indices ( ap_ref.wifi_cur, ap_ref.stations[1] )
        else
            self.tx_rates = split ( self.tx_rates, "," )
        end
    end
    
    if ( self.is_fixed == true ) then
        if ( self.tx_powers == nil ) then
            self.tx_powers = ap_ref.rpc.tx_power_indices ( ap_ref.wifi_cur, ap_ref.stations[1] )
        else
            self.tx_powers = split ( self.tx_powers, "," )
        end
    end

    if ( self.is_fixed == true ) then
        self.control:send_debug( "run tcp experiment for rates " .. table_tostring ( self.tx_rates, 80 ) )
        self.control:send_debug( "run tcp experiment for powers " .. table_tostring ( self.tx_powers, 80 ) )
    end

    for run = 1, self.runs do
        local run_key = tostring ( run )
        if ( self.is_fixed == true and ( self.tx_rates ~= nil and self.tx_powers ~= nil ) ) then
            for _, tx_rate in ipairs ( self.tx_rates ) do
                local rate_key = tostring ( tx_rate )
                for _, tx_power in ipairs ( self.tx_powers ) do
                    local power_key = tostring ( tx_power )
                    keys [ #keys + 1 ] = rate_key .. "-" .. power_key .. "-" .. run_key
                end
            end
        else
            keys [ #keys + 1 ] = run_key
        end
    end

    return keys
end

function TcpExperiment:start_measurement ( ap_ref, key )
    ap_ref:start_measurement ( key )
    local tcp = true
    ap_ref:start_iperf_servers ( tcp, key )
end

function TcpExperiment:stop_measurement ( ap_ref, key )
    ap_ref:stop_iperf_servers ( key )
    ap_ref:stop_measurement ( key )
end

function TcpExperiment:start_experiment ( ap_ref, key )
    -- start iperf clients on AP
    for _, sta_ref in ipairs ( ap_ref.refs ) do
        if ( sta_ref.is_passive == nil or sta_ref.is_passive == false ) then
            local addr = sta_ref:get_addr ()
            if ( addr == nil ) then
                error ( "start_experiment: address is unset" )
                return
            end
            local wait = false
            local phy_num = tonumber ( string.sub ( ap_ref.wifi_cur, 4 ) )
            local iperf_port = 12000 + phy_num
            local pid, exit_code = ap_ref.rpc.run_tcp_iperf ( ap_ref.wifi_cur, iperf_port, addr, self.tcpdata, wait )
            sta_ref.pids [ # sta_ref.pids + 1 ] = pid
        end
    end
end

function TcpExperiment:wait_experiment ( ap_ref, key )
    -- wait for clients on AP
    for _, sta_ref in ipairs ( ap_ref.refs ) do
        if ( sta_ref.is_passive == nil or sta_ref.is_passive == false ) then
            local addr = sta_ref:get_addr ()
            if ( addr == nil ) then
                error ( "wait_experiment: address is unset" )
                return
            end
            local _, out = ap_ref.rpc.wait_iperf_c ( ap_ref.wifi_cur, addr )
            ap_ref.stats.iperf_c_outs [ key ] = out
        end
    end
end
