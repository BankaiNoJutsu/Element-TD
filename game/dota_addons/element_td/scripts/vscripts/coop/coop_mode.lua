-- holds important functions and variables for our cooperative mode

COOP_WAVE = 1 -- the current wave 
CREEPS_PER_WAVE_COOP = 120 -- number of creeps in each wave
CURRENT_WAVE_OBJECT = nil -- maybe should hold the WaveCoop 'object' of the wave that is currently active (can we ever have > 1 waves at once?)

function SpawnWaveCoop()
	-- spawn wave COOP_WAVE
    CURRENT_WAVE_OBJECT = WaveCoop(COOP_WAVE)
    
    -- First wave marks the start of the game
    if START_GAME_TIME == 0 then
        START_GAME_TIME = GameRules:GetGameTime()
    end

    for _, playerID in pairs(playerIDs) do
        local playerData = GetPlayerData(playerID)
        CustomGameEventManager:Send_ServerToAllClients("SetTopBarWaveValue", {playerId = playerID, wave = COOP_WAVE})
        
        -- not sure about these
        playerData.waveObject = CURRENT_WAVE_OBJECT 
        playerData.waveObjects[COOP_WAVE] = CURRENT_WAVE_OBJECT
    end

    -- TODO: boss waves, co-op interest
	CURRENT_WAVE_OBJECT:SpawnWave()
end


function CreateMoveTimerForCreepCoop(creep, sector)
    local destination = EntityEndLocations[sector]
    Timers:CreateTimer(0.1, function()
        if IsValidEntity(creep) and creep:IsAlive() then
            creep:MoveToPosition(destination)
            if (creep:GetAbsOrigin() - destination):Length2D() <= 100 then
                
                -- TODO: make interest work with co-op mode
                --[[
                if GameSettings:GetEndless() ~= "Endless" then
                    InterestManager:PlayerLeakedWave(playerID, creep.waveObject.waveNumber)
                end
                ]]--

                -- Boss Wave leaks = 3 lives
                local lives = 1
                --[[ TODO
                if playerData.completedWaves + 1 >= WAVE_COUNT and not EXPRESS_MODE then
                    lives = 3
                end
                ]]--

                -- Bulky creeps count as 2
                if creep:HasAbility("creep_ability_bulky") then
                    lives = lives * 2
                end

                for _, playerID in pairs(playerIDs) do
                    ReduceLivesForPlayer(playerID, lives)
                end

                creep.recently_leaked = true
                Timers:CreateTimer(10, function()
                    if IsValidEntity(creep) then creep.recently_leaked = nil end
                end)

                FindClearSpaceForUnit(creep, EntityStartLocations[sector], true)
                creep:SetForwardVector(Vector(0, -1, 0))
            end
            return 0.1
        else
            return
        end
    end)
end

function StartBreakTimeCoop(breakTime)
	ElementTD:PrecacheWave(COOP_WAVE)

	local msgTime = 5 -- how long to show the message for
    if (COOP_WAVE - 1) % 5 == 0 and not EXPRESS_MODE then
        breakTime = 30
    end
    -- First boss breaktime 60 seconds
    if not EXPRESS_MODE and COOP_WAVE == WAVE_COUNT and CURRENT_BOSS_WAVE == 0 then
        breakTime = 60
    end
    if msgTime >= breakTime then
        msgTime = breakTime - 0.5
    end

    -- show countdown timer for all players
    Log:debug("Starting co-op break time for wave " .. COOP_WAVE)
   	-- local bShowButton = PlayerResource:GetPlayerCount() == 1 and COOP_WAVE == 1
    CustomGameEventManager:Send_ServerToAllClients("etd_update_wave_timer", {time = breakTime, button = false})

    -- show sector portals
    for i = 1, 6 do
        ShowPortalForSector(i, COOP_WAVE)
    end

	-- set up each individual player
	for _, playerID in pairs(playerIDs) do
		local hero = PlayerResource:GetSelectedHeroEntity(playerID)
		local playerData = GetPlayerData(playerID)

		ShowWaveBreakTimeMessage(playerID, COOP_WAVE, breakTime, msgTime)
		if hero then 
        	hero:RemoveModifierByName("modifier_silence")
    	end

        if PlayerIsAlive(playerID) then

            -- Grant Lumber and Essence to all players the moment the next wave is set
            if WaveGrantsLumber(COOP_WAVE - 1) then
                ModifyLumber(playerID, 1)
                if IsPlayerUsingRandomMode( playerID ) then
                    Notifications:ClearBottom(playerID)
                    local element = GetRandomElementForPlayerWave(playerID, COOP_WAVE - 1)

                    Log:info("Randoming element for player "..playerID..": "..element)

                    if element == "pure" then
                        SendEssenceMessage(playerID, "#etd_random_essence")
                        ModifyLumber(playerID, -1)
                        ModifyPureEssence(playerID, 1)
                        playerData.pureEssenceTotal = playerData.pureEssenceTotal + 1

                        -- Track pure essence purchasing as part of the element order
                        playerData.elementOrder[#playerData.elementOrder + 1] = "Pure"
                        -- Gold bonus for Pure Essence randoming
                        GivePureEssenceGoldBonus(playerID)
                    else
                        -- TODO: no elementals in co-op mode??
                        SendEssenceMessage(playerID, "#etd_random_elemental")
                        --SummonElemental({caster = playerData.summoner, Elemental = element .. "_elemental"})
                    end
                else
                    Log:info("Giving 1 lumber to " .. playerData.name)
                end
            end

            if WaveGrantsEssence(COOP_WAVE - 1) then
                ModifyPureEssence(playerID, 1) 
                Log:info("Giving 1 pure essence to " .. playerData.name)
                playerData.pureEssenceTotal = playerData.pureEssenceTotal + 1
            end
        end
	end

	-- create the timer to wait for wave spawn
    Timers:CreateTimer("SpawnWaveDelayCoop", {
        endTime = breakTime,
        callback = function()

            if COOP_WAVE == WAVE_COUNT and not EXPRESS_MODE then
                CURRENT_BOSS_WAVE = 1
                
                -- TODO: make this work with co-op mode
                --[[
                if PlayerIsAlive(playerID) then
                    Log:info("Spawning the first boss wave for ["..playerID.."]")            
                    playerData.iceFrogKills = 0
                    playerData.bossWaves = CURRENT_BOSS_WAVE
                end
                ShowBossWaveMessage(playerID, CURRENT_BOSS_WAVE)
                UpdateWaveInfo(playerID, wave)
                ]]--
            else
            	Log:info("Spawning co-op wave " .. COOP_WAVE)
            	for _, playerID in pairs(playerIDs) do
					ShowWaveSpawnMessage(playerID, COOP_WAVE) -- show wave spawn message
					UpdateWaveInfo(playerID, COOP_WAVE) -- update wave info
				end
            end

            if COOP_WAVE == 1 then
                EmitAnnouncerSound("announcer_announcer_battle_begin_01")
            end

            -- spawn dat wave
            SpawnWaveCoop() 
        end
    })
end