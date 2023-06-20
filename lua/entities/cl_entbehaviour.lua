if CLIENT then
    local developer = GetConVar("developer")
    function DevPrint(devLevel, msg)
        if developer:GetInt() >= devLevel then
            print("tbois_npc: " .. msg)
        end
    end

    
    
    surface.CreateFont("penHUD", {
        font = "Arial",
        size = 56
    })

    surface.CreateFont("penHUDSmall", {
        font = "Arial",
        size = 24
    })

    local function string_ToHMS(seconds)
        local hours = math.floor(seconds / 3600)
        local minutes = math.floor((seconds / 60) % 60)
        local seconds = math.floor(seconds % 60)

        if hours > 0 then
            return string.format("%02d:%02d:%02d", hours, minutes, seconds)
        else
            return string.format("%02d:%02d", minutes, seconds)
        end
    end

    local flavourTexts = {
        {
            "Gotta learn fast!",
            "Learning this'll be a piece of cake!",
            "This is too easy."
        }, {
            "This must be a big map.",
            "This map is a bit bigger than I thought.",
        }, {
            "Just how big is this place?",
            "This place is pretty big."
        }, {
            "This place is enormous!",
            "A guy could get lost around here."
        }, {
            "Surely I'm almost done...",
            "There can't be too much more...",
            "This isn't gm_bigcity, is it?",
            "Is it over yet?",
            "You never told me the map was this big!"
        }
    }
    local SECONDS_PER_BRACKET = 300 -- 5 minutes
    local color_yellow = Color(255, 255, 80)
    local flavourText = ""
    local lastBracket = 0
    local generateStart = 0
    local function navGenerateHUDOverlay()
        draw.SimpleTextOutlined("pen is studying this map.", "penHUD",
            ScrW() / 2, ScrH() / 2, color_white,
            TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 2, color_black)
        draw.SimpleTextOutlined("Please wait...", "penHUD",
            ScrW() / 2, ScrH() / 2, color_white,
            TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 2, color_black)

        local elapsed = SysTime() - generateStart
        local elapsedStr = string_ToHMS(elapsed)
        draw.SimpleTextOutlined("Time Elapsed:", "penHUDSmall",
            ScrW() / 2, ScrH() * 3/4, color_white,
            TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, 1, color_black)
        draw.SimpleTextOutlined(elapsedStr, "penHUDSmall",
            ScrW() / 2, ScrH() * 3/4, color_white,
            TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, 1, color_black)

        -- It's taking a while.
        local textBracket = math.floor(elapsed / SECONDS_PER_BRACKET) + 1
        if textBracket ~= lastBracket then
            flavourText = table.Random(flavourTexts[math.min(5, textBracket)])
            lastBracket = textBracket
        end
        draw.SimpleTextOutlined(flavourText, "penHUDSmall",
            ScrW() / 2, ScrH() * 4/5, color_yellow,
            TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    end

    net.Receive("pen_navgen", function()
        local startSuccess = net.ReadBool()
        if startSuccess then
            generateStart = SysTime()
            lastBracket = 0
            hook.Add("HUDPaint", "penNavGenOverlay", navGenerateHUDOverlay)
        else
            Derma_Message([[Oh no. pen doesn't even know where to start with \z
            this map.\n\z
            If you're not running the Sandbox gamemode, switch to that and try \z
            again.]], "Error!")
        end
    end)

    local nagMe = true

    local function requestNavGenerate()
        RunConsoleCommand("tbois_npc_learn")
    end

    local function stopNagging()
        nagMe = false
    end

    local function navWarning()
        Derma_Query([[It will take a while (possibly hours) for pen to figure \z
            this map out.\n\z
            While he's studying it, you won't be able to play,\n\z
            and the game will appear to have frozen/crashed.\n\z
            \n\z
            Also note that THE MAP WILL BE RESTARTED.\n\z
            Anything that has been built will be deleted.]], "Warning!",
            "Go ahead!", requestNavGenerate,
            "Not right now.", nil)
    end

    net.Receive("pen_nag", function()
        if not nagMe then return end

        if game.SinglePlayer() then
            Derma_Query([[Uh oh! pen doesn't know this map.\n\z
                Would you like him to learn it?]],
                "This map is not yet pen-compatible!",
                "Yes", navWarning,
                "No", nil,
                "No. Don't ask again.", stopNagging)
        else
            Derma_Query([[Uh oh! pen doesn't know this map. \z
                He won't be able to move!\n\z
                Because you're not in a single-player game, he isn't able to \z
                learn it.\n\z
                \n\z
                Ask the server host about teaching this map to pen.\n\z
                \n\z
                If you ARE the server host, you can run tbois_npc_learn over \z
                rcon.\n\z
                Keep in mind that it may take hours during which you will be \z
                unable\n\z
                to play, and THE MAP WILL BE RESTARTED.",
                "This map is currently not pen-compatible!]],
                "Ok", nil,
                "Ok. Don't say this again.", stopNagging)
        end
    end)
end
