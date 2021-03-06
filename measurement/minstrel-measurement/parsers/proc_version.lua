
require ('parsers/parsers')


ProcVersion = { lx_version = nil
              , lx_build_user = nil
              , gcc_version = nil
              , system = nil
              , num_cpu = nil
              , smp_enabled = nil
              , preemptive = nil
              , date = nil
              }

function ProcVersion:new (o)
    local o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function ProcVersion:create ()
    local o = ProcVersion:new()
    return o
end

function ProcVersion:__tostring() 
    return "ProcVersion ::"
        .. " lx_version: " .. ( self.lx_version or "none" )
        .. " lx_build_user: " .. ( self.lx_build_user or "none" )
        .. " gcc_version: " .. ( self.gcc_version or "none" )
        .. " system: " .. ( self.system or "none" )
        .. "\n"
        .. " num_cpu: " .. ( tostring ( self.num_cpu ) or "none" )
        .. " smp_enabled: " .. ( tostring ( self.smp_enabled ) or "none" )
        .. " preemptive: " .. ( tostring ( self.preemptive ) or "none" )
        .. " date: " .. ( self.date or "none" )
end

function parse_proc_version ( str )

    local rest = str
    local state
    local num
    local num1
    local num2
    local num3
    local c
    local ide
    local add_chars = {}

    local lx_version = ""
    local lx_build_user
    local gcc_version = ""
    local system
    local num_cpu
    local smp_enabled = false
    local preemptive = false

    state, rest = parse_str ( rest, "Linux version")
    rest = skip_layout ( rest )
    num1, rest = parse_num ( rest )
    state, rest = parse_str ( rest, ".")
    num2, rest = parse_num ( rest )
    state, rest = parse_str ( rest, ".")
    num3, rest = parse_num ( rest )
    lx_version = num1 .. "." .. num2 .. "." .. num3

    c = shead ( rest )
    if ( c == '-' ) then
        rest = stail ( rest )
		local add_chars = {}
		add_chars[1] = '-'
        ide, rest = parse_ide ( rest, add_chars )
        lx_version = lx_version .. "-" .. ide
    end 

    rest = skip_layout ( rest )
    state, rest = parse_str ( rest, "(")
    add_chars[1] = '@'
    lx_build_user, rest = parse_ide ( rest, add_chars )
    state, rest = parse_str ( rest, ")")

    rest = skip_layout ( rest )
    state, rest = parse_str ( rest, "(gcc version ")
    num1, rest = parse_num ( rest )
    state, rest = parse_str ( rest, ".")
    num2, rest = parse_num ( rest )
    state, rest = parse_str ( rest, ".")
    num3, rest = parse_num ( rest )
    gcc_version = num1 .. "." .. num2 .. "." .. num3
    rest = skip_layout ( rest )


    num, rest = parse_num ( rest )
    if ( num ~= nil ) then
        rest = skip_layout ( rest )
    end

    state, rest = parse_str ( rest, "(")
    system, rest = parse_ide ( rest )
    rest = skip_until ( rest, ')' )
    state, rest = parse_str ( rest, ")")
    rest = skip_layout ( rest )
    state, rest = parse_str ( rest, ")")

    state, rest = parse_str ( rest, " #")
    num_cpu, rest = parse_num ( rest )
    rest = skip_layout ( rest )
    smp_enabled, rest = parse_str ( rest, "SMP")
    if ( smp_enabled ) then 
        rest = skip_layout ( rest )
    end
    preemptive, rest = parse_str ( rest, "PREEMPT")
    rest = skip_layout ( rest )

    date = rest

    local proc_version = ProcVersion:create()
    proc_version.lx_version = lx_version
    proc_version.lx_build_user = lx_build_user
    proc_version.gcc_version = gcc_version
    proc_version.system = system
    proc_version.num_cpu = tonumber ( num_cpu )
    proc_version.smp_enabled = smp_enabled
    proc_version.preemptive = preemptive
    proc_version.date = date

    return proc_version
end
