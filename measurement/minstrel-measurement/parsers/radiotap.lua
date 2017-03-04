require ('bit') -- lua5.3 supports operators &,|,<<,>> natively

PCAP = {}

--http://www.radiotap.org/fields/defined

PCAP.radiotap_type = {}
PCAP.radiotap_type [ "IEEE80211_RADIOTAP_TSFT" ] = 1
PCAP.radiotap_type [ "IEEE80211_RADIOTAP_FLAGS" ] = 2
PCAP.radiotap_type [ "IEEE80211_RADIOTAP_RATE" ] = 3
PCAP.radiotap_type [ "IEEE80211_RADIOTAP_CHANNEL" ] = 4
PCAP.radiotap_type [ "IEEE80211_RADIOTAP_FHSS" ] = 5
PCAP.radiotap_type [ "IEEE80211_RADIOTAP_DBM_ANTSIGNAL" ] = 6
PCAP.radiotap_type [ "IEEE80211_RADIOTAP_DBM_ANTNOISE" ] = 7
PCAP.radiotap_type [ "IEEE80211_RADIOTAP_LOCK_QUALITY" ] = 8
PCAP.radiotap_type [ "IEEE80211_RADIOTAP_TX_ATTENUATION" ] = 9
PCAP.radiotap_type [ "IEEE80211_RADIOTAP_DB_TX_ATTENUATION" ] = 10
PCAP.radiotap_type [ "IEEE80211_RADIOTAP_DBM_TX_POWER" ] = 11
PCAP.radiotap_type [ "IEEE80211_RADIOTAP_ANTENNA" ] = 12
PCAP.radiotap_type [ "IEEE80211_RADIOTAP_DB_ANTSIGNAL" ] = 13
PCAP.radiotap_type [ "IEEE80211_RADIOTAP_DB_ANTNOISE" ] = 14
PCAP.radiotap_type [ "IEEE80211_RADIOTAP_RX_FLAGS" ] = 15
PCAP.radiotap_type [ "IEEE80211_RADIOTAP_EXT" ] = 32

PCAP.radiotap_flags = {}
PCAP.radiotap_flags ['IEEE80211_RADIOTAP_F_CFP'] = 1
PCAP.radiotap_flags ['IEEE80211_RADIOTAP_F_SHORTPRE'] = 2
PCAP.radiotap_flags ['IEEE80211_RADIOTAP_F_WEP'] = 3
PCAP.radiotap_flags ['IEEE80211_RADIOTAP_F_FRAG'] = 4
PCAP.radiotap_flags ['IEEE80211_RADIOTAP_F_FCS'] = 5
PCAP.radiotap_flags ['IEEE80211_RADIOTAP_F_DATAPAD'] = 6
PCAP.radiotap_flags ['IEEE80211_RADIOTAP_F_BADFCS'] = 7
PCAP.radiotap_flags ['IEEE80211_RADIOTAP_F_SHORTGI'] = 8

PCAP.radiotap_chan_flags = {}
PCAP.radiotap_chan_flags [ "IEEE80211_CHAN_TURBO" ] = 5
PCAP.radiotap_chan_flags [ "IEEE80211_CHAN_CCK" ] = 6
PCAP.radiotap_chan_flags [ "IEEE80211_CHAN_OFDM" ] = 7
PCAP.radiotap_chan_flags [ "IEEE80211_CHAN_2GHZ" ] = 8
PCAP.radiotap_chan_flags [ "IEEE80211_CHAN_5GHZ" ] = 9
PCAP.radiotap_chan_flags [ "IEEE80211_CHAN_PASSIVE" ] = 10
PCAP.radiotap_chan_flags [ "IEEE80211_CHAN_DYN" ] = 11
PCAP.radiotap_chan_flags [ "IEEE80211_CHAN_GFSK" ] = 12

-- converts a number 'mask' of with size 'len'
-- into a string in binary representation
-- (in reversed order)
PCAP.bitmask_tostring = function ( mask, len )
    local ret = ""
    for i = 1, len do
        if ( PCAP.hasbit ( mask, PCAP.bit(i) ) )  then
            ret = ret .. "1"
        else
            ret = ret .. "0"
        end
    end
    return ret
end

-- (1 << (p-1))
PCAP.bit = function (p)
    return 2 ^ (p - 1)  -- 1-based indexing
end

-- x & (p-1)
-- x bitmask
-- p bit created by PCAP.bit
PCAP.hasbit = function (x, p)
  return x % (p + p) >= p       
end

-- converts a string 'str' into decimal representation (ascii) 
PCAP.to_bytes = function ( str )
    local bytes = ""
    for i = 1, #str do
        if ( i ~= 1 ) then bytes = bytes .. " " end
        bytes = bytes .. string.byte ( str, i )
    end
    return bytes
end

-- converts a string 'str' into hexadecimal representation (ascii) 
PCAP.to_bytes_hex = function ( str )
    local bytes = ""
    for i = 1, #str do
        if ( i ~= 1 ) then bytes = bytes .. " " end
        bytes = bytes .. string.format("%x", string.byte ( str, i ) )
    end
    return bytes
end

-- read one byte from head of 'bytes' and truncate it from
-- (unsigned)
PCAP.read_int8 = function ( bytes )
    return string.byte ( bytes, 1 ), string.sub ( bytes, 2 )
end

-- read one byte from head of 'bytes' and truncate it from
-- (signed)
-- 2-complement already known by lua
PCAP.read_int8_signed = function ( bytes )
    local num, rest = PCAP.read_int8 ( bytes )
    return num - 256, rest
end

-- read short number from head of 'bytes' and truncate from
-- (unsigned)
PCAP.read_int16 = function ( bytes )
    return bit.lshift( string.byte ( bytes, 2 ), 8) 
        + string.byte ( bytes, 1 ), string.sub ( bytes, 3 )
end

-- read number (little endian) from head of 'bytes' and truncate from
-- (unsigned)
PCAP.read_int32 = function ( bytes )
    local num = bit.lshift ( string.byte ( bytes, 4 ), 24)
        + bit.lshift ( string.byte ( bytes, 3 ), 16)
        + bit.lshift ( string.byte ( bytes, 2 ), 8)
        + string.byte ( bytes, 1 )
    return num, string.sub ( bytes, 5 )
end

-- read long number from head of 'bytes' and truncate from
PCAP.read_int64 = function ( bytes )
    local rest = bytes
    local high, rest = PCAP.read_int32 ( rest )
    local low, rest = PCAP.read_int32 ( rest )
    local num = bit.lshift ( low, 32 ) + high
    return num, rest
end

PCAP.read_mac = function ( bytes )
    local ret = {}
    for i = 1, 6 do
        ret [ #ret + 1] = string.byte ( bytes, i )
    end
    local rest = string.sub ( bytes, 6 + 1 )
    return ret, rest
end

PCAP.mac_tostring = function ( mac )
    if ( #mac ~= 6 ) then return "not a mac addr" end
    local ret = ""
    for i = 1, 6 do
        if ( i ~= 1 ) then ret = ret .. ":" end
        ret = ret .. string.format("%x", mac [i])
    end
    return ret
end

PCAP.read_str = function ( bytes, len )
    local str = ""
    local rest = bytes
    for i = 1, len do
        c, rest = PCAP.read_int8 ( rest )
        str = str .. string.char ( c )
    end
    return str, rest
end

-- parse the radiotap data block
-- (bssid, ssid only)
-- block may be truncated by tcpdump
PCAP.parse_radiotap_data = function ( capdata )

    local ret = {}
    local rest = capdata

    -- skip first 16 bytes
    for i = 1, 16 do
        _, rest = PCAP.read_int8 ( rest )
    end

    local bssid = PCAP.read_mac ( rest )
    ret [ 'bssid' ] = bssid

    -- skip next 21 bytes
    for i = 1, 21 do
        _, rest = PCAP.read_int8 ( rest )
    end

    -- ssid (not \0 terminated )
    local ssid_len
    ssid_len, rest = PCAP.read_int8 ( rest )
    ssid_len = tonumber ( ssid_len )

    local ssid
    ssid, rest = PCAP.read_str ( rest, ssid_len )
    ret['ssid'] = ssid
    -- ...

    -- FCS
    return ret, rest
end

-- https://www.kernel.org/doc/Documentation/networking/radiotap-headers.txt
-- 1 byte it_version header version (always 0)
-- 1 byte .          padding ( to fit alignment )
-- 2 bytes it_len    total header and data length
-- 4 byte it_present bitmask ( bit 31 is set when theres a 64bit bitmask instead of a 32bit bitmask
PCAP.parse_radiotap_header = function ( capdata )
    local ret = {}
    local rest = capdata

    -- radiotap header
    ret ['it_ver'], rest = PCAP.read_int8 ( rest )
    _, rest = PCAP.read_int8 ( rest ) -- 1 byte padding
    ret ['it_len'], rest = PCAP.read_int16 ( rest )
    ret ['it_present'], rest = PCAP.read_int32 ( rest )
    
    local has_ext = PCAP.hasbit( ret['it_present'], PCAP.bit( PCAP.radiotap_type [ "IEEE80211_RADIOTAP_EXT" ] ) )
    if ( has_ext ) then
        ret ['it_present_ex'], rest = PCAP.read_int32 ( rest )
        _, rest = PCAP.read_int32 ( rest )
        _, rest = PCAP.read_int32 ( rest )
        _, rest = PCAP.read_int32 ( rest )
    end

    if ( PCAP.hasbit ( ret['it_present'], PCAP.bit ( PCAP.radiotap_type [ 'IEEE80211_RADIOTAP_TSFT' ] )  ) ) then
        --align 8
        ret['tsft'], rest = PCAP.read_int64 ( rest )
    end
    if ( PCAP.hasbit ( ret['it_present'], PCAP.bit ( PCAP.radiotap_type [ 'IEEE80211_RADIOTAP_FLAGS' ] )  ) ) then
        ret['flags'], rest = PCAP.read_int8 ( rest )
    end
    if ( PCAP.hasbit ( ret['it_present'], PCAP.bit ( PCAP.radiotap_type [ 'IEEE80211_RADIOTAP_RATE' ] )  ) ) then
        ret['rate'], rest = PCAP.read_int8 ( rest )
    end
    if ( PCAP.hasbit ( ret['it_present'], PCAP.bit ( PCAP.radiotap_type [ 'IEEE80211_RADIOTAP_CHANNEL' ] )  ) ) then
        --align 2
        ret['channel'], rest = PCAP.read_int16 ( rest )
        ret['channel_flags'], rest = PCAP.read_int16 ( rest )
    end
    if ( PCAP.hasbit ( ret['it_present'], PCAP.bit ( PCAP.radiotap_type [ 'IEEE80211_RADIOTAP_FHSS' ] )  ) ) then
        ret['fhss_hop_set'], rest = PCAP.read_int8 ( rest )
        ret['fhss_hop_pattern'], rest = PCAP.read_int8 ( rest )
    end
    if ( PCAP.hasbit ( ret['it_present'], PCAP.bit ( PCAP.radiotap_type [ 'IEEE80211_RADIOTAP_DBM_ANTSIGNAL' ] )  ) ) then
        ret['antenna_signal'], rest = PCAP.read_int8_signed ( rest )
    end
    if ( PCAP.hasbit ( ret['it_present'], PCAP.bit ( PCAP.radiotap_type [ 'IEEE80211_RADIOTAP_DBM_ANTNOISE' ] )  ) ) then
        ret['antenna_noise'], rest = PCAP.read_int8_signed ( rest )
    end
    if ( PCAP.hasbit ( ret['it_present'], PCAP.bit ( PCAP.radiotap_type [ 'IEEE80211_RADIOTAP_LOCK_QUALITY' ] )  ) ) then
        --align 2
        ret['lock_quality'], rest = PCAP.read_int16 ( rest )
    end
    if ( PCAP.hasbit ( ret['it_present'], PCAP.bit ( PCAP.radiotap_type [ 'IEEE80211_RADIOTAP_TX_ATTENUATION' ] )  ) ) then
        --align 2
        ret['antenna_noise'], rest = PCAP.read_int16 ( rest )
    end
    if ( PCAP.hasbit ( ret['it_present'], PCAP.bit ( PCAP.radiotap_type [ 'IEEE80211_RADIOTAP_DBM_TX_POWER' ] )  ) ) then
        -- align 1
        ret['tx_power'], rest = PCAP.read_int8_signed ( rest )
    end
    if ( PCAP.hasbit ( ret['it_present'], PCAP.bit ( PCAP.radiotap_type [ 'IEEE80211_RADIOTAP_ANTENNA' ] )  ) ) then
        ret['db_antenna_signal'], rest = PCAP.read_int8 ( rest )
    end
    if ( PCAP.hasbit ( ret['it_present'], PCAP.bit ( PCAP.radiotap_type [ 'IEEE80211_RADIOTAP_DB_ANTSIGNAL' ] )  ) ) then
        ret['db_antenna_signal'], rest = PCAP.read_int8 ( rest )
    end
    if ( PCAP.hasbit ( ret['it_present'], PCAP.bit ( PCAP.radiotap_type [ 'IEEE80211_RADIOTAP_DB_ANTNOISE' ] )  ) ) then
        ret['db_antenna_noise'], rest = PCAP.read_int8 ( rest )
    end
    if ( PCAP.hasbit ( ret['it_present'], PCAP.bit ( PCAP.radiotap_type [ 'IEEE80211_RADIOTAP_RX_FLAGS' ] )  ) ) then
        --align 2
        ret['db_antenna_noise'], rest = PCAP.read_int16 ( rest )
    end

    return ret, string.sub ( capdata, ret['it_len'] + 1 )
end