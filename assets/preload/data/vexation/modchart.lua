local defaultNotePos = {};
local spin = true;
local arrowMoveX = 32;
local arrowMoveY = 32;
local spinning = false

function onSongStart()
    for i = 0,7 do 
        x = getPropertyFromGroup('strumLineNotes', i, 'x')
 
        y = getPropertyFromGroup('strumLineNotes', i, 'y')
 
        table.insert(defaultNotePos, {x,y})
    end
end
 
function onUpdate(elapsed)
    songPos = getPropertyFromClass('Conductor', 'songPosition');
    currentBeat = (songPos / 1000) * (bpm / 60)
 
    for i = 0,7 do 
        setPropertyFromGroup('strumLineNotes', i, 'x', defaultNotePos[i + 1][1] + arrowMoveX * math.sin((currentBeat + i*0.25) * math.pi))
        setPropertyFromGroup('strumLineNotes', i, 'y', defaultNotePos[i + 1][2] + arrowMoveY * math.cos((currentBeat + i*0.25) * math.pi))
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

function onTweenCompleted(tag)
    if tag == 'strums1' then
        spinning = false
    end
end