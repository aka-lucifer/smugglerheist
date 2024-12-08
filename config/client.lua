return {
    startPosition = {
        coords = vec3(1701.18, 3289.32, 48.6),
        size = vec3(1.85, 1.1, 1.65),
        rotation = 33.75,
    },
    cargoDestination = vec3(-1325.82, -5204.93, 600.0), -- Where the cargoplane will fly to, if it reaches here mission will cancel
    travelSpeed = 600.0, -- The speed the cargoplane will travel at in MPH during its casual flight
    hackedSpeed = 30.0, -- The speed the cargoplane will travel at in MPH once hacked
    blip = {
        cargoplane = {
            sprite = 307,
            colour = 1,
            name = "Cargo Plane"
        },
        jet = {
            sprite = 16,
            colour = 1,
            name = "Escort Jet"
        }
    },
    crateOffset = { min = -200.0, max = 200.0}, -- How far away for 
    flatRotation = vec3(2.036057, -0.087843, -104.172180),
    cargoRearDoorId = 2, -- The hatch door ID of the cargoplane
    cargoCockpitDoorId = 4, -- The front cockpit part door ID of the cargoplane
    dropOff = vec4(-1667.04, -887.83, 7.64, 121.99)
}