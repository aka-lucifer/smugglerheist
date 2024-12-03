return {
    spawnCoords = vec4(-309.05, 7903.28, 600.78, 170.4),
    crateOffsets = {
        vec3(-1.7, 25.7, 0.0), -- FL
        vec3(1.6, 26.0, 0.0), -- FR
        vec3(-1.9, 2.4, 0.0), -- RL
        vec3(1.9, 2.5, 0.0) -- RR
    },
    destinationCoords = vec3(-1325.82, -5204.93, 866.37), -- Where the plane will fly to, if it reaches here mission will cancel
    distanceThreshold = 150.0, -- How close the plane has to be to the cargoplane to dispatch jets
    height = {
        distance = 200.0, -- How close you have to be in order for height to be detected
        threshold = 50.0 -- How high up alongside the distance you have to be, to be detected
    },
    jetTaskInterval = 2000 -- Don't lower too much or it will lag your server
}