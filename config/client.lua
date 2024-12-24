return {
    startPosition = {
        coords = vec3(1701.18, 3289.32, 48.6),
        size = vec3(1.85, 1.1, 1.65),
        rotation = 33.75,
    },
    cargoDestination = vec3(-1325.82, -5204.93, 600.0), -- Where the cargoplane will fly to, if it reaches here mission will cancel
    travelSpeed = 100.0, -- The speed the cargoplane will travel at in MPH during its casual flight
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
        },
        crash = { -- Radius blip when the plane crashes
            colour = 49,
            alpha = 150,
            length = 5 * 60000 -- How long until it deletes in MS
        }
    },
    crateHeight = 20.0, -- How high above the plane to spawn crates (better method than groundZ as that native doesn't work in render dist, in prod could implement parachutes on crates or smth)
    crateOffset = { min = -200.0, max = 200.0},
    dropOff = vec4(-1667.04, -887.83, 7.64, 121.99)
}