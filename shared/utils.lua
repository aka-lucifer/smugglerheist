if not IsDuplicityVersion() then
    function GetEntityAndNetIdFromBagName(bagName)
        local netId = tonumber(bagName:gsub('entity:', ''), 10)
    
        local entity = lib.waitFor(function()
            if NetworkDoesEntityExistWithNetworkId(netId) then
                return NetworkGetEntityFromNetworkId(netId)
            end
        end, ('statebag timed out while awaiting entity creation! (%s)'):format(bagName), 10000)
    
        if not entity then
            lib.print.error(('statebag received invalid entity! (%s)'):format(bagName))
            return 0, 0
        end
    
        return entity, netId
    end
end