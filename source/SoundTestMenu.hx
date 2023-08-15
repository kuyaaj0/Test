package;

import flixel.FlxState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;


#if windows
import Discord.DiscordClient;
#end

class SoundTestMenu extends MusicBeatState
{
	var woahmanstopspammin:Bool = true;

	var whiteshit:FlxSprite;

	var daValue:Int = 0;
	var pcmValue:Int = 0;

	var soundCooldown:Bool = true;

	var funnymonke:Bool = true;

	var incameo:Bool = false;

    var paused:Bool = false;

	var cameoImg:FlxSprite;

	var pcmNO = new FlxText(FlxG.width / 6, FlxG.height / 2, 0, 'WEEK : ', 23);
	var daNO = new FlxText(FlxG.width * .6, FlxG.height / 2, 0, 'SONG : ', 23);

	var pcmNO_NUMBER = new FlxText(FlxG.width / 6, FlxG.height / 2, 0, '0', 23);
	var daNO_NUMBER = new FlxText(FlxG.width / 6, FlxG.height / 2, 0, '0', 23);
	

    override function create()
    {
		DiscordClient.changePresence('In the Sound Test Menu', null);

	    new FlxTimer().start(0.1, function(tmr:FlxTimer)
		{
			FlxG.sound.playMusic(Paths.music('breakfast'));
		});
		
		whiteshit = new FlxSprite().makeGraphic(1280, 720, FlxColor.WHITE);
		whiteshit.alpha = 0;

		cameoImg = new FlxSprite();

		var bg:FlxSprite = new FlxSprite(-100);
        bg.frames = Paths.getSparrowAtlas('menuStatic');
        bg.animation.addByPrefix('static', 'static', 24, true);
		bg.scrollFactor.x = 0;
		bg.scrollFactor.y = 0;
		bg.setGraphicSize(Std.int(bg.width * 1));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = true;
        bg.animation.play('static');
		add(bg);

		var soundtesttext = new FlxText(0, 0, 0, 'iPHONE 69420 Pro Max 187 GB', 25);
		soundtesttext.screenCenter();
		soundtesttext.y -= 180;
		soundtesttext.x -= 33;
		soundtesttext.setFormat("Pixel Arial 11 Bold", 25, FlxColor.fromRGB(0, 163, 255));
		soundtesttext.setBorderStyle(SHADOW, FlxColor.BLACK, 4, 1);
		add(soundtesttext);

		pcmNO.setFormat("Pixel Arial 11 Bold", 23, FlxColor.fromRGB(174, 179, 251));
		pcmNO.setBorderStyle(SHADOW, FlxColor.fromRGB(106, 110, 159), 4, 1);
        pcmNO.y -= 70;
		pcmNO.x += 100;

		daNO.setFormat("Pixel Arial 11 Bold", 23, FlxColor.fromRGB(174, 179, 251));
		daNO.setBorderStyle(SHADOW, FlxColor.fromRGB(106, 110, 159), 4, 1);
		daNO.y -= 70;
			
		add(pcmNO);
    	add(daNO);

		pcmNO_NUMBER.y -= 70;
		pcmNO_NUMBER.x += 270;
		pcmNO_NUMBER.setFormat("Pixel Arial 11 Bold", 23, FlxColor.fromRGB(174, 179, 251));
		pcmNO_NUMBER.setBorderStyle(SHADOW, FlxColor.fromRGB(106, 110, 159), 4, 1);
		add(pcmNO_NUMBER);
	
		daNO_NUMBER.y -= 70;
		daNO_NUMBER.x += daNO.x - 70;
		daNO_NUMBER.setFormat("Pixel Arial 11 Bold", 23, FlxColor.fromRGB(174, 179, 251));
		daNO_NUMBER.setBorderStyle(SHADOW, FlxColor.fromRGB(106, 110, 159), 4, 1);
		add(daNO_NUMBER);

		var ipad:FlxSprite = new FlxSprite().loadGraphic(Paths.image('ipadMenu'));
		ipad.updateHitbox();
		ipad.screenCenter();
		ipad.antialiasing = true;
		add(ipad);

		cameoImg.visible = false;
		add(cameoImg);

		add(whiteshit);
    }

	function changeNumber(selection:Int) 
	{
		if (funnymonke)
		{
			pcmValue += selection;
			if (pcmValue < 0) pcmValue = 20; //change values
			if (pcmValue > 100) pcmValue = 0;
		}
		else
		{
			daValue += selection;
			if (daValue < 0) daValue = 20;
			if (daValue > 100) daValue = 0;
		}
	}

	function flashyWashy(a:Bool)
	{
		if (a == true)
		{
			FlxG.sound.play(Paths.sound('confirmMenu'));
			FlxTween.tween(whiteshit, {alpha: 1}, 0.4);
		}
		else
			FlxTween.color(whiteshit, 0.1, FlxColor.WHITE, FlxColor.WHITE);
			FlxTween.tween(whiteshit, {alpha: 0}, 0.2);

	}

    var zoomTween:FlxTween;
	function beatZoomCam(zoom:Float)
	{
		FlxG.camera.zoom = zoom;

		if(zoomTween != null) 
            zoomTween.cancel();

		zoomTween = FlxTween.tween(FlxG.camera, {zoom: 1}, 1, {ease: FlxEase.circOut, 
            onComplete: function(twn:FlxTween)
			{
				zoomTween = null;
			}
		});
	}

	function enterSong(data:String, song:String) {
		woahmanstopspammin = false;
		PlayState.SONG = Song.loadFromJson(data, song);
		PlayState.isStoryMode = false;
		PlayState.storyDifficulty = 1;
		PlayState.storyWeek = 1;
		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;
		flashyWashy(true);
		new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			LoadingState.loadAndSwitchState(new PlayState());
		});
	}

	function loadImage(image:String, song:String, ?lib:String) {
		woahmanstopspammin = false;
		flashyWashy(true);
		new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			cameoImg.visible = true;
			cameoImg.loadGraphic(Paths.image(image, lib));
			cameoImg.setSize(1280, 720);
			flashyWashy(false);
			FlxG.sound.music.stop();

		});
		new FlxTimer().start(2.1, function(tmr:FlxTimer)
		{
			FlxG.sound.playMusic(Paths.music(song, lib), 1, false);
			incameo = true;
		});
	}

	function doTheThing(first:Int, second:Int) 
	{
		if (first == 3 && second == 19)
		{
			enterSong('infernum-last', 'infernum-last'); //done
		}
		else if (first == 0 && second == 0) 
		{
		    enterSong('vexation-v6xv6', 'vexation-v6xv6'); // done
		}
		else if (first == 20 && second == 20)
		{
			enterSong('abnormal', 'abnormal'); //
        }
		else if (first == 6 && second == 9)
		{
			enterSong('vejacion', 'vejacion');
		}
		else if (first == 15 && second == 14)
		{
			enterSong('shitmore', 'shitmore');
		}
		else if (first == 13 && second == 8)
		{
			enterSong('ignition', 'ignition');
		}
		else if (first == 18 && second == 7)
		{
			enterSong('infernum-bside', 'infernum-bside');
		}
		else if (first == 1 && second == 4) 
		{
			loadImage('gallery/ROMAN', 'balls-vex', 'whitty');
		}
		else
		{
			if (soundCooldown)
			{
				soundCooldown = false;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				new FlxTimer().start(0.8, function(tmr:FlxTimer)
				{
					soundCooldown = true;
				});
                trace('ERROR: No song found.');
			}
        }
	}
		
    var holdTime:Float = 0;
    var continued:Int = 0;
	override public function update(elapsed:Float)
	{
        var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
        var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

        if (FlxG.keys.justPressed.D || FlxG.keys.justPressed.F || FlxG.keys.justPressed.J || FlxG.keys.justPressed.K) {
			if(incameo)
            	beatZoomCam(1.1);
		}

		if (FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.A || FlxG.keys.justPressed.D) 
            if (woahmanstopspammin) 
                funnymonke = !funnymonke;

        if (downP) {
            if (woahmanstopspammin) {
                changeNumber(shiftMult);
                holdTime = 0;
            }
        } 

        if (upP) {
            if (woahmanstopspammin) {
                changeNumber(-shiftMult);
                holdTime = 0;
            }
        } 

        if(controls.UI_DOWN || controls.UI_UP)
		{
			var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
			holdTime += elapsed;
			var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

			if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
			{
				changeNumber((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
			}
		}

		if (FlxG.keys.justPressed.ENTER && woahmanstopspammin) {
            doTheThing(pcmValue, daValue);
        }

		if (FlxG.keys.justPressed.ENTER && !woahmanstopspammin && incameo) LoadingState.loadAndSwitchState(new SoundTestMenu());

		if (FlxG.keys.justPressed.ESCAPE && woahmanstopspammin && !incameo) LoadingState.loadAndSwitchState(new MainMenuState());

		// if(FlxG.sound.music.finished && !woahmanstopspammin && incameo) LoadingState.loadAndSwitchState(new SoundTestMenu());

        if(FlxG.keys.justPressed.SPACE) {
            continued = continued + 1;
            trace(continued);
        }

        if (continued == 1) {
            FlxG.sound.music.pause();
            paused = true;
            trace('Paused Song.');

        }else if (continued == 2) {
            FlxG.sound.music.play();
            paused = false;
            trace('Continued Song.');
			continued == 0;
        }

		if (funnymonke)
		{
			pcmNO.setFormat("Pixel Arial 11 Bold", 23, FlxColor.fromRGB(254, 174, 0));
			pcmNO.setBorderStyle(SHADOW, FlxColor.fromRGB(253, 36, 3), 4, 1);
			daNO.setFormat("Pixel Arial 11 Bold", 23, FlxColor.fromRGB(174, 179, 251));
			daNO.setBorderStyle(SHADOW, FlxColor.fromRGB(106, 110, 159), 4, 1);
		}
		else
		{
			pcmNO.setFormat("Pixel Arial 11 Bold", 23, FlxColor.fromRGB(174, 179, 251));
			pcmNO.setBorderStyle(SHADOW, FlxColor.fromRGB(106, 110, 159), 4, 1);
			
            daNO.setFormat("Pixel Arial 11 Bold", 23, FlxColor.fromRGB(254, 174, 0));
			daNO.setBorderStyle(SHADOW, FlxColor.fromRGB(253, 36, 3), 4, 1);
		}
			
		if (pcmValue < 10)	pcmNO_NUMBER.text = '0' + Std.string(pcmValue);
		else pcmNO_NUMBER.text = Std.string(pcmValue);

		if (daValue < 10)	daNO_NUMBER.text = '0' + Std.string(daValue);
		else daNO_NUMBER.text = Std.string(daValue);
						
		super.update(elapsed);
	}
}