local checkluatype = SF.CheckLuaType

--- Express Library for interacting with the Express Service
-- @name express
-- @class library
-- @libtbl express_library
SF.RegisterLibrary( "express" )

return function( instance )

local express_library = instance.Libraries.express
local sanitize, unsanitize = instance.Sanitize, instance.Unsanitize
local ply_wrap, ply_unwrap = instance.Types.Player.Wrap, instance.Types.Player.Unwrap

--- Similar to net.receive, attaches a callback function to a given message name.
-- @shared
-- @param string name The name of the message. (Case insensitive)
-- @param function callback The function to call when data comes through for this message. This function received a table of data on the client and on the server, the player who sent the message followed by said table.
function express_library.receive( name, callback )
    checkluatype( name, TYPE_STRING )
    checkluatype( callback, TYPE_FUNCTION )

    local wrapper

    if SERVER then
        wrapper = function( player, data )
            return instance:runFunction( callback, ply_wrap( player ), sanitize( data ) )
        end
    else
        wrapper = function( data )
            return instance:runFunction( callback, sanitize( data ) )
        end
    end

    express.Receive( name, wrapper )
end

--- Sends an arbitrary table of data and runs the given callback upon arrival.
-- @shared
-- @param string name The name of the message. (Case insensitive)
-- @param table data The table of data to send.
-- @param function callback The callback function to call when the message has reached its destination.
-- @param Player|table|nil recipients (Optional and SERVER only) A player or table of players to send the message to.
function express_library.send( name, data, callback, recipients )
    checkluatype( name, TYPE_STRING )
    checkluatype( data, TYPE_TABLE )
    checkluatype( callback, TYPE_FUNCTION )

    local unwrapped_data = unsanitize( data )

    local function wrapper( ... )
        return instance:runFunction( callback, ... )
    end

    if SERVER then
        if recipients then
            local unwrapped_recipients

            if instance.IsSFType( recipients ) then
                unwrapped_recipients = ply_unwrap( recipients )
            else
                unwrapped_recipients = unsanitize( recipients )
            end

            express.Send( name, unwrapped_data, unwrapped_recipients, wrapper )
        else
            express.Broadcast( name, unwrapped_data, wrapper )
        end
    else
        express.Send( name, unwrapped_data, wrapper )
    end
end

end
