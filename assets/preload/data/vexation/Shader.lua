function onStepHit()
	if curStep == 1984 then
	addVCREffect('camHUD', 0.05)
	addVCREffect('camGame', 0.05)
	end
	if curStep == 2528 then
		clearEffects('camHUD')
		clearEffects('camGame')
	end
end

function onUpdate()
	setProperty('botplayTxt.visible', false)
end

--could be useful
--[[
	addChromaticAbberationEffect(camera:String, chromeOffset:Float = 0.005)
	addScanlineEffect('camHUD', true)
	addGrainEffect(camera:String, grainSize:Float, lumAmount:Float, lockAlpha:Bool=false)
	addTiltshiftEffect(camera:String, blurAmount:Float, center:Float)
	addVCREffect(camera:String, glitchFactor:Float = 0.0, distortion:Bool=true, perspectiveOn:Bool=true, vignetteMoving:Bool=true)
	addGlitchEffect(camera:String, waveSpeed:Float = 0.1, waveFrq:Float = 0.1, waveAmp:Float = 0.1)
	addPulseEffect(camera:String, waveSpeed:Float = 0.1, waveFrq:Float = 0.1, waveAmp:Float = 0.1)
	addDistortionEffect(camera:String, waveSpeed:Float = 0.1, waveFrq:Float = 0.1, waveAmp:Float = 0.1)
	addInvertEffect(camera:String, lockAlpha:Bool=false)
	addGreyscaleEffect(camera:String)
	add3DEffect(camera:String, xrotation:Float=0, yrotation:Float=0, zrotation:Float=0, depth:Float=0)
	addBloomEffect(camera:String, intensity:Float = 0.35, blurSize:Float=1.0)
	clearEffects(camera:String)
]]