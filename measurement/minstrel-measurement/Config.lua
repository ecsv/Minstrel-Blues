
function find_node( name, nodes ) 
    for _, node in ipairs ( nodes ) do 
        if ( node.name == name ) then return node end 
    end
    return nil
end

function cnode_to_string ( config )
    if ( config == nil ) then return "none" end
    return ( config.name or "none") .. "\t" .. ( config.radio or "none" ) .. "\t" .. ( config.ctrl_if or "none" )
end


function show_config_error( parser, arg, option )
    local str
    if ( option == true) then
        str = "option '--" .. arg .. "' missing or no config file specified"
    else
        str = "<".. arg .. "> missing"
    end
    print ( parser:get_usage() )
    print ( )
    print ( "Error: " .. str )
    os.exit()
end

ctrl = nil -- var in config file
nodes = {} -- table in config file
connections = {} -- table in config file

function create_config ( name, ctrl_if, radio )
    return { name  = name
           , ctrl_if = ctrl_if
           , radio = radio
           }
end

function create_configs ( names, ctrl, radio )
    local configs = {}
    for i, name in ipairs ( names ) do
        configs [i] = create_config ( name, ctrl, radio )
    end
    return configs
end

function copy_config_nodes( src, dest )
    for _,v in ipairs( src ) do dest [ #dest + 1 ] = v end
end

function get_config_fname ( fname )
    local rc_fname = os.getenv("HOME") .. "/.minstrelmrc"
    local has_rcfile = isFile ( rc_fname )
    local has_config_arg = fname ~= nil
    
    if ( has_config_arg == true ) then
        return fname
    else
        return rc_fname
    end
end

function load_config ( fname )
    local rc_fname = os.getenv("HOME") .. "/.minstrelmrc"
    local has_rcfile = isFile ( rc_fname )
    local has_config_arg = fname ~= nil

    -- load config from a file
    if ( has_config_arg or has_rcfile ) then

        if ( not isFile ( fname ) and not has_rcfile ) then
            print ( fname .. " does not exists.")
            return false
        end

        -- (loadfile, dofile, loadstring)  
        if ( has_config_arg == true ) then
            require ( string.sub ( fname, 1, #fname - 4 ) )
        else
            dofile ( rc_fname )
        end
        
        return true
    end

    return false
end

function set_config_from_arg ( config, key, arg )
    if ( arg ~= nil ) then config [ key ] = arg end 
end

function set_configs_from_arg ( configs, key, arg )
    for _, config in ipairs ( configs ) do
        set_config_from_arg ( config, key, arg )
    end
end

function select_config ( all_configs, name )
    if ( arg == nil ) then  return nil end

    local node = find_node ( name, all_configs )
    
    if ( node == nil ) then return nil end
    if ( node.name ~= name ) then
        print ( "Error: no configuration for node with name '" .. name .. "' found")
        return nil
    end
    return node
end

function select_configs ( all_configs, names )
    local configs = {}
    if ( table_size ( names ) > 0 ) then
        for _, name in ipairs ( names ) do
            local node = find_node ( name, all_configs )
            if ( node == nil ) then
                print ( "Error: no configuration for node with name '" .. name .. "' found")
                return {}
            end
            configs [ #configs + 1 ] = node 
        end
    else
        for _, node in ipairs ( all_configs ) do
            configs [ #configs + 1 ] = node 
        end
    end
    return configs
end

function list_connections ( list )
    local names = {}
    for name, _ in pairs ( list ) do
        names [ #names + 1 ] = name
    end
    return names
end

function get_connections ( list, name )
    return list [ name ]
end

function accesspoints ( nodes, connections )
    local names = list_connections ( connections )
    local aps = {}
    for _, name in ipairs ( names ) do
        aps [ #aps  + 1] = find_node ( name, nodes )
    end
    return aps
end

function stations ( nodes, connections )
    local stations = {}
    for _, stas in pairs ( connections ) do
        for _, name in ipairs ( stas ) do
            stations [ #stations  + 1] = find_node ( name, nodes )
        end
    end
    return stations
end