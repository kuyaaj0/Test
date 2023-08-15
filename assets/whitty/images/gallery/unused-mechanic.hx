var whittyHands:FlxSprite;
	var drain:Bool = false;
    if (drain)
        health = health -0.006;
whittyHands = new FlxSprite(healthBar.x + 150, healthBar.y + 50);
whittyHands.frames = Paths.getSparrowAtlas('Whitty_Hands', 'whitty');
whittyHands.animation.addByPrefix('open', 'timeBar open', 24, false);
whittyHands.animation.addByPrefix('close', 'timeBar close', 24, false);
whittyHands.cameras = [camHUD];
add(whittyHands);

function resetHand() {
    whittyHands.animation.play('open');
    whittyHands.offset.y = - 30;
    FlxTween.tween(healthBar, {angle: healthBar.angle - 8}, 0.4, {ease: FlxEase.cubeInOut});
    FlxTween.tween(healthBarBG, {angle: healthBarBG.angle - 8}, 0.4, {ease: FlxEase.cubeInOut});
    FlxTween.tween(iconP1, {angle: iconP1.angle - 8}, 0.4, {ease: FlxEase.cubeInOut});
    FlxTween.tween(iconP2, {angle: iconP2.angle - 8}, 0.4, {ease: FlxEase.cubeInOut});
    FlxTween.tween(whittyHands, {angle: whittyHands.angle - 8}, 0.4, {ease: FlxEase.cubeInOut}); 
    FlxTween.tween(whittyHands, {y: whittyHands.y + 130}, 0.41, {ease: FlxEase.cubeInOut});
}

function trigger(yl:Float, time:Float){
    FlxTween.tween(whittyHands, {y: whittyHands.y + yl}, time, {ease: FlxEase.cubeInOut, 
        onComplete: function(twn: FlxTween) 
        {
            whittyHands.animation.play('close');
            whittyHands.offset.y = 30;
            new FlxTimer().start(0.5, function(tmr:FlxTimer)
                {
                    FlxTween.tween(healthBar, {angle: healthBar.angle + 8}, 0.4, {ease: FlxEase.cubeInOut});
                    FlxTween.tween(healthBarBG, {angle: healthBarBG.angle + 8}, 0.4, {ease: FlxEase.cubeInOut});
                    FlxTween.tween(iconP1, {angle: iconP1.angle + 8}, 0.4, {ease: FlxEase.cubeInOut});
                    FlxTween.tween(iconP2, {angle: iconP2.angle + 8}, 0.4, {ease: FlxEase.cubeInOut});
                    FlxTween.tween(whittyHands, {y: whittyHands.y + 30}, 0.4, {ease: FlxEase.cubeInOut});
                    FlxTween.tween(whittyHands, {angle: whittyHands.angle + 8}, 0.4, {ease: FlxEase.cubeInOut,
                        onComplete: function(twn:FlxTween)
                        {
                            drain = true;
                        }
                    }); 
                }
            );
        }
    });
}

case 'Healthdrain Stopper' :
						drain = false;
						resetHand();

                        if (curBeat == 16)
                            trigger(-130, 0.41);
                        else if (curBeat == 32)
                            trigger(-130, 0.41);
                        else 