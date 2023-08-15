function onBeatHit()
	if curBeat >= 1 and curBeat < 32 then
		triggerEvent('Add Camera Zoom', 0.031, 0.031)
	end
	if curBeat >= 32 and curBeat < 223 then
		triggerEvent('Add Camera Zoom', 0.1, 0.1)
	end
end

function jumpscare()
	makeLuaSprite('lmao', '8', 0, 0);
	setObjectCamera('lmao', 'camHUD')
	addLuaSprite('lmao', false);
	doTweenAlpha('lmao', 'lmao', 0, 1)
end

function onStepHit()
	if curStep == 120 then
		jumpscare()
		triggerEvent('Add Camera Zoom', 0.3, "")
	end
end