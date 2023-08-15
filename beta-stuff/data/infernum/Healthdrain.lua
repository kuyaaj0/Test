local drain = false
function onCreate()
    makeAnimatedLuaSprite('whittyHand', 'stage/Whitty_Hands', getProperty('healthBar.x') + 150, getProperty('healthBar.y') + 50)
    addAnimationByPrefix('whittyHand', 'open', 'open', 24, false)
    addAnimationByPrefix('whittyHand', 'close', 'close', 24, false)
    setProperty('whittyHand.angle', 180)
    setProperty('whittyHand.flipX', true)
    setObjectCamera('whittyHand', 'camHUD')
    addLuaSprite('whittyHand', true)
end

function onBeatHit()
    if curBeat == 16 then
        trigger(-130, 0.41)
    elseif curBeat == 32 then
        trigger(-130, 0.41)
    end
end

function trigger(y, time)
    doTweenY('hand', 'whittyHand', getProperty('whittyHand.y') + y, time, 'cubeInOut')
end

function reset()
    doTweenY('hand4', 'whittyHand', getProperty('whittyHand.y') +130, 0.41, 'cubeInOut')
    setProperty('whittyHand.offset.y', -30)
    doTweenAngle('hand4.5', 'whittyHand', getProperty('whittyHand.angle') -8, 0.4)
    doTweenAngle('healthBar1', 'healthBar', getProperty('healthBar.angle') -8, 0.4, 'cubeInOut')
    doTweenAngle('healthBarBG1', 'healthBarBG', getProperty('healthBarBG.angle') -8, 0.4, 'cubeInOut')
    doTweenAngle('iconP11', 'iconP1', getProperty('iconP1.angle') -8, 0.4, 'cubeInOut')
    doTweenAngle('iconP21', 'iconP2', getProperty('iconP2.angle') -8, 0.4, 'cubeInOut')
    objectPlayAnimation('whittyHand', 'open')
end

function onTweenCompleted(tag)
    if tag == 'hand' then
        objectPlayAnimation('whittyHand', 'close')
        setProperty('whittyHand.offset.y', 30)
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
        doTweenY('hand3', 'whittyHand', getProperty('whittyHand.y') +30, 0.4, 'cubeInOut')
        doTweenAngle('hand3.5', 'whittyHand', getProperty('whittyHand.angle') +8, 0.4)
        doTweenAngle('healthBar', 'healthBar', getProperty('healthBar.angle') +8, 0.4, 'cubeInOut')
        doTweenAngle('healthBarBG', 'healthBarBG', getProperty('healthBarBG.angle') +8, 0.4, 'cubeInOut')
        doTweenAngle('iconP1', 'iconP1', getProperty('iconP1.angle') +8, 0.4, 'cubeInOut')
        doTweenAngle('iconP2', 'iconP2', getProperty('iconP2.angle') +8, 0.4, 'cubeInOut')
    end
end

function goodNoteHit(id, noteData, noteType, isSustainNote)
	if noteType == 'Healthdrain Stopper' then
        drain = false
        reset()
	end
end