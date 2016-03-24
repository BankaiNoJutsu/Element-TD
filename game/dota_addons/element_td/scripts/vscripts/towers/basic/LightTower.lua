-- Light tower class

LightTower = createClass({
        tower = nil,
        towerClass = "",

        constructor = function(self, tower, towerClass)
            self.tower = tower
            self.towerClass = towerClass or self.towerClass
        end
    },
    {
        className = "LightTower"
    },
nil)

function LightTower:OnAttackStart(keys)
    local target = keys.target
    
    if target:entindex() == self.last_target_index then
        self.consecutiveAttacks = self.consecutiveAttacks + 1
        if self.consecutiveAttacks == 1 then
            self.ability:ApplyDataDrivenModifier(self.tower, self.tower, "modifier_intensity_indicator", {})    
        end
        self.tower:SetModifierStackCount("modifier_intensity_indicator", self.ability, self.consecutiveAttacks)

        local newDamage = self.baseDamage + (self.consecutiveAttacks * self.damagePerAttack)
        self.tower:SetBaseDamageMax(newDamage)
        self.tower:SetBaseDamageMin(newDamage)
        
        -- this tower gains a "glow particle" every 3 consecutive attacks, capped at 3 instances
        if #self.particles < math.min(3, math.floor(self.consecutiveAttacks / 3)) then
            local particle = ParticleManager:CreateParticle(self.particleName, PATTACH_ABSORIGIN_FOLLOW, self.tower)
            ParticleManager:SetParticleControl(particle, 0, self.tower:GetOrigin())
            table.insert(self.particles, particle)
        end
    else
        self.consecutiveAttacks = 0
        self.last_target_index = target:entindex()
        self.tower:RemoveModifierByName("modifier_intensity_indicator")
        self.tower:SetBaseDamageMax(self.baseDamage)
        self.tower:SetBaseDamageMin(self.baseDamage)
       
        for _, particle in pairs(self.particles) do
            ParticleManager:DestroyParticle(particle, false)
        end
        self.particles = {}
    end
end

function LightTower:OnAttackLanded(keys)
    local target = keys.target
    local damage = self.tower:GetAverageTrueAttackDamage()
    DamageEntity(target, self.tower, damage)
    
    if self.consecutiveAttacks > 0 then
        PopupLightDamage(self.tower, math.floor(damage))
    end
end

function LightTower:OnCreated()
    self.ability = AddAbility(self.tower, "light_tower_intensity", self.tower:GetLevel())
    self.damagePerAttack = self.ability:GetSpecialValueFor("damage") 
    self.baseDamage = self.tower:GetBaseDamageMax() 
    self.consecutiveAttacks = 0  
    self.particles = {}
    self.particleName = "particles/units/heroes/hero_keeper_of_the_light/keeper_of_the_light_spirit_form_ambient.vpcf"
end

RegisterTowerClass(LightTower, LightTower.className)