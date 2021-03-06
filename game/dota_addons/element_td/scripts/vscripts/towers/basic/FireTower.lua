-- Fire tower class

FireTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower
            self.towerClass = towerClass or self.towerClass
        end
    },
    {
        className = "FireTower"
    },
nil)

--[[ Will get toggle targeting to work later.
function FireTower:OnAbilityToggle(keys)
    if self.tower:IsAlive() then
        self.tower.toggled = not self.tower.toggled
    end

    if self.tower:HasModifier("modifier_attack_targeting") then
        self.tower:RemoveModifierByName("modifier_attack_targeting")
    end

    self.tower:AddNewModifier(self.tower, nil, "modifier_attack_targeting", {
        target_type = tonumber(keys.target_type), 
        keep_target = tonumber(keys.keep_target)
    })
end

function FireTower:GetUpgradeData()
    return { 
        toggle = self.tower.toggled
    }
end

function FireTower:ApplyUpgradeData(data)
    if data.toggle then
        self.tower.toggled = true
        self.ability:ToggleAbility()
    end
end
]]

function FireTower:OnAttackLanded(keys)
    local target = keys.target
    
    if target:entindex() == self.last_target_index then
        self.consecutiveAttacks = self.consecutiveAttacks + 1
        if self.consecutiveAttacks == 1 then
            self.ability:ApplyDataDrivenModifier(self.tower, self.tower, "modifier_blazeit", {})    
        end
        self.tower:SetModifierStackCount("modifier_blazeit", self.ability, self.consecutiveAttacks)
        PopupNapalmBonusDamage(self.tower, self.consecutiveAttacks * self.aoeGrowth)
    else
        self.consecutiveAttacks = 0
        self.last_target_index = target:entindex()
        self.tower:RemoveModifierByName("modifier_blazeit")
    end

    local damage = self.tower:GetAverageTrueAttackDamage(target)

    DamageEntitiesInArea(target:GetOrigin(), self.halfAOE + (self.consecutiveAttacks * self.aoeGrowth), self.tower, damage / 2)
    DamageEntitiesInArea(target:GetOrigin(), self.fullAOE + (self.consecutiveAttacks * (self.aoeGrowth/2)), self.tower, damage / 2)

    self.ability:ApplyDataDrivenModifier(self.tower, self.tower, "modifier_blazeit", {})
end

--[[ Removed in 1.15, applied to Poison Tower
function FireTower:DealBlazeDamage(keys)
    local target = keys.target    
    local damage = ApplyAbilityDamageFromModifiers(self.damage_per_interval, self.tower)    
    DamageEntity(target, self.tower, damage)
end
    ]]

function FireTower:OnCreated()
    self.tower:AddNewModifier(self.tower, nil, "modifier_attack_targeting", {target_type=TOWER_TARGETING_HIGHEST_HP, keep_target=true}) -- {target_type=TOWER_TARGETING_HIGHEST_HP, keep_target=true})
    self.fullAOE =  tonumber(GetUnitKeyValue(self.towerClass, "AOE_Full"))
    self.halfAOE =  tonumber(GetUnitKeyValue(self.towerClass, "AOE_Half"))
    self.ability = AddAbility(self.tower, "fire_tower_blaze", self.tower:GetLevel())
    self.aoeGrowth = self.ability:GetLevelSpecialValueFor("aoe", self.ability:GetLevel()-1)
    self.modifier_name = "modifier_blazeit" --420
    self.consecutiveAttacks = 0 

--[[ Will get toggle targeting to work later
    self:OnAbilityToggle({target_type = TOWER_TARGETING_HIGHEST_HP,keep_target=true}) -- set default targeting mode
    self.tower.toggled = false
	]]

--[[ Removed in 1.15, applied to Poison Tower
    self.interval = 0.5 --taken from the modifier ThinkInterval value
    self.damage_per_interval = self.ability:GetLevelSpecialValueFor("damage_per_second", self.tower:GetLevel()-1) * self.interval

    self.tower:AddNewModifier(self.tower, nil, "modifier_attack_targeting", {target_type=TOWER_TARGETING_CLOSEST})
    ]]
end

RegisterTowerClass(FireTower, FireTower.className)
