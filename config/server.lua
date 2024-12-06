return {
    requiredPolice = 0, -- How many police required in order to start the mission
    missionCost = 100, -- How much the mission costs to start it
    paymentType = "cash", -- How players will pay for the heist (supports cash or bank)
    missionPlane = {
        coords = vec4(1718.47, 3254.59, 41.32, 104.0),
        model = `vestra`,
        taskInterval = 1000 -- How often to check if the mission plane isn't destroyed
    },
    cargoSpawn = vec4(-309.05, 7903.28, 600.78, 170.4), -- Where the cargoplane spawns
    distanceThreshold = 100.0, -- How close the plane has to be to the cargoplane to dispatch jets
    height = {
        distance = 170.0, -- How close you have to be in order for height to be detected
        threshold = -20.0 -- How high up alongside the distance you have to be, to be detected
    },
    jetTaskInterval = 2000, -- Don't lower too much or it will lag your server
    warningCount = 3, -- How many warnings to give them before jets are dispatched
    resetWarnings = true, -- Reset warnings if you are no longer too close/high and you haven't hit the max warning count
    planeSeats = 4, -- How many seats the plane has, edit as needed
    jetCount = 2, -- How many jets to dispatch when you trigger them
    jetSpawnOffset = 300.0, -- What random offset to use when spawning jets
    crateItems = {
        { item = "goldbar", amount = 3 },
        { item = "weapon_carbinerifle", amount = 2 }
    },
    reward = 60000 -- How much you get for sucessfully finishing the heist
}