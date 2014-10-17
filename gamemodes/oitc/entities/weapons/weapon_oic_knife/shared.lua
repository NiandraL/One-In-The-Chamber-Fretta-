if( SERVER ) then
	AddCSLuaFile( "shared.lua" );
end

if( CLIENT ) then
	SWEP.PrintName = "Knife";
	SWEP.Slot = 3;
	SWEP.SlotPos = 3;
	SWEP.DrawAmmo = false;
	SWEP.DrawCrosshair = false;
end

SWEP.Author			= "Adobe Ninja"
SWEP.Instructions	= "Left click to stab"
SWEP.Contact		= "adobeninja.net"
SWEP.Purpose		= ""

SWEP.ViewModelFOV	= 62
SWEP.ViewModelFlip	= false

SWEP.Spawnable			= false
SWEP.AdminSpawnable		= true

SWEP.NextStrike = 0;
  
SWEP.ViewModel      = "models/weapons/v_knife_t.mdl"
SWEP.WorldModel   = "models/weapons/w_knife_t.mdl"
  
-------------Primary Fire Attributes----------------------------------------
SWEP.Primary.Delay			= 0.9 	--In seconds
SWEP.Primary.Recoil			= 0		--Gun Kick
SWEP.Primary.Damage			= 100	--Damage per Bullet
SWEP.Primary.NumShots		= 1		--Number of shots per one fire
SWEP.Primary.Cone			= 0 	--Bullet Spread
SWEP.Primary.ClipSize		= -1	--Use "-1 if there are no clips"
SWEP.Primary.DefaultClip	= -1	--Number of shots in next clip
SWEP.Primary.Automatic   	= true	--Pistol fire (false) or SMG fire (true)
SWEP.Primary.Ammo         	= "none"	--Ammo Type
 
-------------Secondary Fire Attributes-------------------------------------
SWEP.Secondary.Delay		= 0.9
SWEP.Secondary.Recoil		= 0
SWEP.Secondary.Damage		= 0
SWEP.Secondary.NumShots		= 1
SWEP.Secondary.Cone			= 0
SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic   	= true
SWEP.Secondary.Ammo         = "none"

util.PrecacheSound("weapons/knife/knife_deploy1.wav")
util.PrecacheSound("weapons/knife/knife_hitwall1.wav")
util.PrecacheSound("weapons/knife/knife_hit1.wav")
util.PrecacheSound("weapons/knife/knife_hit2.wav")
util.PrecacheSound("weapons/knife/knife_hit3.wav")
util.PrecacheSound("weapons/knife/knife_hit4.wav")
util.PrecacheSound("weapons/iceaxe/iceaxe_swing1.wav")

function SWEP:Initialize()
	self:SetWeaponHoldType( "knife" );
	self.Hit = { 
	Sound( "weapons/knife/knife_hitwall1.wav" )};
	self.FleshHit = {
  	Sound( "weapons/knife/knife_hit1.wav" ),
	Sound( "weapons/knife/knife_hit2.wav" ),
	Sound( "weapons/knife/knife_hit3.wav" ),
  	Sound( "weapons/knife/knife_hit4.wav" ) };

end

function SWEP:Precache()
end

function SWEP:Deploy()
	self.Owner:EmitSound( "weapons/knife/knife_deploy1.wav" );
	return true;
end

function SWEP:PrimaryAttack()
   self.Weapon:SetNextPrimaryFire( CurTime() + self.Primary.Delay )
   self.Weapon:SetNextSecondaryFire( CurTime() + self.Secondary.Delay )

   if not IsValid(self.Owner) then return end

   self.Owner:LagCompensation(true)

   local spos = self.Owner:GetShootPos()
   local sdest = spos + (self.Owner:GetAimVector() * 70)

   local kmins = Vector(1,1,1) * -10
   local kmaxs = Vector(1,1,1) * 10

   local tr = util.TraceHull({start=spos, endpos=sdest, filter=self.Owner, mask=MASK_SHOT_HULL, mins=kmins, maxs=kmaxs})

   -- Hull might hit environment stuff that line does not hit
   if not IsValid(tr.Entity) then
      tr = util.TraceLine({start=spos, endpos=sdest, filter=self.Owner, mask=MASK_SHOT_HULL})
   end

   local hitEnt = tr.Entity

   -- effects
   if IsValid(hitEnt) then
      self.Weapon:SendWeaponAnim( ACT_VM_HITCENTER )

      local edata = EffectData()
      edata:SetStart(spos)
      edata:SetOrigin(tr.HitPos)
      edata:SetNormal(tr.Normal)
      edata:SetEntity(hitEnt)

      if hitEnt:IsPlayer() or hitEnt:GetClass() == "prop_ragdoll" then
         util.Effect("BloodImpact", edata)
      end
   else
      self.Weapon:SendWeaponAnim( ACT_VM_MISSCENTER )
   end

   if SERVER then
      self.Owner:SetAnimation( PLAYER_ATTACK1 )
   end


   if SERVER and tr.Hit and tr.HitNonWorld and IsValid(hitEnt) then
      if hitEnt:IsPlayer() then
         -- knife damage is never karma'd, so don't need to take that into
         -- account we do want to avoid rounding error strangeness caused by
         -- other damage scaling, causing a death when we don't expect one, so
         -- when the target's health is close to kill-point we just kill
         if hitEnt:Health() < (self.Primary.Damage + 10) then
            self:StabKill(tr, spos, sdest)
         else
            local dmg = DamageInfo()
            dmg:SetDamage(self.Primary.Damage)
            dmg:SetAttacker(self.Owner)
            dmg:SetInflictor(self.Weapon or self)
            dmg:SetDamageForce(self.Owner:GetAimVector() * 5)
            dmg:SetDamagePosition(self.Owner:GetPos())
            dmg:SetDamageType(DMG_SLASH)

            hitEnt:DispatchTraceAttack(dmg, spos + (self.Owner:GetAimVector() * 3), sdest)
         end
      end
   end

   self.Owner:LagCompensation(false)
end

function SWEP:StabKill(tr, spos, sdest)
   local target = tr.Entity

   local dmg = DamageInfo()
   dmg:SetDamage(2000)
   dmg:SetAttacker(self.Owner)
   dmg:SetInflictor(self.Weapon or self)
   dmg:SetDamageForce(self.Owner:GetAimVector())
   dmg:SetDamagePosition(self.Owner:GetPos())
   dmg:SetDamageType(DMG_SLASH)

   -- now that we use a hull trace, our hitpos is guaranteed to be
   -- terrible, so try to make something of it with a separate trace and
   -- hope our effect_fn trace has more luck

   -- first a straight up line trace to see if we aimed nicely
   local retr = util.TraceLine({start=spos, endpos=sdest, filter=self.Owner, mask=MASK_SHOT_HULL})

   -- if that fails, just trace to worldcenter so we have SOMETHING
   if retr.Entity != target then
      local center = target:LocalToWorld(target:OBBCenter())
      retr = util.TraceLine({start=spos, endpos=center, filter=self.Owner, mask=MASK_SHOT_HULL})
   end


   -- create knife effect creation fn
   local bone = retr.PhysicsBone
   local pos = retr.HitPos
   local norm = tr.Normal
   local ang = Angle(-28,0,0) + norm:Angle()
   ang:RotateAroundAxis(ang:Right(), -90)
   pos = pos - (ang:Forward() * 7)

   local prints = self.fingerprints
   local ignore = self.Owner

   target.effect_fn = function(rag)
                         -- we might find a better location
                         local rtr = util.TraceLine({start=pos, endpos=pos + norm * 40, filter=ignore, mask=MASK_SHOT_HULL})

                         if IsValid(rtr.Entity) and rtr.Entity == rag then
                            bone = rtr.PhysicsBone
                            pos = rtr.HitPos
                            ang = Angle(-28,0,0) + rtr.Normal:Angle()
                            ang:RotateAroundAxis(ang:Right(), -90)
                            pos = pos - (ang:Forward() * 10)

                         end

                         local knife = ents.Create("prop_physics")
                         knife:SetModel("models/weapons/w_knife_t.mdl")
                         knife:SetPos(pos)
                         knife:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
                         knife:SetAngles(ang)
                         knife.CanPickup = false

                         knife:Spawn()

                         local phys = knife:GetPhysicsObject()
                         if IsValid(phys) then
                            phys:EnableCollisions(false)
                         end

                         constraint.Weld(rag, knife, bone, 0, 0, true)

                         -- need to close over knife in order to keep a valid ref to it
                         rag:CallOnRemove("ttt_knife_cleanup", function() SafeRemoveEntity(knife) end)
                      end


   -- seems the spos and sdest are purely for effects/forces?
   target:DispatchTraceAttack(dmg, spos + (self.Owner:GetAimVector() * 3), sdest)

   -- target appears to die right there, so we could theoretically get to
   -- the ragdoll in here...
end


function SWEP:SecondaryAttack()
end 
