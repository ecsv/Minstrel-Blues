
local argparse = require "argparse"

require ('Measurement')

require ('FXsnrAnalyser')
require ('SNRRenderer')

local parser = argparse("netRun", "Run minstrel blues multi AP / multi STA mesurement")

parser:argument("input", "measurement / analyse data directory","/tmp")

local args = parser:parse()

local measurements = {}

for _, name in ipairs ( ( scandir ( args.input ) ) ) do

    if ( name ~= "." and name ~= ".."  and isDir ( args.input .. "/" .. name ) ) then
                       
        --if ( Config.find_node ( name, nodes ) ~= nil ) then
        local measurement = Measurement.parse ( name, args.input )
        measurements [ #measurements + 1 ] = measurement
        print ( measurement:__tostring () )
        --end
    end
end

print ("Analyse and plot SNR")
for _, measurement in ipairs ( measurements ) do

    local analyser = FXsnrAnalyser:create ()
    analyser:add_measurement ( measurement )
    local snrs = analyser:snrs ()
    pprint ( snrs )
    --print ( )

    local renderer = SNRRenderer:create ( snrs )

    local dirname = args.input .. "/" .. measurement.node_name
    renderer:run ( dirname )

end
