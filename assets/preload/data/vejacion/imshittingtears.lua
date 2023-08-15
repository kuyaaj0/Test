function eyesores()
    addPulseEffect('camHUD', 1, 1, 1)
end

function onStepHit()
    if curStep == 481 then
        setProperty('camHUD.visible', false)
    elseif curStep == 552 then
        setProperty('camHUD.visible', true)
    end
end
