local drain = false
function onCreate()
    if not getPropertyFromClass('ClientPrefs', 'downScroll') then
        makeAnimatedLuaSprite('whittyHand', 'Whitty_Hands', getProperty('healthBar.x') + 150, getProperty('healthBar.y') + 50)
    else
        makeAnimatedLuaSprite('whittyHand', 'Whitty_Hands', getProperty('healthBar.x') - 50, getProperty('healthBarBurn.y') - 350)
    end
    addAnimationByPrefix('whittyHand', 'open', 'open', 24, false)
    addAnimationByPrefix('whittyHand', 'close', 'close', 24, false)
    
    if not getPropertyFromClass('ClientPrefs', 'downScroll') then
        setProperty('whittyHand.angle', 180)
    end
    
    setProperty('whittyHand.flipX', true)
    setObjectCamera('whittyHand', 'camHUD')
    addLuaSprite('whittyHand', true)

    if not getPropertyFromClass('ClientPrefs', 'downScroll') then
        makeAnimatedLuaSprite('whittyHands', 'Whitty_Hands', getProperty('timeBar.x') - 60, getProperty('timeBar.y') - 410)
    else
        makeAnimatedLuaSprite('whittyHands', 'Whitty_Hands', getProperty('timeBar.x') - 60, getProperty('timeBar.y') + 10)
    end
    addAnimationByPrefix('whittyHands', 'open', 'timeBar open', 24, false)
    addAnimationByPrefix('whittyHands', 'close', 'timeBar close', 24, false)
    setObjectCamera('whittyHands', 'camHUD')

    if getPropertyFromClass('ClientPrefs', 'downScroll') then
        setProperty('whittyHands.angle', 180)
    end
    addLuaSprite('whittyHands', true)
end

function onCreatePost()
    if timeBarType == 'Time Left' and not timeBarType == 'Time Elapsed' and not timeBarType == 'Disabled' then
        setPropertyFromClass('ClientPrefs', 'timeBarType', 'Time Elapsed')
    end
end

function onBeatHit()
    if curBeat == 16 then
        if not getPropertyFromClass('ClientPrefs', 'downScroll') then
            trigger(-130, 0.41)
        else
            trigger(230, 0.41)
        end
    elseif curBeat == 32 then
        if not getPropertyFromClass('ClientPrefs', 'downScroll') then
            trigger(-130, 0.41)
        else
            trigger(230, 0.41)
        end
    elseif curBeat == 204 then
        if not getPropertyFromClass('ClientPrefs', 'downScroll') then
            trigger(-130, 0.41)
        else
            trigger(230, 0.41)
        end    
    elseif curBeat == 264 then
        if not getPropertyFromClass('ClientPrefs', 'downScroll') then
            trigger(-130, 0.41)
        else
            trigger(230, 0.41)
        end
    elseif curBeat == 604 then
        if not getPropertyFromClass('ClientPrefs', 'downScroll') then
            trigger(-130, 0.41)
        else
            trigger(230, 0.41)
        end
    elseif curBeat == 680 then
        if not getPropertyFromClass('ClientPrefs', 'downScroll') then
            trigger(-130, 0.41)
        else
            trigger(230, 0.41)
        end
    elseif curBeat == 764 then
        if not getPropertyFromClass('ClientPrefs', 'downScroll') then
            trigger(-130, 0.41)
        else
            trigger(230, 0.41)
        end
    elseif curBeat == 956 then
        if not getPropertyFromClass('ClientPrefs', 'downScroll') then
            trigger(-130, 0.41)
        else
            trigger(230, 0.41)
        end
    end
end

function trigger(y, time)
    doTweenY('hande', 'whittyHand', getProperty('whittyHand.y') + y, time, 'cubeInOut')
end

function reset()
    if not getPropertyFromClass('ClientPrefs', 'downScroll') then
        doTweenY('hand4', 'whittyHand', getProperty('whittyHand.y') + 100, 0.41, 'cubeInOut')
        setProperty('whittyHand.offset.y', -30)
    else
        doTweenY('hand4', 'whittyHand', getProperty('whittyHand.y') - 200, 0.41, 'cubeInOut')
        setProperty('whittyHand.offset.y', 30)
    end
    
    doTweenAngle('hand4.5', 'whittyHand', getProperty('whittyHand.angle') -8, 0.4)
    doTweenAngle('healthBar1', 'healthBar', getProperty('healthBar.angle') -8, 0.4, 'cubeInOut')
    doTweenAngle('healthBarBG1', 'healthBarBG', getProperty('healthBarBG.angle') -8, 0.4, 'cubeInOut')
    doTweenAngle('healthBarBG1', 'healthBarBurn', getProperty('healthBarBurn.angle') -8, 0.4, 'cubeInOut')
    doTweenAngle('iconP11', 'iconP1', getProperty('iconP1.angle') -8, 0.4, 'cubeInOut')
    doTweenAngle('iconP21', 'iconP2', getProperty('iconP2.angle') -8, 0.4, 'cubeInOut')
    objectPlayAnimation('whittyHand', 'open')
end

function onTweenCompleted(tag)
    if tag == 'hands' then
        runTimer('wait', 0.1)
    end
    if tag == 'hande' then
        objectPlayAnimation('whittyHand', 'close')
        if not getPropertyFromClass('ClientPrefs', 'downScroll') then
            setProperty('whittyHand.offset.y', 30)
        else
            setProperty('whittyHand.offset.y', - 10)
        end
        runTimer('hand2', 0.5)
    end
    if tag == 'hand3.5' then
        drain = true
    end
    if tag == 'hand4' then
        triggered = false
    end
end

function onUpdate(elapsed)
    if drain then
        setProperty('health', getProperty('health') -0.006)
    end
end

function onTimerCompleted(tag)
    if tag == 'hand2' then
        if not getPropertyFromClass('ClientPrefs', 'downScroll') then
            doTweenY('hand3', 'whittyHand', getProperty('whittyHand.y') +30, 0.4, 'cubeInOut')
        else
            doTweenY('hand3', 'whittyHand', getProperty('whittyHand.y') -20, 0.4, 'cubeInOut')
        end

        doTweenAngle('hand3.5', 'whittyHand', getProperty('whittyHand.angle') +8, 0.4)
        doTweenAngle('healthBar', 'healthBar', getProperty('healthBar.angle') +8, 0.4, 'cubeInOut')
        doTweenAngle('healthBarBG', 'healthBarBG', getProperty('healthBarBG.angle') +8, 0.4, 'cubeInOut')
        doTweenAngle('healthBarBG', 'healthBarBurn', getProperty('healthBarBurn.angle') +8, 0.4, 'cubeInOut')
        doTweenAngle('iconP1', 'iconP1', getProperty('iconP1.angle') +8, 0.4, 'cubeInOut')
        doTweenAngle('iconP2', 'iconP2', getProperty('iconP2.angle') +8, 0.4, 'cubeInOut')
    end
    if tag == 'wait' then
        objectPlayAnimation('whittyHands', 'close')
        if not getPropertyFromClass('ClientPrefs', 'downScroll') then
            setProperty('whittyHands.offset.y', - 30)
        else
            setProperty('whittyHands.offset.y', 30)
        end
        runTimer('wait2', 0.3)
    end
    if tag == 'wait2' then
        if not getPropertyFromClass('ClientPrefs', 'downScroll') then
            grabAndPull(-210, 0.9, 'cubeInOut')
            doTweenY('timeBar', 'timeBar', getProperty('whittyHands.y') - 25, 0.9, 'cubeInOut')
            doTweenY('timeTxt', 'timeTxt', getProperty('whittyHands.y') - 25, 0.9, 'cubeInOut')
        else
            grabAndPull(210, 0.9, 'cubeInOut')
            doTweenY('timeBar', 'timeBar', getProperty('timeBar.y') + 150, 0.9, 'cubeInOut')
            doTweenY('timeTxt', 'timeTxt', getProperty('timeTxt.y') + 150, 0.9, 'cubeInOut')
        end
    end
end

function onSongStart()
    if not getPropertyFromClass('ClientPrefs', 'downScroll') then
        grabAndPull(210, 0.5, 'cubeInOut')
    else
        grabAndPull(-100, 0.5, 'cubeInOut')
    end
end

function grabAndPull(y, time, ease)
    doTweenY('hands', 'whittyHands', getProperty('whittyHands.y') + y, time, ease)
end

function goodNoteHit(id, noteData, noteType, isSustainNote)
	if noteType == 'Healthdrain Stopper' then
        drain = false
        reset()
	end
end