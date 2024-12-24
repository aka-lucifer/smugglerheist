return {
    debug = true,
    hackDistance = 200.0, -- How close you have to be for hacking to be viable
    bombPlacementOffsets = {
        { -- Left Wing
            attach = vec3(29.8, 2.0, 1.2),
            explode = vec3(-29.0, -7.0, 1.16)
        },
        { -- Right Wing
            attach = vec3(-27.5 , 11.5, 1.3),
            explode = vec3(29.0, -7.0, 1.16)
        },
    },
    crateCount = 4, -- How many crates to spawn when the plane crashes
}