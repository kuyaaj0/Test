twistLeft = true;
noteMax = 8
--Bopping on beat
function onBeatHit()

    if (curBeat >= 64 and curBeat < 92) or (curBeat >= 96 and curBeat < 128) then
        if twistLeft == true then        
            for i=0, noteMax, 1 do
                noteTweenAngle('note' .. i, i, 25, 0.15, 'quadInOut')
            end
            twistLeft = false;        
        elseif twistLeft == false then
            for i=0, noteMax, 1 do
                noteTweenAngle('note' .. i, i, -25, 0.15, 'quadInOut')
            end  
            twistLeft = true;
            
        end
    end
    if curBeat == 93 or curBeat == 129 then
        noteTweenAngle('noter' .. i, i, 0, 0.5, 'quadInOut')
    end 

end

function onTweenCompleted(tag)
    for i=0, noteMax, 1 do
        if tag == 'note' ..i then
            noteTweenAngle('noteEnd' .. i, i, 0, 0.15, 'quadInOut')
        end
    end
end

function onCreate()
    for i= 0, noteMax, 1 do
        setPropertyFromGroup('strumLineNotes', i, 'alpha', 0)
    end
end

function onStepHit()
    if curStep == 1 then
        noteY = getPropertyFromGroup('strumLineNotes', i, 'y')
        noteTweenAlpha('note', 0, 1, 1)
        if not getPropertyFromClass('ClientPrefs', 'downScroll') then
            noteTweenY('noteY', 0, noteY + 20, 1, 'cubeOut')
        else
            noteTweenY('noteY', 0, noteY - 20, 1, 'cubeOut')
        end
    elseif curStep == 16 then
        noteTweenAlpha('note', 7, 1, 1)
        if not getPropertyFromClass('ClientPrefs', 'downScroll') then
            noteTweenY('noteY', 7, noteY + 20, 1, 'cubeOut')
        else
            noteTweenY('noteY', 7, noteY - 20, 1, 'cubeOut')
        end
    elseif curStep == 32 then
        noteTweenAlpha('note', 1, 1, 1)
        if not getPropertyFromClass('ClientPrefs', 'downScroll') then
            noteTweenY('noteY', 1, noteY + 20, 1, 'cubeOut')
        else
            noteTweenY('noteY', 1, noteY - 20, 1, 'cubeOut')
        end
    elseif curStep == 48 then
        noteTweenAlpha('note', 6, 1, 1)
        if not getPropertyFromClass('ClientPrefs', 'downScroll') then
            noteTweenY('noteY', 6, noteY + 20, 1, 'cubeOut')
        else
            noteTweenY('noteY', 6, noteY - 20, 1, 'cubeOut')
        end
    elseif curStep == 64 then
        noteTweenAlpha('note', 2, 1, 1)
        if not getPropertyFromClass('ClientPrefs', 'downScroll') then
            noteTweenY('noteY', 2, noteY + 20, 1, 'cubeOut')
        else
            noteTweenY('noteY', 2, noteY - 20, 1, 'cubeOut')
        end
    elseif curStep == 80 then
        noteTweenAlpha('note', 5, 1, 1)
        if not getPropertyFromClass('ClientPrefs', 'downScroll') then
            noteTweenY('noteY', 5, noteY + 20, 1, 'cubeOut')
        else
            noteTweenY('noteY', 5, noteY - 20, 1, 'cubeOut')
        end
    elseif curStep == 96 then
        noteTweenAlpha('note', 3, 1, 1)
        if not getPropertyFromClass('ClientPrefs', 'downScroll') then
            noteTweenY('noteY', 3, noteY + 20, 1, 'cubeOut')
        else
            noteTweenY('noteY', 3, noteY - 20, 1, 'cubeOut')
        end
    elseif curStep == 112 then
        noteTweenAlpha('note', 4, 1, 1)
        if not getPropertyFromClass('ClientPrefs', 'downScroll') then
            noteTweenY('noteY', 4, noteY + 20, 1, 'cubeOut')
        else
            noteTweenY('noteY', 4, noteY - 20, 1, 'cubeOut')
        end
    end
end
--[[Squeak Notes

if curStep == 504 then
    doTweenZoom('popZoom', 'camGame', 1, 1, 'bounceOut');
end

    if curStep % 2 == 0 then
        if (508 > curStep and curStep > 479) then
            if upUp == false then
                for i=0, noteMax, 1
                    do
                        if (i % 2 == 0) then 
                            noteTweenY('noteY' .. i, i, defaultPlayerStrumY0 + 15, 0.05, 'quadInOut')
                            else
                            noteTweenY('noteY' .. i, i, defaultPlayerStrumY0 - 15, 0.05, 'quadInOut')
                            end
                    end
                upUp = true
            else
                for i=0, noteMax, 1
                    do
                        if (i % 2 == 0) then 
                            noteTweenY('noteY' .. i, i, defaultPlayerStrumY0 - 15, 0.05, 'quadInOut')
                            else
                            noteTweenY('noteY' .. i, i, defaultPlayerStrumY0 + 15, 0.05, 'quadInOut')
                            end
                    end
                    upUp = false
            end
        end
    end

    --Revert Squeak Notes
    if curStep == 509 then
        for i=0, noteMax, 1
        do
        noteTweenY('returnnoteY' .. i, i, defaultPlayerStrumY0, 0.8, 'elasticOut');
        end
    end
end]]--