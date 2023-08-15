local defaultNotePos = {};
local defaultWindowPos = {};
local spin = true;
local arrowMoveX = 32;
local arrowMoveY = 32;
local windowMoveX = 64;
local windowMoveY = 64;
local spinning = false
local allowCountdown = false
local isWarning = false
function onStartCountdown()
    if not allowCountdown --[[and isStoryMode and not seenCutscene]] then
        setProperty('inCutscene', true)

        makeLuaSprite('warning', 'creepyMessage', 200, 0)
        setScrollFactor('warning', 0, 0)
        setObjectCamera('warning', 'camOther')
        -- screenCenter('warning', 'XY')
        scaleObject('warning', 0.7, 0.7)
        addLuaSprite('warning', true)

        makeLuaSprite('warning2', 'youhavebeenWARNED', 0, 0)
        setScrollFactor('warning2', 0, 0)
        setObjectCamera('warning2', 'camOther')
        screenCenter('warning2', 'XY')
        setProperty('camHUD.visible', false)
        isWarning = true
        playMusic('gameOver', 0.9)
        
        return Function_Stop
    end
    return Function_Continue
end

function onSongStart()
    for i = 0,7 do 
        x = getPropertyFromGroup('strumLineNotes', i, 'x')
 
        y = getPropertyFromGroup('strumLineNotes', i, 'y')
 
        table.insert(defaultNotePos, {x,y})
    end
    windowX = getPropertyFromClass('openfl.Lib', 'application.window.x')
    windowY = getPropertyFromClass('openfl.Lib', 'application.window.y')
    table.insert(defaultWindowPos, {windowX,windowY})

end
 
function onUpdate(elapsed)
    songPos = getPropertyFromClass('Conductor', 'songPosition');
    currentBeat = (songPos / 1000) * (bpm / 60)
 
    if curStep > 1 then
        for i = 0,7 do 
            setPropertyFromGroup('strumLineNotes', i, 'x', defaultNotePos[i + 1][1] + arrowMoveX * math.sin((currentBeat + i*0.25) * math.pi))
            setPropertyFromGroup('strumLineNotes', i, 'y', defaultNotePos[i + 1][2] + arrowMoveY * math.cos((currentBeat + i*0.25) * math.pi))
        end
        for i = 0,7 do 
            setPropertyFromClass('openfl.Lib','application.window.x', defaultWindowPos[i + 1][1] + windowMoveX * math.sin((currentBeat + i*0.25) * math.pi))
            setPropertyFromClass('openfl.Lib','application.window.y', defaultWindowPos[i + 1][2] + windowMoveY * math.cos((currentBeat + i*0.25) * math.pi))
        end
    end
end

function onBeatHit()
    if getRandomBool(15) and not spinning then
        spinning = true
        noteTweenAngle('strums0', 0, getPropertyFromGroup('strumLineNotes', 0, 'angle') + 360, 1, 'cubeInOut')
        noteTweenAngle('strums1', 1, getPropertyFromGroup('strumLineNotes', 1, 'angle') + 360, 1, 'cubeInOut')
        noteTweenAngle('strums2', 2, getPropertyFromGroup('strumLineNotes', 2, 'angle') + 360, 1, 'cubeInOut')
        noteTweenAngle('strums3', 3, getPropertyFromGroup('strumLineNotes', 3, 'angle') + 360, 1, 'cubeInOut')
        noteTweenAngle('strums4', 4, getPropertyFromGroup('strumLineNotes', 4, 'angle') + 360, 1, 'cubeInOut')
        noteTweenAngle('strums5', 5, getPropertyFromGroup('strumLineNotes', 5, 'angle') + 360, 1, 'cubeInOut')
        noteTweenAngle('strums6', 6, getPropertyFromGroup('strumLineNotes', 6, 'angle') + 360, 1, 'cubeInOut')
        noteTweenAngle('strums7', 7, getPropertyFromGroup('strumLineNotes', 7, 'angle') + 360, 1, 'cubeInOut')
    end
end

function onTimerCompleted(tag, loops, loopsLeft)
    if tag == 'y' then
        doTweenAlpha('warning2', 'warning2', 0, 2) 
        isWarning = false
    end
end

function onTweenCompleted(tag)
    if tag == 'strums1' then
        spinning = false
    end
    if tag == 'warning2' then
        startCountdown()
        setProperty('camHUD.visible', true)
    end
end

function onUpdatePost()
    if getPropertyFromClass('flixel.FlxG', 'keys.justPressed.Y') then
        removeLuaSprite('warning')
        addLuaSprite('warning2', true)
        runTimer('y', 1)
        playMusic('gameOverEnd', 0.9)
        allowCountdown = true
        -- startCountdown() 
    end    
    if getPropertyFromClass('flixel.FlxG', 'keys.justPressed.N') and isWarning then
        endSong() 
    end    
end
