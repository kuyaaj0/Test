local allowCountdown = false
local stops = 0
local anims = 0
function onStartCountdown()
	-- Block the first countdown and start a timer of 0.8 seconds to play the dialogue
	if not allowCountdown and isStoryMode and not seenCutscene then
		setProperty('inCutscene', true);
		
		if stops == 0 then
			makeLuaSprite('stageback', 'whittyBack', -500, -130);
			setLuaSpriteScrollFactor('stageback', 1.0, 1.0);
			
			makeLuaSprite('stagefront', 'whittyFront', -500, -170);
			setLuaSpriteScrollFactor('stagefront', 1.0, 1.0);
			
			makeAnimatedLuaSprite('crack', 'crack', 0, 0)
    		addAnimationByPrefix('crack', 'idle', 'crack', 24, false)
    		screenCenter('crack', 'XY')

			addLuaSprite('stageback', false);
			addLuaSprite('stagefront', false);
            
			makeAnimatedLuaSprite('whit','cutscene/cuttinDeezeBalls',-250,0)
		    addAnim('whit','shake',24,true)
            addAnim('whit','crack0',12,false)
            addAnim('whit','crack loop', 24,true)
			addAnim('whit', 'pose0', 12, false)
			addAnim('whit', 'pose loop', 24, true)
			addAnim('whit', 'eyes0', 24, false)
			addAnim('whit', 'eyes loop', 24, true)
			addAnim('whit', 'set0', 24, false)
			addAnim('whit', 'set loop', 24, true)
			addAnim('whit', 'ballistic0', 24, false)
			addAnim('whit', 'ballistic loop', 24, true)
            addAnim('whit','scream0',12,false)
            addAnim('whit','scream loop',24,true)
            addLuaSprite('whit',true)
			
			setProperty('dad.visible',false)
			setProperty('camFollowPos.x', 300)
            runTimer('1', 2)
			objectPlayAnimation('whit','shake',false);
			doTweenZoom('camGame', 'camGame', 1.4, 2)
			doTweenX('camFollowPosX','camFollowPos', getProperty('camFollowPos.x') -20, 2)
			doTweenY('camFollowPosY','camFollowPos', getProperty('camFollowPos.y') -100, 2)
			playSound('shake')
			playSound('hiss', 0.051, true)
		end
		if stops == 1 then
            setProperty('camGame._fxFadeAlpha', 0);
			cameraFlash('game','FFFFFF',0.8)
			setProperty('dad.visible',true)
			removeLuaSprite('whit',false)
			removeLuaSprite('stageback',false)
			removeLuaSprite('stagefront',false)
			removeLuaSprite('crack',false)
			runTimer('startDialogue', 0.8);
			allowCountdown = true;
		end
	stops  = stops + 1
		return Function_Stop;
	end
	return Function_Continue;
end

function addAnim(tag, anim, frame, loop)
	addAnimationByPrefix(tag, anim, anim, frame, loop)
end

function onTimerCompleted(tag, loops, loopsLeft)
	if tag == 'startDialogue' then -- Timer completed, play dialogue
		startDialogue('dialogue','rumb');
	end
    if tag == '1' then
        objectPlayAnimation('whit','crack0',true)
		playSound('micCrack')
		cameraShake('game', 0.01, 0.1)
		doTweenZoom('camGame', 'camGame', getProperty('defaultCamZoom') + 0.1, 0.12)
		doTweenY('camFollowPosY','camFollowPos', getProperty('camFollowPos.y') + 50, 0.12)
		runTimer('2', 3)
		anims = 1
    end
    if tag == '2' then
        objectPlayAnimation('whit','pose0',true)
		runTimer('3', 1)
		anims = 2
    end
    if tag == '3' then
        objectPlayAnimation('whit','eyes0',true)
		doTweenZoom('camGamee', 'camGame', getProperty('defaultCamZoom') + 0.2, 0.12)
		playSound('eye')
		playSound('income')
		runTimer('4', 2.1)
		anims = 3
    end
    if tag == '4' then
		objectPlayAnimation('whit','set0',true)
		runTimer('5', 1.5)
		anims = 4
	end
    if tag == '5' then
		objectPlayAnimation('whit','ballistic0',true)
		runTimer('6', 2)
		anims = 5
	end
    if tag == '6' then
		doTweenZoom('camGame', 'camGame', getProperty('defaultCamZoom'), 0.13, 'cubeIn')
        objectPlayAnimation('whit','scream0',false)
		playSound('ouchMyToe')
		cameraShake('game',0.01,4)
		stopSound('income')
		stopSound('hiss')
		runTimer('kfin', 4)
		anims = 6
	end
	if tag == '7' then
		cameraFade('game','FFFFFF',1)
	end
	if tag == 'kfin' then
		startCountdown()
	end
	if tag == 'endshit' then
        setProperty('camHUD._fxFadeAlpha', 0);
        cameraFlash('hud','000000',1)
		makeLuaSprite('endcock','jabaited')
        addLuaSprite('endcock',true)
        setObjectCamera('endcock','camHUD')
	end
end
function onUpdatePost()
    if keyJustPressed('space') then 
        startCountdown() 
    end    
end

function onUpdate()
	if anims == 1 then
		if getProperty('whit.animation.curAnim.finished') then
			objectPlayAnimation('whit','crack loop',true)
		end
	elseif anims == 2 then
		if getProperty('whit.animation.curAnim.finished') then
			objectPlayAnimation('whit','pose loop',true)
		end
	elseif anims == 3 then
		if getProperty('whit.animation.curAnim.finished') then
			objectPlayAnimation('whit','eyes loop',true)
		end
	elseif anims == 4 then
		if getProperty('whit.animation.curAnim.finished') then
			objectPlayAnimation('whit','set loop',true)
			playSound('souljaboyCrank')
			addLuaSprite('crack', false)
			objectPlayAnimation('crack', 'idle')
			doTweenZoom('camGame', 'camGame', getProperty('defaultCamZoom') + 0.81, 3, 'cubeIn')
			cameraShake('game',0.01,0.2)
		end
	elseif anims == 5 then
		if getProperty('whit.animation.curAnim.finished') then
			objectPlayAnimation('whit','ballistic loop',true)
			cameraShake('game',0.01,0.2)
		end
	elseif anims == 6 then
		if getProperty('whit.animation.curAnim.finished') then
			objectPlayAnimation('whit','scream loop',true)
			runTimer('7', 1.7)
		end
	end
end    

function onTweenCompleted(tag)
	if tag == 'camGamee' then
		doTweenZoom('camGam1', 'camGame', getProperty('defaultCamZoom') + 0.1, 1)
	end
end