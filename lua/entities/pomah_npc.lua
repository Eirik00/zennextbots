
AddCSLuaFile()
AddCSLuaFile("cl_entbehaviour.lua")

ENT.Base = "base_nextbot"

ENT.PhysgunDisabled = true
ENT.AutomaticFrameAdvance = false

ENT.JumpSound = Sound("pomah_npc/jump.mp3")
ENT.JumpHighSound = Sound("pomah_npc/jump.mp3")
ENT.TauntSounds = {
	Sound("pomah_npc/attack1.mp3"),
	Sound("pomah_npc/attack2.mp3"),
	Sound("pomah_npc/attack3.mp3")
}
local chaseMusic = Sound("pomah_npc/chase.mp3")

local IsValid = IsValid

if SERVER then -- SERVER --
    include("sv_entbehaviour.lua")
else -- CLIENT --
    
     --[ CHANGE MODEL IMAGE ] --
    local MAT_pomah = Material("npc_pomah/pomah_npc")
    killicon.Add("pomah_npc", "npc_pomah/killicon", color_white)
    language.Add("pomah_npc", "pomah ")

    
    -- [][] IGNORE FROM HERE [][] --
            ENT.RenderGroup = RENDERGROUP_TRANSLUCENT
            include("cl_entbehaviour.lua")

            local panicMusic = nil
            local lastPanic = 0 -- The last time we were in music range of a pomah.


            -- If another pomah comes in range before this delay is up,
            -- the music will continue where it left off.
            local MUSIC_RESTART_DELAY = 2

            -- Beyond this distance, pomahs do not count to music volume.
            local MUSIC_CUTOFF_DISTANCE = 1650

            -- Max volume is achieved when MUSIC_pomah_PANIC_COUNT pomahs are this close,
            -- or an equivalent score.
            local MUSIC_PANIC_DISTANCE = 400

             -- That's a lot of pomah.
            local MUSIC_pomah_PANIC_COUNT = 8

            local MUSIC_pomah_MAX_DISTANCE_SCORE = (MUSIC_CUTOFF_DISTANCE - MUSIC_PANIC_DISTANCE) * MUSIC_pomah_PANIC_COUNT

            --TODO: Why don't these flags show up? Bug? Documentation would be lovely.
            local pomah_npc_music_volume = CreateConVar("pomah_npc_music_volume", 1, bit.bor(FCVAR_DEMO, FCVAR_ARCHIVE), "Maximum music volume when being chased by pomah. (0-1, where 0 is muted)")

            local function updatePanicMusic()
                if #ents.FindByClass("pomah_npc") == 0 then
                    -- Whoops. No need to run for now.
                    DevPrint(4, "Halting music timer.")
                    timer.Remove("pomahPanicMusicUpdate")

                    if panicMusic ~= nil then
                        panicMusic:Stop()
                    end

                    return
                end

                if panicMusic == nil then
                    if IsValid(LocalPlayer()) then
                        panicMusic = CreateSound(LocalPlayer(), chaseMusic)
                        panicMusic:Stop()
                    else
                        return -- No LocalPlayer yet!
                    end
                end

                local userVolume = math.Clamp(pomah_npc_music_volume:GetFloat(), 0, 1)
                if userVolume == 0 or not IsValid(LocalPlayer()) then
                    panicMusic:Stop()
                    return
                end

                local totalDistanceScore = 0
                local nearEntities = ents.FindInSphere(LocalPlayer():GetPos(), 1000)
                for _, ent in pairs(nearEntities) do
                    if IsValid(ent) and ent:GetClass() == "pomah_npc" then
                        local distanceScore = math.max(0, MUSIC_CUTOFF_DISTANCE
                            - LocalPlayer():GetPos():Distance(ent:GetPos()))
                        totalDistanceScore = totalDistanceScore + distanceScore
                    end
                end

                local musicVolume = math.min(1,
                    totalDistanceScore / MUSIC_pomah_MAX_DISTANCE_SCORE)

                local shouldRestartMusic = (CurTime() - lastPanic >= MUSIC_RESTART_DELAY)
                if musicVolume > 0 then
                    if shouldRestartMusic then
                        panicMusic:Play()
                    end

                    if not LocalPlayer():Alive() then
                        -- Quiet down so we can hear pomah taunt us.
                        musicVolume = musicVolume / 4
                    end

                    lastPanic = CurTime()
                elseif shouldRestartMusic then
                    panicMusic:Stop()
                    return
                else
                    musicVolume = 0
                end

                musicVolume = math.max(0.01, musicVolume * userVolume)

                panicMusic:Play()

                -- Just for kicks.
                panicMusic:ChangePitch(math.Clamp(game.GetTimeScale() * 100, 50, 255), 0)
                panicMusic:ChangeVolume(musicVolume, 0)
            end

            local REPEAT_FOREVER = 0
            local function startTimer()
                if not timer.Exists("pomahPanicMusicUpdate") then
                    timer.Create("pomahPanicMusicUpdate", 0.05, REPEAT_FOREVER,
                        updatePanicMusic)
                    --DevPrint(4, "Beginning music timer.")
                end
            end
    --[][] TO HERE [][]--
    
    
    --[ MODEL SIZE ] --
    local SPRITE_SIZE = 128
    function ENT:Initialize()
        self:SetRenderBounds(
            Vector(-SPRITE_SIZE / 2, -SPRITE_SIZE / 2, 0),
            Vector(SPRITE_SIZE / 2, SPRITE_SIZE / 2, SPRITE_SIZE),
            Vector(5, 5, 5)
        )

        startTimer()
    end

    local DRAW_OFFSET = SPRITE_SIZE / 2 * vector_up
    function ENT:DrawTranslucent()
        render.SetMaterial(MAT_pomah)

        -- Get the normal vector from pomah to the player's eyes, and then compute
        -- a corresponding projection onto the xy-plane.
        local pos = self:GetPos() + DRAW_OFFSET
        local normal = EyePos() - pos
        normal:Normalize()
        local xyNormal = Vector(normal.x, normal.y, 0)
        xyNormal:Normalize()

        -- pomah should only look 1/3 of the way up to the player so that they
        -- don't appear to lay flat from above.
        local pitch = math.acos(math.Clamp(normal:Dot(xyNormal), -1, 1)) / 3
        local cos = math.cos(pitch)
        normal = Vector(
            xyNormal.x * cos,
            xyNormal.y * cos,
            math.sin(pitch)
        )

        render.DrawQuadEasy(pos, normal, SPRITE_SIZE, SPRITE_SIZE,
            color_white, 180)
    end

end

--
-- List the NPC as spawnable.
--
list.Set("NPC", "pomah_npc", {
	Name = "pomah", -- ingame npc name
	Class = "pomah_npc", 
	Category = "[TheBoys] RomanBot",
	AdminOnly = true
})
