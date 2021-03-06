modifier_spring_forward = class({})

function modifier_spring_forward:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
	}
end

function modifier_spring_forward:OnCreated()
    if self:GetAbility() then
       self.attack_speed_bonus = self:GetAbility():GetSpecialValueFor("attack_speed")
       self.level = self:GetAbility():GetLevel()
    else
        self.attack_speed_bonus = 15
        self.level = 1
    end
end

function modifier_spring_forward:GetModifierAttackSpeedBonus_Constant()
	return self.attack_speed_bonus
end

function modifier_spring_forward:GetTexture()
    return "towers/well"
end

function modifier_spring_forward:GetEffectName()
	return "particles/custom/towers/well/spring_forward.vpcf"
end

function modifier_spring_forward:GetEffectAttachType()
	return PATTACH_ABSORIGIN
end