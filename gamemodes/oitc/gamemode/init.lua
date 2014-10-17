
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( 'shared.lua' )


// Serverside only stuff goes here
// Serversided shit is gay D=

-- Round Start Sounds
resource.AddFile("sound/OIC/RoundStart/Rangers_v2.mp3")
resource.AddFile("sound/OIC/RoundStart/Spetsnaz_v2.mp3")

-- Round End Sounds
resource.AddFile("sound/OIC/Victory/Spetsnaz_v2.mp3")
resource.AddFile("sound/OIC/Victory/Rangers_v2.mp3")
resource.AddFile("sound/OIC/Victory/DrawGame.mp3")

--Generic Sounds

-- Tango Down
resource.AddFile("sound/OIC/Generic/Spetsnaz/TangoDown.mp3")
resource.AddFile("sound/OIC/Generic/Rangers/TangoDown.mp3")

function GM:OnPreRoundStart( num )

	game.CleanUpMap()
	
	UTIL_SpawnAllPlayers()

end


-- Playe The Victory/Draw Sound At The End Of The Round
function GM:OnRoundEnd(round)
	local winner = GetGlobalInt("RoundResult")
	if winner == 2 then
		for i, ply in pairs(player.GetAll()) do
			ply:ConCommand("play OIC/Victory/Rangers_v2.mp3")
			ply:KillSilent()
		end
	elseif winner == 1 then
		for i, ply in pairs(player.GetAll()) do
			ply:ConCommand("play OIC/Victory/Spetsnaz_v2.mp3")
			ply:KillSilent()
		end
	else
		for i, ply in pairs(player.GetAll()) do
			ply:ConCommand("play OIC/Victory/DrawGame.mp3")
			ply:KillSilent()
		end
	end
	
end

function GM:PlayerJoinTeam(ply, teamid) 
	if (!GAMEMODE:InRound()) and ply:Team() == TEAM_UNASSIGNED and (teamid == TEAM_SPETSNAZ or TEAM_RANGERS) then 
		ply:SetTeam(teamid)
	end
	
	if ply:Team() != TEAM_SPECTATOR and teamid == TEAM_SPECTATOR then
		ply:SetTeam(TEAM_SPECTATOR)
		ply:KillSilent()
		ply:StripWeapons()
		ply:ChatPrint(""..ply:Nick()..", you've joined Spectators.")
	end	
	
	if (ply:Team() == TEAM_UNASSIGNED or TEAM_SPECTATOR) and ( GAMEMODE:InRound() ) and GetGlobalFloat("RoundStartTime",CurTime()) - 30 < CurTime() 
		and (teamid == TEAM_SPETSNAZ or TEAM_RANGERS) then
		ply:SetTeam(teamid)
		timer.Simple(1, function()
			ply:Spawn()
			print("Late player successfully spawned.")
		end)
	end	
	if (ply:Team() == TEAM_UNASSIGNED or TEAM_SPECTATOR) and ( GAMEMODE:InRound() ) and GetGlobalFloat("RoundStartTime",CurTime()) + 30 < CurTime()
		and (teamid == TEAM_SPETSNAZ or TEAM_RANGERS) then
		timer.Simple(1, function()
		ply:KillSilent()
		ply:SetTeam(teamid)
		ply:ChatPrint("You'll spawn automatically when next round starts, "..ply:Nick()..".")
		print("Late player has not been spawned.")
		end)
	end
end

function GM:CanStartRound()
	if #team.GetPlayers( TEAM_SPETSNAZ ) + #team.GetPlayers( TEAM_RANGERS ) >= 2 then return true end
	return false
end