return {
    debug = true,
    hackDistance = 200.0, -- How close you have to be for hacking to be viable
    bombPlacementOffsets = {
        { -- Left Wing
            attach = vec3(27.0, 2.0, 1.4),
            explode = vec3(-29.0, -7.0, 1.16)
        },
        { -- Right Wing
            attach = vec3(-27.0, 13.0, 1.3),
            explode = vec3(29.0, -7.0, 1.16)
        },
    },
    crateOffsets = { -- Offsets where to spawn the crates inside the cargoplane
        vec3(-1.7, 25.7, 0.0), -- FL
        vec3(1.6, 26.0, 0.0), -- FR
        vec3(-1.9, 2.4, 0.0), -- RL
        vec3(1.9, 2.5, 0.0) -- RR
    }
}