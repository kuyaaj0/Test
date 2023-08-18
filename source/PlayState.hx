package;

import flixel.graphics.FlxGraphic;
#if desktop
import Discord.DiscordClient;
#end
import Section.SwagSection;
import Song.SwagSong;
import WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.particles.FlxEmitter;
import flixel.animation.FlxAnimationController;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxShader;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import lime.utils.Assets;
import openfl.Lib;
import openfl.display.BlendMode;
import openfl.display.Shader;
import openfl.display.StageQuality;
import openfl.filters.BitmapFilter;
import openfl.filters.ShaderFilter;
import openfl.utils.Assets as OpenFlAssets;
import editors.ChartingState;
import editors.CharacterEditorState;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import Note.EventNote;
import openfl.events.KeyboardEvent;
import Achievements;
import StageData;
import FunkinLua;
import DialogueBoxPsych;
import Shaders;
import DynamicShaderHandler;
#if MODS_ALLOWED
import sys.FileSystem;
#end

using StringTools;

class PlayState extends MusicBeatState
{
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public static var ratingStuff:Array<Dynamic> = [
		['You Lose!', 0.2], //From 0% to 19%
		['Worser', 0.4], //From 20% to 39%
		['Bad', 0.5], //From 40% to 49%
		['No', 0.6], //From 50% to 59%
		['Meh', 0.69], //From 60% to 68%
		['Fine', 0.7], //69%
		['Good', 0.8], //From 70% to 79%
		['Great', 0.9], //From 80% to 89%
		['Fantastic!', 1], //From 90% to 99%
		['AMAZING!!', 1] //The value on this one isn't used actually, since Perfect is always "1"
	];
	public static var animatedShaders:Map<String, DynamicShaderHandler> = new Map<String, DynamicShaderHandler>();
	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();
	public var shader_chromatic_abberation:ChromaticAberrationEffect;
	public var camGameShaders:Array<ShaderEffect> = [];
	public var camHUDShaders:Array<ShaderEffect> = [];
	public var camOtherShaders:Array<ShaderEffect> = [];
	//event variables
	private var isCameraOnForcedPos:Bool = false;
	#if (haxe >= "4.0.0")
	public var variables:Map<String, Dynamic> = new Map();
	public var boyfriendMap:Map<String, Boyfriend> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	#else
	public var boyfriendMap:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();
	#end

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;
	
	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;
	public var shaderUpdates:Array<Float->Void> = [];
	public static var curStage:String = '';
	public static var isPixelStage:Bool = false;
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;

	var dialogueBlack:FlxSprite;

	public var vocals:FlxSound;

	public var dad:Character;
	public var gf:Character;
	public var boyfriend:Boyfriend;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];

	private var strumLine:FlxSprite;

	//Handles the new epic mega smexy cam code that i've done
	private var camFollow:FlxPoint;
	private var camFollowPos:FlxObject;
	private static var prevCamFollow:FlxPoint;
	private static var prevCamFollowPos:FlxObject;

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var camZooming:Bool = false;
	private var curSong:String = "";

	public var gfSpeed:Int = 1;
	public var health:Float = 1;
	public var combo:Int = 0;

	private var healthBarBG:FlxSprite;
	private var healthBarBurn:FlxSprite;
	public var healthBar:FlxBar;
	var songPercent:Float = 0;
	var watermark:FlxText;

	private var timeBarBG:AttachedSprite;
	public var timeBar:FlxBar;

	public var playbackRate(default, set):Float = 1;
	
	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;
	
	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	private var updateTime:Bool = true;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	//Gameplay settings
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled:Bool = false;
	public var practiceMode:Bool = false;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;
	public var cameraSpeed:Float = 1;

	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];
	var dialogueJson:DialogueFile = null;

	var halloweenBG:BGSprite;
	var halloweenWhite:BGSprite;

	var phillyCityLights:FlxTypedGroup<BGSprite>;
	var blammedLightsBlack:ModchartSprite;
	var blammedLightsBlackTween:FlxTween;
	var phillyCityLightsEvent:FlxTypedGroup<BGSprite>;
	var phillyCityLightsEventTween:FlxTween;

	var ewBg:FlxSprite;
	var nwBg:FlxSprite;
	var nwBg2:FlxSprite;
	var rain:FlxSprite;
	var fire:FlxSprite;
	var fire3:FlxSprite;
	var fire4:FlxSprite;
	var circ:FlxSprite;
	var matt:FlxSprite;
	var crowd:FlxSprite;
	var staticc:FlxSprite;
	var crack:FlxSprite;
	var block:FlxSprite;
	var whait:FlxSprite;
	var upperBar:FlxSprite;
	var lowerBar:FlxSprite;
	var depraveBlack:BGSprite;
	var depraveLight:BGSprite;
	var depraveSmokes:FlxSpriteGroup;
	var effect:FlxSprite;
	var fireEffect:FlxSprite;
	var emitter:FlxEmitter;
	var camEmitt:Bool = false;
	var voicelineValue:String;
	var voiceLine:FlxSprite;
	var bbg:FlxSprite;
	var spaceBar:FlxSprite;

	var victim:FlxSprite;
	var victim2:FlxSprite;
	var victim3:FlxSprite;

	var bfire:FlxSprite;
	var bfire2:FlxSprite;
	var bfire3:FlxSprite;
	var bfire4:FlxSprite;
	var bfire5:FlxSprite;
	var bfire6:FlxSprite;

	var shitmoresfriends:FlxSprite;
	var shitmoresfrends:FlxSprite;

	/*var trailEnabledDad:Bool = false;
	var trailEnabledBF:Bool = false;
	var timerStartedDad:Bool = false;
	var timerStartedBF:Bool = false;

	var trailLength:Int = 5;
	var trailDelay:Int = 0.05;*/

	var evilTrail:FlxTrail;
	var moreevilTrail:FlxTrail;

	var particles:FlxTypedGroup<FlxEmitter>;

	var lose:Bool = false;
	var one:Bool = false;
	var two:Bool = false;
	var shake:Bool = false;
	var vexated:Bool = false;
	var vine:FlxSprite;
	var whittay:FlxSprite;
	var bsidefirevisible = false;

	public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;
	public var scoreTxt:FlxText;
	var timeTxt:FlxText;
	var scoreTxtTween:FlxTween;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	public var defaultCamZoom:Float = 1.05;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;
	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	var whittyPrecacheList:Map<String, String> = new Map<String, String>();
	var precacheList:Map<String, String> = new Map<String, String>();

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;
	var songLength:Float = 0;
	
	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	#if desktop
	// Discord RPC variables
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	//Achievement stuff
	var keysPressed:Array<Bool> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Lua stuff
	public static var instance:PlayState;
	public var luaArray:Array<FunkinLua> = [];
	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	public var introSoundsSuffix:String = '';
	public var luaShaders:Map<String, DynamicShaderHandler> = new Map<String, DynamicShaderHandler>();

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;
	
	// Less laggy controls
	private var keysArray:Array<Dynamic>;

	

	override public function create()
	{
		Paths.clearStoredMemory();

		// for lua
		instance = this;

		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		playbackRate = ClientPrefs.getGameplaySetting('songspeed', 1);
		Achievements.loadAchievements();

		keysArray = [
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right'))
		];

		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray.length)
		{
			keysPressed.push(false);
		}

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		// Gameplay settings
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);

		shader_chromatic_abberation = new ChromaticAberrationEffect();

		// var gameCam:FlxCamera = FlxG.camera;
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD);
		FlxG.cameras.add(camOther);
		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();

		FlxCamera.defaultCameras = [camGame];
		CustomFadeTransition.nextCamera = camOther;
		//FlxG.cameras.setDefaultDrawTarget(camGame, true);

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		#if desktop
		storyDifficultyText = CoolUtil.difficulties[storyDifficulty];

		// String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		if (isStoryMode)
		{
			detailsText = "Story Mode: " + WeekData.getCurrentWeek().weekName;
		}
		else
		{
			detailsText = "Freeplay";
		}

		// String for when the game is paused
		detailsPausedText = "Paused - " + detailsText;
		#end

		GameOverSubstate.resetVariables();
		var songName:String = Paths.formatToSongPath(SONG.song);

		curStage = PlayState.SONG.stage;
		trace('stage is: ' + curStage);
		
		var stageData:StageFile = StageData.getStageFile(curStage);
		if(stageData == null) { //Stage couldn't be found, create a dummy stage for preventing a crash
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,
				
				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100],
				
				camera_boyfriend: [0, 0],
				camera_opponent: [0, 0],
				camera_girlfriend: [0, 0],
				camera_speed: 1
			};
		}

		defaultCamZoom = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;
		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if(stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if(boyfriendCameraOffset == null) //gods sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null)
			opponentCameraOffset = [0, 0];

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null)
			girlfriendCameraOffset = [0, 0];

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);

		switch (curStage)
		{
			case 'stage': //Week 1
				var bg:BGSprite = new BGSprite('stageback', -600, -200, 0.9, 0.9);
				add(bg);

				var stageFront:BGSprite = new BGSprite('stagefront', -650, 600, 0.9, 0.9);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				add(stageFront);
				if(!ClientPrefs.lowQuality) {
					var stageLight:BGSprite = new BGSprite('stage_light', -125, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					add(stageLight);
					var stageLight:BGSprite = new BGSprite('stage_light', 1225, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					stageLight.flipX = true;
					add(stageLight);

					var stageCurtains:BGSprite = new BGSprite('stagecurtains', -500, -300, 1.3, 1.3);
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					add(stageCurtains);
				}

			case 'shitmore': //APRIL WEEK 1

				GameOverSubstate.characterName = 'boof-dead';
				GameOverSubstate.deathSoundName = 'fnf_loss_sfx_stupid';
				GameOverSubstate.loopSoundName = 'gameOverCum';
				GameOverSubstate.endSoundName = 'fnf_loss_sfx_stupid';

				var bg:FlxSprite = new FlxSprite(-600, -300).makeGraphic(Std.int(FlxG.width * 3), Std.int(FlxG.height * 3), FlxColor.WHITE);
				add(bg);

				shitmoresfriends = new FlxSprite(-350, -200);
				shitmoresfriends.frames = Paths.getSparrowAtlas('supercalifragilisticexpialidocious_people', 'whitty');
				shitmoresfriends.animation.addByPrefix('bop', 'bop', 24);
				shitmoresfriends.scale.set(0.8, 0.8);
				add(shitmoresfriends);

				shitmoresfrends = new FlxSprite(-350, -50);
				shitmoresfrends.frames = Paths.getSparrowAtlas('supercalifragilisticexpialidocious_people2', 'whitty');
				shitmoresfrends.animation.addByPrefix('bop', 'bop', 24);
				shitmoresfrends.scale.set(1, 1);
	
			case 'corruptionAlley':
				GameOverSubstate.characterName = 'bfC-dead';
	
				var bg:FlxSprite = new FlxSprite(-420, -130).loadGraphic(Paths.image('whittyBack', 'whitty'));
				bg.scrollFactor.set(1.0, 1.0);
				add(bg);
	
				var front:FlxSprite = new FlxSprite(-420, -130).loadGraphic(Paths.image('whittyFront', 'whitty'));
				front.scrollFactor.set(1.0, 1.0);
				add(front);  

				var trash:FlxSprite = new FlxSprite(-420, -130).loadGraphic(Paths.image('whittyTrash', 'whitty'));
				trash.scrollFactor.set(1.0, 1.0);
				add(trash);
				
				var isolation:FlxSprite = new FlxSprite(-420, -130).loadGraphic(Paths.image('whittyIsolation', 'whitty'));
				isolation.scrollFactor.set(1.0, 1.0);
				add(isolation);

				var light:FlxSprite = new FlxSprite(-420, -130).loadGraphic(Paths.image('whittyLight', 'whitty'));
				light.scrollFactor.set(1.0, 1.0);
				add(light);

				ewBg = new FlxSprite(-420, -130).loadGraphic(Paths.image('stageEffect', 'whitty'));
				ewBg.scrollFactor.set(1.0, 1.0);
				ewBg.visible = false;
				add(ewBg);

				rain = new FlxSprite(-470, -160);
				rain.frames = Paths.getSparrowAtlas('rain', 'whitty');
				rain.animation.addByPrefix('rain', 'Rain', 24, true);
				rain.scrollFactor.set(0, 0);
				rain.animation.play("rain");
				rain.visible = false;

				halloweenWhite = new BGSprite(null, -FlxG.width, -FlxG.height, 0, 0);
				halloweenWhite.makeGraphic(Std.int(FlxG.width * 3), Std.int(FlxG.height * 3), FlxColor.WHITE);
				halloweenWhite.alpha = 0;
				halloweenWhite.blend = ADD;

				//PRECACHE SOUNDS
				// whittyPrecacheList.set('thunder_1', 'sound');
				// whittyPrecacheList.set('thunder_2', 'sound');
	
				depraveSmokes = new FlxSpriteGroup(); //troll'd
			case 'CrazyCorruptionAlley':
				GameOverSubstate.characterName = 'bfC-dead';
	
				nwBg = new FlxSprite(-370, -160);
				nwBg.frames = Paths.getSparrowAtlas('BallisticBackground', 'whitty');
				nwBg.animation.addByPrefix('gameButMove', 'BallisticBackground idle', 16, true);
				nwBg.scrollFactor.set(1.0, 1.0);
				nwBg.animation.play("gameButMove");
				nwBg.alpha = 1;
				add(nwBg);

				victim = new FlxSprite(-370, -160);
				victim.frames = Paths.getSparrowAtlas('victims_laugh', 'whitty');
				victim.animation.addByPrefix('victim3','laugh',24,true);
				victim.animation.play('victim3');
				add(victim);

				victim2 = new FlxSprite(250, -400);
				victim2.frames = Paths.getSparrowAtlas('victims_laugh', 'whitty');
				victim2.animation.addByPrefix('victim3','laugh',24,true);
				victim2.animation.play('victim3');
				add(victim2);

				victim3 = new FlxSprite(-1050, -1100);
				victim3.frames = Paths.getSparrowAtlas('victims_laugh', 'whitty');
				victim3.animation.addByPrefix('victim3','laugh',24,true);
				victim3.animation.play('victim3');
				victim3.flipX = true;
				victim3.scale.set(1.3, 1.3);
				add(victim3);

				victim.scrollFactor.set(0.45, 0.85);
				victim2.scrollFactor.set(0.45, 0.85);
				victim3.scrollFactor.set(0.45, 0.85);

				victim.visible = false;
				victim2.visible = false;
				victim3.visible = false;

				nwBg2 = new FlxSprite(-370, -160);
				nwBg2.frames = Paths.getSparrowAtlas('BallisticBackground2', 'whitty');
				nwBg2.animation.addByPrefix('gameButMove', 'BallisticBackground idle', 16, true);
				nwBg2.scrollFactor.set(1.0, 1.0);
				nwBg2.animation.play("gameButMove");
				nwBg2.alpha = 0;
				add(nwBg2);
				
				var trash:FlxSprite = new FlxSprite(-370, -130).loadGraphic(Paths.image('whittyTrash', 'whitty'));
				trash.scrollFactor.set(1.0, 1.0);
				add(trash);

				var fire2:FlxSprite = new FlxSprite(1300,400);
				fire2.frames = Paths.getSparrowAtlas('Fire 1', 'whitty');
    			fire2.animation.addByPrefix('idle', 'Small flame', 24,true);
				fire2.alpha = 0.9;
				fire2.scale.set(2.5, 2.5);
				fire2.animation.play('idle');
				fire2.antialiasing = ClientPrefs.globalAntialiasing;
				add(fire2);

				matt = new FlxSprite(0,300);
				matt.frames = Paths.getSparrowAtlas('stagepeople', 'whitty');
    			matt.animation.addByPrefix('bop', 'people stage', 24,false);
				matt.scale.set(1.5, 1.5);
				matt.flipX = true;
				matt.antialiasing = ClientPrefs.globalAntialiasing;
				matt.visible = false;
				add(matt);

				fire3 = new FlxSprite(-500,700);
				fire3.frames = Paths.getSparrowAtlas('Fire 1', 'whitty');
    			fire3.animation.addByPrefix('idle', 'Small flame', 24,true);
				fire3.alpha = 0.9;
				fire3.scale.set(3, 3);
				fire3.animation.play('idle');
				fire3.antialiasing = ClientPrefs.globalAntialiasing;
				fire3.flipX = true;
					
				fire4 = new FlxSprite(1400,900);
				fire4.frames = Paths.getSparrowAtlas('Fire 1', 'whitty');
    			fire4.animation.addByPrefix('idle', 'Small flame', 24,true);
				fire4.alpha = 0.9;
				fire4.scale.set(3, 3);
				fire4.animation.play('idle');
				fire4.antialiasing = ClientPrefs.globalAntialiasing;
				fire4.flipX = true;

				var trash:FlxSprite = new FlxSprite(-370, -130).loadGraphic(Paths.image('whittyTrash', 'whitty'));
				trash.scrollFactor.set(1.0, 1.0);
				add(trash);

				bbg = new FlxSprite(-370, -130).loadGraphic(Paths.image('infernumBG', 'whitty'));
				bbg.scrollFactor.set(1.0, 1.0);
				add(bbg);
				bbg.visible = false;

			case 'CrazyVexationAlley':
				GameOverSubstate.characterName = 'bfC-dead';

				var victim:FlxSprite = new FlxSprite(-400, -160);
				victim.frames = Paths.getSparrowAtlas('victims_laugh', 'whitty');
				victim.animation.addByPrefix('victim3','laugh',24,true);
				victim.animation.play('victim3');
				add(victim);

				var victim2:FlxSprite = new FlxSprite(250, -400);
				victim2.frames = Paths.getSparrowAtlas('victims_laugh', 'whitty');
				victim2.animation.addByPrefix('victim3','laugh',24,true);
				victim2.animation.play('victim3');
				add(victim2);

				var victim3:FlxSprite = new FlxSprite(-1050, -1100);
				victim3.frames = Paths.getSparrowAtlas('victims_laugh', 'whitty');
				victim3.animation.addByPrefix('victim3','laugh',24,true);
				victim3.animation.play('victim3');
				victim3.flipX = true;
				victim3.scale.set(1.3, 1.3);
				add(victim3);

				victim.scrollFactor.set(0.45, 0.85);
				victim2.scrollFactor.set(0.45, 0.85);
				victim3.scrollFactor.set(0.45, 0.85);

				nwBg = new FlxSprite(-370, -160);
				nwBg.frames = Paths.getSparrowAtlas('BallisticBackground3', 'whitty');
				nwBg.animation.addByPrefix('gameButMove', 'BallisticBackground idle', 16, true);
				nwBg.scrollFactor.set(1.0, 1.0);
				nwBg.animation.play("gameButMove");
				nwBg.alpha = 1;
				add(nwBg);

				fire = new FlxSprite(-450, 300);/* <--- haxe would understand the command static lol*/
				fire.frames = Paths.getSparrowAtlas('Fire Front', 'whitty');
				fire.animation.addByPrefix('burn', 'Flame Wall Glow', 24, true);
				fire.animation.addByPrefix('idle', 'Fire Idle', 24, true);
				fire.animation.play('burn');
				fire.alpha = 0.9;
				fire.antialiasing = ClientPrefs.globalAntialiasing;

				matt = new FlxSprite(0,400);
				matt.frames = Paths.getSparrowAtlas('stagepeople', 'whitty');
    			matt.animation.addByPrefix('bop', 'people stage', 24,false);
				matt.scale.set(1.5, 1.5);
				matt.flipX = true;
				matt.antialiasing = ClientPrefs.globalAntialiasing;

				crowd = new FlxSprite(-250,550);
				crowd.frames = Paths.getSparrowAtlas('frontpeople', 'whitty');
    			crowd.animation.addByPrefix('bop', 'people front', 24,false);
				crowd.scale.set(1.1, 1.1);
				crowd.scrollFactor.set(0.85, 0.85);
				crowd.antialiasing = ClientPrefs.globalAntialiasing;

				nwBg2 = new FlxSprite(-370, -160);
				nwBg2.frames = Paths.getSparrowAtlas('BallisticBackgroundG', 'whitty');
				nwBg2.animation.addByPrefix('gameButMove', 'Bg move', 16, true);
				nwBg2.animation.addByPrefix('game', 'Startup', 16, false);
				nwBg2.scrollFactor.set(1.0, 1.0);
				nwBg2.animation.play("gameButMove");
				nwBg2.alpha = 0;
				add(nwBg2);
			case 'shitty':
				GameOverSubstate.characterName = 'boof-dead';
				GameOverSubstate.deathSoundName = 'fnf_loss_sfx_stupid';
				GameOverSubstate.loopSoundName = 'gameOverCum';
				GameOverSubstate.endSoundName = 'fnf_loss_sfx_stupid';
	
				var nwBg = new FlxSprite(-370, -60);
				nwBg.frames = Paths.getSparrowAtlas('shittybg', 'whitty');
				nwBg.animation.addByPrefix('gameButMove', 'a', 16, true);
				nwBg.scrollFactor.set(1.0, 1.0);
				nwBg.animation.play("gameButMove");
				add(nwBg);
				
				var trash:FlxSprite = new FlxSprite(-320, -130).loadGraphic(Paths.image('whittyTrash', 'whitty'));
				trash.scrollFactor.set(1.0, 1.0);
				add(trash);
			case 'ballisticAlley':
				GameOverSubstate.characterName = 'bfC-dead';
	
				var nwBg = new FlxSprite(-470, -60);
				nwBg.frames = Paths.getSparrowAtlas('BallisticBackgroundV', 'whitty');
				nwBg.animation.addByPrefix('gameButMove', 'Background Whitty Moving', 16, true);
				nwBg.scrollFactor.set(1.0, 1.0);
				nwBg.animation.play("gameButMove");
				add(nwBg);

			case 'ballistic-bside' :
				var stageback:FlxSprite = new FlxSprite(-870, -360);
				stageback.frames = Paths.getSparrowAtlas('bside/ballisticWall', 'whitty');
				stageback.animation.addByPrefix('tha_swag_wal','wal style change',24,true);
				stageback.animation.play('tha_swag_wal',false);
				stageback.scrollFactor.set(0.9, 0.9);
				add(stageback);

				var stagefront:FlxSprite = new FlxSprite(-600, -350);
				stagefront.frames = Paths.getSparrowAtlas('bside/ballisticGround', 'whitty');
				stagefront.animation.addByPrefix('tha_cool_groun','flo style change',24,true);
				stagefront.animation.play('tha_cool_groun',false);
				stagefront.scrollFactor.set(1, 1);
				add(stagefront);

				bfire = new FlxSprite(-420, 260);
				bfire.frames = Paths.getSparrowAtlas('bside/fireglow', 'whitty');
				bfire.animation.addByPrefix('fire', 'FireStage', 24, true);
				bfire.animation.play('fire');
				bfire.visible = false;
				add(bfire);

				bfire2 = new FlxSprite(1120, 260);
				bfire2.frames = Paths.getSparrowAtlas('bside/fireglow', 'whitty');
				bfire2.animation.addByPrefix('fire', 'FireStage', 24, true);
				bfire2.animation.play('fire');
				bfire2.visible = false;
				add(bfire2);
		}

		spaceBar = new FlxSprite();
		spaceBar.antialiasing = true;
		spaceBar.frames = Paths.getSparrowAtlas("spacebar","whitty");		
		spaceBar.animation.addByPrefix("spaceBar", "spacebar", 24,true);
		spaceBar.setGraphicSize(Std.int(spaceBar.width * 0.85));
		spaceBar.screenCenter(XY);
		spaceBar.alpha = 0;
		add(spaceBar);
		spaceBar.cameras = [camOther];

		if(isPixelStage) {
			introSoundsSuffix = '-pixel';
		}
		add(gfGroup);
		// Shitty's layering but whatev it works somehow LOL

		if(curStage == 'ballistic-bside') {
			bfire3 = new FlxSprite(20, 260);
			bfire3.frames = Paths.getSparrowAtlas('bside/fireglow', 'whitty');
			bfire3.animation.addByPrefix('fire', 'FireStage', 24, true);
			bfire3.animation.play('fire');
			bfire3.visible = false;
			add(bfire3);

			bfire4 = new FlxSprite(620, 260);
			bfire4.frames = Paths.getSparrowAtlas('bside/fireglow', 'whitty');
			bfire4.animation.addByPrefix('fire', 'FireStage', 24, true);
			bfire4.animation.play('fire');
			bfire4.visible = false;
			add(bfire4);
		}

		staticc = new FlxSprite(-600, -300);/* <--- haxe would understand the command static lol*/
		staticc.frames = Paths.getSparrowAtlas('static', 'whitty');
		staticc.animation.addByPrefix('static', 'static', 69, true);
		staticc.alpha = 0;
		staticc.animation.play('static');
		staticc.scale.set(3, 3);
		add(staticc);

		if(curStage == 'CrazyVexationAlley') {
			add(fire);
			add(matt);
		}

		vine = new FlxSprite(500,570);
		vine.antialiasing = true;
		vine.frames = Paths.getSparrowAtlas("vexationVines","whitty");		
		vine.animation.addByPrefix("vine", "Vine Whip", 24, false);
		vine.setGraphicSize(Std.int(vine.width * 0.85));
		vine.alpha = 0;
		add(vine);

		whittay = new FlxSprite(-500,0);
		whittay.antialiasing = true;
		whittay.frames = Paths.getSparrowAtlas("cuttinDeezBalls","whitty");		
		whittay.animation.addByPrefix("whittay", "Whitty Ballistic Cutscene", 24, false);
		whittay.alpha = 0;

		circ = new FlxSprite(DAD_X - 600, DAD_Y - 300);
		circ.frames = Paths.getSparrowAtlas('circle');
    	circ.animation.addByPrefix('glow', 'circle glow', 24, false);
   		circ.alpha = 0;
    	add(circ);

		add(dadGroup);
		add(boyfriendGroup);

		
		if(curStage == 'ballistic-bside') {
			bfire5 = new FlxSprite(-720, 460);
			bfire5.frames = Paths.getSparrowAtlas('fireglow', 'whitty');
			bfire5.animation.addByPrefix('fire', 'FireStage', 24, true);
			bfire5.scale.set(1.2, 1.2);
			bfire5.animation.play('fire');
			bfire5.visible = false;
			bfire5.flipX =  true;
			add(bfire5);

			bfire6 = new FlxSprite(1220, 560);
			bfire6.frames = Paths.getSparrowAtlas('fireglow', 'whitty');
			bfire6.animation.addByPrefix('fire', 'FireStage', 24, true);
			bfire6.scale.set(1.2, 1.2);
			bfire6.animation.play('fire');
			bfire6.visible = false;
			bfire6.flipX = true;
			add(bfire6);
		}

		if (curStage == 'shitmore')
			add(shitmoresfrends);
		
		if(curStage == 'CrazyCorruptionAlley') {
			add(fire3);
			add(fire4);
		}
		if(curStage == 'CrazyVexationAlley') {
			add(crowd);
			add(whittay);
		}

		particles = new FlxTypedGroup<FlxEmitter>();

		for (i in 0...6)
		{
			emitter = new FlxEmitter(-1000, 1500);
			emitter.launchMode = FlxEmitterMode.SQUARE;
			emitter.velocity.set(-50, -150, 50, -750, -100, 0, 100, -100);
			emitter.scale.set(0.75, 0.75, 3, 3, 0.75, 0.75, 1.5, 1.5);
			emitter.drag.set(0, 0, 0, 0, 5, 5, 10, 10);
			emitter.width = 3500;
			emitter.alpha.set(1, 1, 0, 0);
			emitter.lifespan.set(3, 5);
			if(SONG.song.toLowerCase() == 'vexation' || SONG.song.toLowerCase() == 'vexation-hell')
				emitter.loadParticles(Paths.image('glow/CorruptParticle' + i, 'whitty'), 500, 16, true);
			else
				emitter.loadParticles(Paths.image('glow/Particle' + i, 'whitty'), 500, 16, true);
			particles.add(emitter);
		}

		if(SONG.song.toLowerCase() == 'vexation' || SONG.song.toLowerCase() == 'vexation-hell')
			fireEffect = new FlxSprite(-420, 130).loadGraphic(Paths.image('burnEffectVexation', 'whitty'));
		else
			fireEffect = new FlxSprite(-420, 130).loadGraphic(Paths.image('burnEffect', 'whitty'));
		fireEffect.scrollFactor.set(0.7, 0.7);
		if(!ClientPrefs.lowQuality)
			add(fireEffect);
		fireEffect.alpha = 0;

		add(particles);

		if(curStage == 'corruptionAlley' && SONG.song.toLowerCase() == 'pressure' || SONG.song.toLowerCase() == 'abnormal'){
			if(!isStoryMode){
				rain.visible = true;
				if(SONG.song.toLowerCase() == 'abnormal')
					rain.visible = false;
			}
			add(rain);
			add(halloweenWhite);
		}


		if(SONG.song.toLowerCase() == 'infernum' || SONG.song.toLowerCase() == 'infernum-hell') {
			

			block = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
			add(block);
			block.x = -600;
			block.y = -300;
			block.scrollFactor.set(0, 0);
			block.visible = true;

			whait = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
			add(whait);
			whait.x = -600;
			whait.y = -300;
			whait.scrollFactor.set(0, 0);
			whait.visible = false;

			crack = new FlxSprite(); 
			crack.frames = Paths.getSparrowAtlas('crack', 'whitty');
			crack.animation.addByPrefix('idle', 'crack', 24, false);
			crack.screenCenter();
			crack.scrollFactor.set(0, 0);
			crack.cameras = [camGame];
		}

		voiceLine = new FlxSprite().loadGraphic(Paths.image('voiceline-' + voicelineValue, 'whitty'));
		voiceLine.setGraphicSize(1280,720);
		add(voiceLine);
		voiceLine.alpha = 0;

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		if(curStage == 'philly') {
			phillyCityLightsEvent = new FlxTypedGroup<BGSprite>();
			for (i in 0...5)
			{
				var light:BGSprite = new BGSprite('philly/win' + i, -10, 0, 0.3, 0.3);
				light.visible = false;
				light.setGraphicSize(Std.int(light.width * 0.85));
				light.updateHitbox();
				phillyCityLightsEvent.add(light);
			}
		}


		// "GLOBAL" SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('scripts/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end
		

		// STAGE SCRIPTS
		#if (MODS_ALLOWED && LUA_ALLOWED)
		var doPush:Bool = false;
		var luaFile:String = 'stages/' + curStage + '.lua';
		if(FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}

		if(doPush) 
			luaArray.push(new FunkinLua(luaFile));
		#end

		if(!modchartSprites.exists('blammedLightsBlack')) { //Creates blammed light black fade in case you didn't make your own
			blammedLightsBlack = new ModchartSprite(FlxG.width * -0.5, FlxG.height * -0.5);
			blammedLightsBlack.makeGraphic(Std.int(FlxG.width * 5), Std.int(FlxG.height * 5), FlxColor.BLACK);
			var position:Int = members.indexOf(gfGroup);
			if(members.indexOf(boyfriendGroup) < position) {
				position = members.indexOf(boyfriendGroup);
			} else if(members.indexOf(dadGroup) < position) {
				position = members.indexOf(dadGroup);
			}
			insert(position, blammedLightsBlack);

			blammedLightsBlack.wasAdded = true;
			modchartSprites.set('blammedLightsBlack', blammedLightsBlack);
		}
		if(curStage == 'philly') insert(members.indexOf(blammedLightsBlack) + 1, phillyCityLightsEvent);
		blammedLightsBlack = modchartSprites.get('blammedLightsBlack');
		blammedLightsBlack.alpha = 0.0;

		var gfVersion:String = SONG.gfVersion;
		if(gfVersion == null || gfVersion.length < 1) {
			switch (curStage)
			{
				default:
					gfVersion = 'gf';
			}
			SONG.gfVersion = gfVersion; //Fix for the Chart Editor
		}

		gf = new Character(0, 0, gfVersion);
		startCharacterPos(gf);
		gf.scrollFactor.set(0.95, 0.95);
		gfGroup.add(gf);
		startCharacterLua(gf.curCharacter);

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterLua(dad.curCharacter);
		
		boyfriend = new Boyfriend(0, 0, SONG.player1);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);
		startCharacterLua(boyfriend.curCharacter);
		
		var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);
		if(gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		if(dad.curCharacter.startsWith('gf')) {
			dad.setPosition(GF_X, GF_Y);
			if(gf != null)
				gf.visible = false;
		}

		switch(curStage)
		{	
			case 'CrazyVexationAlley' | 'shitty':
				evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069); //nice (vexation)
				addBehindDad(evilTrail); 
				moreevilTrail = new FlxTrail(boyfriend, null, 4, 24, 0.3, 0.069); //nice (vexation)
				addBehindBF(moreevilTrail); 

			case 'ballistic-bside':
				evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069); //nice (infernum-bside)
				evilTrail.color = FlxColor.fromRGB(76, 235, 255);
				addBehindDad(evilTrail); 
				moreevilTrail = new FlxTrail(boyfriend, null, 4, 24, 0.3, 0.069); //nice (infernum-bside)
				moreevilTrail.color = FlxColor.fromRGB(76, 235, 255);
				addBehindBF(moreevilTrail); 
		}

		var file:String = Paths.json(songName + '/dialogue'); //Checks for json/Psych Engine dialogue
		if (OpenFlAssets.exists(file)) {
			dialogueJson = DialogueBoxPsych.parseDialogue(file);
		}

		var file:String = Paths.txt(songName + '/' + songName + 'Dialogue'); //Checks for vanilla/Senpai dialogue
		if (OpenFlAssets.exists(file)) {
			dialogue = CoolUtil.coolTextFile(file);
		}
		var doof:DialogueBox = new DialogueBox(false, dialogue);
		// doof.x += 70;
		// doof.y = FlxG.height * 0.5;
		doof.scrollFactor.set();
		doof.finishThing = startCountdown;
		doof.nextDialogueThing = startNextDialogue;
		doof.skipDialogueThing = skipDialogue;

		Conductor.songPosition = -5000;

		upperBar = new FlxSprite(0, -120).makeGraphic(1280, 120, FlxColor.BLACK);
		upperBar.cameras = [camHUD];
		add(upperBar);

		lowerBar = new FlxSprite(0, 720).makeGraphic(1280, 120, FlxColor.BLACK);
		lowerBar.cameras = [camHUD];
		add(lowerBar);

		strumLine = new FlxSprite(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, 50).makeGraphic(FlxG.width, 10);
		if(ClientPrefs.downScroll) strumLine.y = FlxG.height - 150;
		strumLine.scrollFactor.set();

		var showTime:Bool = (ClientPrefs.timeBarType != 'Disabled');
		timeTxt = new FlxText(STRUM_X + (FlxG.width / 2) - 248, 19, 400, "", 32);
		timeTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.alpha = 0;
		timeTxt.borderSize = 2;
		timeTxt.visible = showTime;
		if(ClientPrefs.downScroll) timeTxt.y = FlxG.height - 44;

		if(ClientPrefs.timeBarType == 'Song Name')
		{
			timeTxt.text = SONG.song;
		}
		updateTime = showTime;

		timeBarBG = new AttachedSprite('timeBar');
		timeBarBG.x = timeTxt.x;
		timeBarBG.y = timeTxt.y + (timeTxt.height / 4);
		timeBarBG.scrollFactor.set();
		timeBarBG.alpha = 0;
		timeBarBG.visible = showTime;
		timeBarBG.color = FlxColor.BLACK;
		timeBarBG.xAdd = -4;
		timeBarBG.yAdd = -4;
		add(timeBarBG);

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		timeBar.numDivisions = 800; //How much lag this causes?? Should i tone it down to idk, 400 or 200?
		timeBar.alpha = 0;
		timeBar.visible = showTime;
		add(timeBar);
		add(timeTxt);
		timeBarBG.sprTracker = timeBar;

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		add(strumLineNotes);
		add(grpNoteSplashes);

		if(ClientPrefs.timeBarType == 'Song Name')
		{
			timeTxt.size = 24;
			timeTxt.y += 3;
		}

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		// startCountdown();

		generateSong(SONG.song);
		#if LUA_ALLOWED
		for (notetype in noteTypeMap.keys())
		{
			var luaToLoad:String = Paths.modFolders('custom_notetypes/' + notetype + '.lua');
			if(FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			else
			{
				luaToLoad = Paths.getPreloadPath('custom_notetypes/' + notetype + '.lua');
				if(FileSystem.exists(luaToLoad))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
			}
		}
		for (event in eventPushedMap.keys())
		{
			var luaToLoad:String = Paths.modFolders('custom_events/' + event + '.lua');
			if(FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
			}
			else
			{
				luaToLoad = Paths.getPreloadPath('custom_events/' + event + '.lua');
				if(FileSystem.exists(luaToLoad))
				{
					luaArray.push(new FunkinLua(luaToLoad));
				}
			}
		}
		#end
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		// After all characters being loaded, it makes then invisible 0.01s later so that the player won't freeze when you change characters
		// add(strumLine);

		camFollow = new FlxPoint();
		camFollowPos = new FlxObject(0, 0, 1, 1);

		snapCamFollowToPos(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}
		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;
		moveCameraSection(0);

		healthBarBG = new FlxSprite(0, FlxG.height * 0.85).loadGraphic(Paths.image('healthBar'));
        healthBarBG.screenCenter(X);
        healthBarBG.scrollFactor.set();
        healthBarBG.visible = !ClientPrefs.hideHud;
        if(ClientPrefs.downScroll) 
			healthBarBG.y = 80;

        healthBar = new FlxBar(healthBarBG.x + 30, healthBarBG.y + 22, RIGHT_TO_LEFT, 601, 10, this,
            'health', 0, 2);
        healthBar.scrollFactor.set();
        healthBar.visible = !ClientPrefs.hideHud;
        healthBar.alpha = ClientPrefs.healthBarAlpha;
        add(healthBar);
        if(ClientPrefs.downScroll) 
			healthBar.y = 102;
		
		add(healthBarBG);

		healthBarBurn = new FlxSprite(0, FlxG.height * 0.8);
		
		if(SONG.song.toLowerCase() == 'vexation' ||SONG.song.toLowerCase() == 'vexation-hell')  
			healthBarBurn.frames = Paths.getSparrowAtlas('healthBarBurnVex');
		else// if (SONG.song.toLowerCase() == 'infernum' || SONG.song.toLowerCase() == 'infernum-hell') 
			healthBarBurn.frames = Paths.getSparrowAtlas('healthBarBurn');
		
		healthBarBurn.animation.addByPrefix('idle', 'healthbar', 24, true);
		if (ClientPrefs.downScroll)
			healthBarBurn.y = 35;
		healthBarBurn.screenCenter(X);
		healthBarBurn.scrollFactor.set();
		if(SONG.song.toLowerCase() == 'infernum' || SONG.song.toLowerCase() == 'infernum-hell' 
			|| SONG.song.toLowerCase() == 'vexation' ||SONG.song.toLowerCase() == 'vexation-hell') {
			add(healthBarBurn);
			healthBarBurn.animation.play('idle');
			healthBarBG.visible = false;
			healthBar.visible = false;
		}
		
		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		iconP1.visible = !ClientPrefs.hideHud;
		iconP1.alpha = ClientPrefs.healthBarAlpha;
		add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		iconP2.visible = !ClientPrefs.hideHud;
		iconP2.alpha = ClientPrefs.healthBarAlpha;
		add(iconP2);
		reloadHealthBarColors();

		watermark = new FlxText(4,healthBarBG.y + 50,0,SONG.song + " - " + storyDifficultyText, 32); //x, y, fieldWidth, text, size
		watermark.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
		watermark.scrollFactor.set();
		add(watermark);

		if (ClientPrefs.downScroll)
			watermark.y = FlxG.height * 0.9 + 45;

		scoreTxt = new FlxText(FlxG.width / 2 - 235, healthBarBG.y + 56, FlxG.width, "", 32);
		// if(ClientPrefs.showRating)
			// scoreTxt.x = FlxG.width / 2 - 235
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE,FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		// scoreTxt.screenCenter(X);
		scoreTxt.visible = !ClientPrefs.hideHud;												  
		add(scoreTxt);

		botplayTxt = new FlxText(400, timeBarBG.y + 55, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		add(botplayTxt);
		if(ClientPrefs.downScroll) {
			botplayTxt.y = timeBarBG.y - 78;
		}

		
		if(SONG.song.toLowerCase() != 'vexation' || SONG.song.toLowerCase() != 'vexation-hell')
			effect = new FlxSprite().loadGraphic(Paths.image('thefunnyeffect', 'whitty'));
		else
			effect = new FlxSprite().loadGraphic(Paths.image('thefunnyeffectV', 'whitty'));
		effect.setGraphicSize(1280,720);
		effect.updateHitbox();
		effect.blend = MULTIPLY;
		if(curStage == 'CrazyCorruptionAlley' || curStage == 'CrazyVexationAlley')
			add(effect);

		if(SONG.song.endsWith('hell') || SONG.song.endsWith('Hell')) {
			var helleffect = new FlxSprite().loadGraphic(Paths.image('thehelleffect', 'whitty'));
			helleffect.setGraphicSize(1280,720);
			helleffect.updateHitbox();
			helleffect.blend = MULTIPLY;
			helleffect.cameras = [camOther];
			helleffect.alpha = 0.89;
			add(helleffect);
		}

		strumLineNotes.cameras = [camHUD];
		grpNoteSplashes.cameras = [camHUD];
		notes.cameras = [camHUD];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		healthBarBurn.cameras = [camHUD];
		watermark.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		botplayTxt.cameras = [camHUD];
		timeBar.cameras = [camHUD];
		timeBarBG.cameras = [camHUD];
		timeTxt.cameras = [camHUD];
		doof.cameras = [camHUD];
		effect.cameras = [camOther];
		voiceLine.cameras = [camHUD];

                #if android
                addAndroidControls();
                #end

		dialogueBlack = new FlxSprite(0, 0).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		dialogueBlack.screenCenter();
		if(!isStoryMode)
			add(dialogueBlack);

		// if (SONG.song == 'South')
		// FlxG.camera.alpha = 0.7;
		// UI_camera.zoom = 1;

		// cameras = [FlxG.cameras.list[1]];
		startingSong = true;

		// SONG SPECIFIC SCRIPTS
		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('data/' + Paths.formatToSongPath(SONG.song) + '/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('data/' + Paths.formatToSongPath(SONG.song) + '/'));
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/data/' + Paths.formatToSongPath(SONG.song) + '/'));
		#end

		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if(file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end

		if(SONG.song.toLowerCase() == 'deprave') {
			for (i in 0...strumLineNotes.length) {
				strumLineNotes.members[i].alpha = 0;
			}
		}
		
		var daSong:String = Paths.formatToSongPath(curSong);
		if (isStoryMode && !seenCutscene)
		{
			switch (daSong)
			{
				case "monster":
					var whiteScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
					add(whiteScreen);
					whiteScreen.scrollFactor.set();
					whiteScreen.blend = ADD;
					camHUD.visible = false;
					snapCamFollowToPos(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
					inCutscene = true;

					FlxTween.tween(whiteScreen, {alpha: 0}, 1, {
						startDelay: 0.1,
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween)
						{
							camHUD.visible = true;
							remove(whiteScreen);
							startCountdown();
						}
					});
					FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2));
					gf.playAnim('scared', true);
					boyfriend.playAnim('scared', true);

				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite().makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;
					inCutscene = true;

					FlxTween.tween(blackScreen, {alpha: 0}, 0.7, {
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween) {
							remove(blackScreen);
						}
					});
					FlxG.sound.play(Paths.sound('Lights_Turn_On'));
					snapCamFollowToPos(400, -2050);
					FlxG.camera.focusOn(camFollow);
					FlxG.camera.zoom = 1.5;

					new FlxTimer().start(0.8, function(tmr:FlxTimer)
					{
						camHUD.visible = true;
						remove(blackScreen);
						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5, {
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween)
							{
								startCountdown();
							}
						});
					});
				case 'senpai' | 'roses' | 'thorns':
					if(daSong == 'roses') FlxG.sound.play(Paths.sound('ANGRY'));
					schoolIntro(doof);
				
				// case 'deprave':
					// depraveIntro();

				// case 'vexation':
					// vexationIntro();
					// Cutscenes are in LUA bc many bugs and crashes.

				default:
					startCountdown();
			}
			seenCutscene = true;
		} else {
			startCountdown();
		}
		RecalculateRating();

		//PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FRICK THEM UP IDK HOW HAXE WORKS
		if(ClientPrefs.hitsoundVolume > 0) CoolUtil.precacheSound('hitsound');
		CoolUtil.precacheSound('missnote1');
		CoolUtil.precacheSound('missnote2');
		CoolUtil.precacheSound('missnote3');
		CoolUtil.precacheMusic('breakfast');

		#if desktop
		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		#end

		if(!ClientPrefs.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000;
		callOnLuas('onCreatePost', []);
		
		super.create();

		for (key => type in whittyPrecacheList)
		{
			trace('Key $key is type $type');
			switch(type)
			{
				case 'image':
					Paths.image(key, 'whitty');
				case 'sound':
					Paths.sound(key, 'whitty');
				case 'music':
					Paths.music(key, 'whitty');
			}
		}

		for (key => type in precacheList)
		{
			trace('Key $key is type $type');
			switch(type)
			{
				case 'image':
					Paths.image(key);
				case 'sound':
					Paths.sound(key);
				case 'music':
					Paths.music(key);
			}
		}

		Paths.clearUnusedMemory();
		CustomFadeTransition.nextCamera = camOther;
	}

	function set_songSpeed(value:Float):Float
	{
		if(generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
			for (note in notes)
			{
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
				{
					note.scale.y *= ratio;
					note.updateHitbox();
				}
			}
			for (note in unspawnNotes)
			{
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
				{
					note.scale.y *= ratio;
					note.updateHitbox();
				}
			}
		}
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}

	function defeatBg(enable:Bool){
		if (!enable) {
			bbg.visible = false;
			healthBarBurn.visible = true;
			timeBar.visible = true;
			scoreTxt.visible = true;
			timeTxt.visible = true;
			iconP1.visible = true;
			iconP2.visible = true;
			fireEffect.visible = true;
			emitter.visible = true;
			fire3.alpha = 0.9;
			fire4.alpha = 0.9;
			
		} else{
			bbg.visible = true;
			healthBar.visible = false;
			healthBarBG.visible = false;
			healthBarBurn.visible = false;
			timeBar.visible = false;
			scoreTxt.visible = false;
			timeTxt.visible = false;
			iconP1.visible = false;
			iconP2.visible = false;
			fireEffect.visible = false;
			emitter.visible = false;
			fire3.alpha = 0;
			fire4.alpha = 0;
		}
	}
	
	function set_playbackRate(value:Float):Float
	{
		if(generatedMusic)
		{
			if(vocals != null) vocals.pitch = value;
			FlxG.sound.music.pitch = value;
		}
		playbackRate = value;
		FlxAnimationController.globalSpeed = value;
		trace('Anim speed: ' + FlxAnimationController.globalSpeed);
		Conductor.safeZoneOffset = (ClientPrefs.safeFrames / 60) * 1000 * value;
		setOnLuas('playbackRate', playbackRate);
		return value;
	}
	
	function addTrail(target, alpha, delay, ?color){
		var trail = new FlxTrail(target, null, 4, delay, alpha, 0.069); //target, graphic, length, delay(in ms), alpha, diff
		insert(members.indexOf(target) - 1, trail);//nice position
	}

	public function addTextToDebug(text:String) {
		#if LUA_ALLOWED
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
			spr.y += 20;
		});

		if(luaDebugGroup.members.length > 34) {
			var blah = luaDebugGroup.members[34];
			blah.destroy();
			luaDebugGroup.remove(blah);
		}
		luaDebugGroup.insert(0, new DebugLuaText(text, luaDebugGroup));
		#end
	}

	public function reloadHealthBarColors() {
		healthBar.createFilledBar(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
			
		healthBar.updateBar();
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Boyfriend = new Boyfriend(0, 0, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);
					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = 0.00001;
					startCharacterLua(newBoyfriend.curCharacter);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacterPos(newDad, true);
					newDad.alpha = 0.00001;
					startCharacterLua(newDad.curCharacter);
				}

			case 2:
				if(gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacterPos(newGf);
					newGf.alpha = 0.00001;
					startCharacterLua(newGf.curCharacter);
				}
		}
	}

	function startCharacterLua(name:String)
	{
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/' + name + '.lua';
		if(FileSystem.exists(Paths.modFolders(luaFile))) {
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		} else {
			luaFile = Paths.getPreloadPath(luaFile);
			if(FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}
		
		if(doPush)
		{
			for (lua in luaArray)
			{
				if(lua.scriptName == luaFile) return;
			}
			luaArray.push(new FunkinLua(luaFile));
		}
		#end
	}
	
  public function addShaderToCamera(cam:String,effect:Dynamic){//STOLE FROM ANDROMEDA
	  
	  
	  
		switch(cam.toLowerCase()) {
			case 'camhud' | 'hud':
					camHUDShaders.push(effect);
					var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
					for(i in camHUDShaders){
					  newCamEffects.push(new ShaderFilter(i.shader));
					}
					camHUD.setFilters(newCamEffects);
			case 'camother' | 'other':
					camOtherShaders.push(effect);
					var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
					for(i in camOtherShaders){
					  newCamEffects.push(new ShaderFilter(i.shader));
					}
					camOther.setFilters(newCamEffects);
			case 'camgame' | 'game':
					camGameShaders.push(effect);
					var newCamEffects:Array<BitmapFilter>=[]; // IT SHUTS HAXE UP IDK WHY BUT WHATEVER IDK WHY I CANT JUST ARRAY<SHADERFILTER>
					for(i in camGameShaders){
					  newCamEffects.push(new ShaderFilter(i.shader));
					}
					camGame.setFilters(newCamEffects);
			default:
				if(modchartSprites.exists(cam)) {
					Reflect.setProperty(modchartSprites.get(cam),"shader",effect.shader);
				} else if(modchartTexts.exists(cam)) {
					Reflect.setProperty(modchartTexts.get(cam),"shader",effect.shader);
				} else {
					var OBJ = Reflect.getProperty(PlayState.instance,cam);
					Reflect.setProperty(OBJ,"shader", effect.shader);
				}
			
			
				
				
		}
	  
	  
	  
	  
  }

  public function removeShaderFromCamera(cam:String,effect:ShaderEffect){
	  
	  
		switch(cam.toLowerCase()) {
			case 'camhud' | 'hud': 
    camHUDShaders.remove(effect);
    var newCamEffects:Array<BitmapFilter>=[];
    for(i in camHUDShaders){
      newCamEffects.push(new ShaderFilter(i.shader));
    }
    camHUD.setFilters(newCamEffects);
			case 'camother' | 'other': 
					camOtherShaders.remove(effect);
					var newCamEffects:Array<BitmapFilter>=[];
					for(i in camOtherShaders){
					  newCamEffects.push(new ShaderFilter(i.shader));
					}
					camOther.setFilters(newCamEffects);
			default: 
				if(modchartSprites.exists(cam)) {
					Reflect.setProperty(modchartSprites.get(cam),"shader",null);
				} else if(modchartTexts.exists(cam)) {
					Reflect.setProperty(modchartTexts.get(cam),"shader",null);
				} else {
					var OBJ = Reflect.getProperty(PlayState.instance,cam);
					Reflect.setProperty(OBJ,"shader", null);
				}
				
		}
		
	  
  }
	
	
	
  public function clearShaderFromCamera(cam:String){
	  
	  
		switch(cam.toLowerCase()) {
			case 'camhud' | 'hud': 
				camHUDShaders = [];
				var newCamEffects:Array<BitmapFilter>=[];
				camHUD.setFilters(newCamEffects);
			case 'camother' | 'other': 
				camOtherShaders = [];
				var newCamEffects:Array<BitmapFilter>=[];
				camOther.setFilters(newCamEffects);
			case 'camgame' | 'game': 
				camGameShaders = [];
				var newCamEffects:Array<BitmapFilter>=[];
				camGame.setFilters(newCamEffects);
			default: 
				camGameShaders = [];
				var newCamEffects:Array<BitmapFilter>=[];
				camGame.setFilters(newCamEffects);
		}
		
	  
  }
	
	
	
	
	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function getLuaObject(tag:String, text:Bool=true):FlxSprite {
		if(modchartSprites.exists(tag)) return modchartSprites.get(tag);
		if(text && modchartTexts.exists(tag)) return modchartTexts.get(tag);
		if(variables.exists(tag)) return variables.get(tag);
		return null;
	}

	public function startVideo(name:String):Void {
		#if VIDEOS_ALLOWED
		var foundFile:Bool = false;
		var fileName:String = #if MODS_ALLOWED Paths.modFolders('videos/' + name + '.' + Paths.VIDEO_EXT); #else ''; #end
		#if sys
		if(FileSystem.exists(fileName)) {
			foundFile = true;
		}
		#end

		if(!foundFile) {
			fileName = Paths.video(name);
			#if sys
			if(FileSystem.exists(fileName)) {
			#else
			if(OpenFlAssets.exists(fileName)) {
			#end
				foundFile = true;
			}
		}

		if(foundFile) {
			inCutscene = true;
			var bg = new FlxSprite(-FlxG.width, -FlxG.height).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
			bg.scrollFactor.set();
			bg.cameras = [camHUD];
			add(bg);

			(new FlxVideo(fileName)).finishCallback = function() {
				remove(bg);
				startAndEnd();
			}
			return;
		}
		else
		{
			FlxG.log.warn('Couldnt find video file: ' + fileName);
			startAndEnd();
		}
		#end
		startAndEnd();
	}

	function startAndEnd()
	{
		if(endingSong)
			endSong();
		else
			startCountdown();
	}

	var dialogueCount:Int = 0;
	var psychDialogue:DialogueBoxPsych;
	//You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void
	{
		
		// TO DO: Make this more flexible, maybe?
		if(psychDialogue != null) return;

		if(dialogueFile.dialogue.length > 0) {
			inCutscene = true;
			CoolUtil.precacheSound('dialogue');
			CoolUtil.precacheSound('dialogueClose');
			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();
			if(endingSong) {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					endSong();
					remove(psychDialogue);
				}
			} else {
				psychDialogue.finishThing = function() {
					psychDialogue = null;
					startCountdown();
					remove(psychDialogue);
				}
			}
			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		} else {
			FlxG.log.warn('Your dialogue file is badly formatted!');
			trace('Your dialogue file is badly formatted!');
			if(endingSong) {
				endSong();
			} else {
				startCountdown();
			}
		}
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		inCutscene = true;
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var black2:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black2.scrollFactor.set();
		add(black2);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += 300;

		var songName:String = Paths.formatToSongPath(SONG.song);
		if (songName == 'roses' || songName == 'thorns')
		{
			remove(black);

			if (songName == 'thorns')
			{
				add(red);
				camHUD.visible = false;
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				if (dialogueBox != null)
				{
					if (Paths.formatToSongPath(SONG.song) == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
							{
								swagTimer.reset();
							}
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
										camHUD.visible = true;
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
					{
						add(dialogueBox);
					}
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	function depraveIntro()
	{
		inCutscene = true;
				
		var black:FlxSprite = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		black.alpha = 1;
		add(black);
		
		var whitty:FlxSprite = new FlxSprite(-38, -67);
		whitty.frames = Paths.getSparrowAtlas('cutscene/WhittyC_Cutscene', 'whitty');
		whitty.animation.addByPrefix('look', 'look', 24, false);
		whitty.animation.addByPrefix('hurt', 'hurt', 24, false);
		whitty.animation.addByPrefix('turn', 'turn', 24, false);
		whitty.animation.addByPrefix('hit', 'hit', 24, false);
		whitty.animation.addByPrefix('catch', 'catch', 24, false);
		add(whitty);

		var mic:FlxSprite = new FlxSprite(900,500);
		mic.frames = Paths.getSparrowAtlas('cutscene/micSpin', 'whitty');
		mic.animation.addByPrefix('spin','spin',24,true);
        add(mic);
		mic.visible = false;

		dad.alpha = 0;
		boyfriend.alpha = 0;
		camFollowPos.setPosition(500, 400);
		FlxG.sound.play('city');
		new FlxTimer().start(0.5, function(tmr:FlxTimer)
		{
			
			FlxTween.tween(camGame, {zoom: 1.3} ,3.5, {ease: FlxEase.sineOut});
			FlxTween.tween(camFollowPos, {x: camFollowPos.x - 100}, 3.5, {ease: FlxEase.cubeOut});
			FlxTween.tween(camFollowPos, {y: camFollowPos.y - 200}, 3.5, {ease: FlxEase.cubeOut});
			FlxTween.tween(black, {alpha: 0}, 1, {ease: FlxEase.sineOut,
			onComplete: function(twn:FlxTween)
			{
				whitty.animation.play('look');
				new FlxTimer().start(2, function(tmr:FlxTimer)
				{
					whitty.animation.play('hurt');
					FlxG.sound.play('fire');
					new FlxTimer().start(2, function(tmr:FlxTimer)
					{
						FlxTween.tween(camGame, {zoom: defaultCamZoom + 0.2} ,0.7, {ease: FlxEase.sineOut});
						FlxTween.tween(camFollowPos, {x: camFollowPos.x + 450}, 0.7, {ease: FlxEase.circOut});
						FlxTween.tween(camFollowPos, {y: camFollowPos.y + 250}, 0.7, {ease: FlxEase.circOut});
						boyfriend.visible = true;
						FlxG.sound.play('beepboop');
						boyfriend.playAnim('singLEFT');
						new FlxTimer().start(2, function(tmr:FlxTimer)
						{
							FlxTween.tween(camGame, {zoom: defaultCamZoom} ,0.7, {ease: FlxEase.sineOut});
							FlxTween.tween(camFollowPos, {x: 500}, 0.7, {ease: FlxEase.circOut});
							FlxTween.tween(camFollowPos, {y: 400}, 0.7, {ease: FlxEase.circOut});
        					whitty.animation.play('turn');
							new FlxTimer().start(1.25, function(tmr:FlxTimer)
							{
								boyfriend.playAnim('pre-attack');
								new FlxTimer().start(0.55, function(tmr:FlxTimer)
								{
									boyfriend.playAnim('attack');
									FlxG.sound.play('micSpin');
									FlxTween.tween(mic, {x: 200} ,0.4);
									FlxTween.tween(mic, {y: 200} ,0.4);
									mic.visible = true;
									new FlxTimer().start(0.5, function(tmr:FlxTimer)
									{
										whitty.animation.play('hit');
										FlxG.camera.shake(0.02, 0.2);
										FlxG.sound.play('micThrow');
										FlxG.sound.play('ballistic');
										remove(mic);
										new FlxTimer().start(1, function(tmr:FlxTimer)
										{
											whitty.animation.play('catch');
											FlxG.sound.play('take');
											new FlxTimer().start(1.5, function(tmr:FlxTimer)
											{
												FlxTween.tween(black, {alpha: 1}, 0.8, {ease:FlxEase.sineOut,
												onComplete: function(twn:FlxTween)
												{
													dad.alpha = 1;
													boyfriend.alpha = 1;	
												}
											});
										});
									});
								});
							});
						});
					});
				});
			});
		}
		});
	});
}

	
	function vexationOutro():Void
	{
		inCutscene = true;
				
		spaceBar.visible = false;

		var black2:FlxSprite = new FlxSprite(-600, -300).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black2.scrollFactor.set();
		add(black2);

		camHUD.visible = false;

		var vexationOutro:FlxSprite = new FlxSprite().loadGraphic(Paths.image('tobecontinued', 'whitty'));
		// vexationOutro.scale.set(1.4, 1.4);
		vexationOutro.scrollFactor.set();
		vexationOutro.updateHitbox();
		vexationOutro.screenCenter();
		vexationOutro.cameras = [camOther];

		var codes:FlxSprite = new FlxSprite().loadGraphic(Paths.image('codes', 'whitty'));
		// codes.scale.set(1.4, 1.4);
		codes.scrollFactor.set();
		codes.updateHitbox();
		codes.screenCenter();
		codes.cameras = [camOther];
		codes.alpha = 0;
	
		new FlxTimer().start(0.1, function(tmr:FlxTimer)
		{
			FlxG.sound.play(Paths.sound('vexation_outro'), 1);

			new FlxTimer().start(0.37, function(tmr:FlxTimer)
			{
				add(vexationOutro);
				new FlxTimer().start(0.9, function(tmr:FlxTimer)
				{
					FlxTween.tween(vexationOutro, {alpha: 0}, 1, {ease:FlxEase.linear,
						onComplete: function(twn:FlxTween) {
							new FlxTimer().start(3.37, function(tmr:FlxTimer)
							{
								add(codes);
								FlxTween.tween(codes, {alpha: 1}, 0.5);
								new FlxTimer().start(3.37, function(tmr:FlxTimer)
								{
									MusicBeatState.switchState(new SoundTestMenu());
									// FlxG.sound.music.fadeIn(2, 0, 0.9); //duration, from volume, to volume
									// FlxG.sound.playMusic(Paths.music('breakfast'));
								});
							});
						}
					});
				});
			});
		});
	}

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;

	public static var startOnTime:Float = 0;

	public function startCountdown():Void
	{
		if(startedCountdown) {
			callOnLuas('onStartCountdown', []);
			return;
		}

		inCutscene = false;
		var ret:Dynamic = callOnLuas('onStartCountdown', []);
		if(ret != FunkinLua.Function_Stop) {

			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;
                        #if android
                        androidc.visible = true;
                        #end
			generateStaticArrows(0);
			generateStaticArrows(1);
			for (i in 0...playerStrums.length) {
				setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}
			for (i in 0...opponentStrums.length) {
				setOnLuas('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnLuas('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
				//if(ClientPrefs.middleScroll) opponentStrums.members[i].visible = false;
			}

			startedCountdown = true;
			Conductor.songPosition = 0;
			Conductor.songPosition -= Conductor.crochet * 5;
			setOnLuas('startedCountdown', true);
			callOnLuas('onCountdownStarted', []);

			var swagCounter:Int = 0;

			if(startOnTime < 0) startOnTime = 0;

			if (startOnTime > 0) {
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 350);
				return;
			}
			else if (skipCountdown)
			{
				setSongTime(0);
				return;
				swagCounter = 3;
			}

			startTimer = new FlxTimer().start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer)
			{
				if (gf != null && tmr.loopsLeft % gfSpeed == 0 && !gf.stunned && gf.animation.curAnim.name != null && !gf.animation.curAnim.name.startsWith("sing"))
				{
					gf.dance();
				}
				if(tmr.loopsLeft % 2 == 0) {
					if (boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing'))
					{
						boyfriend.dance();
					}
					if (dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
					{
						dad.dance();
					}
				}
				else if(dad.danceIdle && dad.animation.curAnim != null && !dad.stunned && !dad.curCharacter.startsWith('gf') && !dad.animation.curAnim.name.startsWith("sing"))
				{
					dad.dance();
				}

				var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
				introAssets.set('default', ['ready', 'set', 'go']);
				introAssets.set('pixel', ['pixelUI/ready-pixel', 'pixelUI/set-pixel', 'pixelUI/date-pixel']);

				var introAlts:Array<String> = introAssets.get('default');
				var antialias:Bool = ClientPrefs.globalAntialiasing;
				if(isPixelStage) {
					introAlts = introAssets.get('pixel');
					antialias = false;
				}

				// head bopping for bg characters on Mall

				switch (swagCounter)
				{
					case 0:
						FlxG.sound.play(Paths.sound('intro3' + introSoundsSuffix), 0.6);
						FlxTween.tween(dialogueBlack, {alpha: 0}, 0.8);
					case 1:
						countdownReady = new FlxSprite().loadGraphic(Paths.image(introAlts[0]));
						countdownReady.scrollFactor.set();
						countdownReady.updateHitbox();

						if (PlayState.isPixelStage)
							countdownReady.setGraphicSize(Std.int(countdownReady.width * daPixelZoom));

						countdownReady.screenCenter();
						countdownReady.antialiasing = antialias;
						add(countdownReady);
						FlxTween.tween(countdownReady, {/*y: countdownReady.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownReady);
								countdownReady.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro2' + introSoundsSuffix), 0.6);
					case 2:
						countdownSet = new FlxSprite().loadGraphic(Paths.image(introAlts[1]));
						countdownSet.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownSet.setGraphicSize(Std.int(countdownSet.width * daPixelZoom));

						countdownSet.screenCenter();
						countdownSet.antialiasing = antialias;
						add(countdownSet);
						FlxTween.tween(countdownSet, {/*y: countdownSet.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownSet);
								countdownSet.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('intro1' + introSoundsSuffix), 0.6);
					case 3:
						if (!skipCountdown){
						countdownGo = new FlxSprite().loadGraphic(Paths.image(introAlts[2]));
						countdownGo.scrollFactor.set();

						if (PlayState.isPixelStage)
							countdownGo.setGraphicSize(Std.int(countdownGo.width * daPixelZoom));

						countdownGo.updateHitbox();

						countdownGo.screenCenter();
						countdownGo.antialiasing = antialias;
						add(countdownGo);
						FlxTween.tween(countdownGo, {/*y: countdownGo.y + 100,*/ alpha: 0}, Conductor.crochet / 1000, {
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween)
							{
								remove(countdownGo);
								countdownGo.destroy();
							}
						});
						FlxG.sound.play(Paths.sound('introGo' + introSoundsSuffix), 0.6);
						}
					case 4:
				}

				notes.forEachAlive(function(note:Note) {
					note.copyAlpha = false;
					note.alpha = note.multAlpha;
					if(ClientPrefs.middleScroll && !note.mustPress) {
						note.alpha *= 0.5;
					}
				});
				callOnLuas('onCountdownTick', [swagCounter]);

				swagCounter += 1;
				// generateSong('fresh');
			}, 5);
		}
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = unspawnNotes[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;
						
				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}
			--i;
		}
	
		i = notes.length - 1;
		while (i >= 0) {
			var daNote:Note = notes.members[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;
	
				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}
			--i;
		}
	}

	public function setSongTime(time:Float)
	{
		if(time < 0) time = 0;
		
		FlxG.sound.music.pause();
		vocals.pause();
	
		FlxG.sound.music.time = time;
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.play();
	
		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = time;
			vocals.pitch = playbackRate;
		}
		vocals.play();
		Conductor.songPosition = time;
		songTime = time;
	}

	function startNextDialogue() {
		dialogueCount++;
		callOnLuas('onNextDialogue', [dialogueCount]);
	}

	function skipDialogue() {
		callOnLuas('onSkipDialogue', [dialogueCount]);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 1, false);
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.onComplete = finishSong;
		vocals.play();

		if(startOnTime > 0)
		{
			setSongTime(startOnTime - 500);
		}
		startOnTime = 0;

		if(paused) {
			//trace('Oopsie doopsie! Paused sound');
			FlxG.sound.music.pause();
			vocals.pause();
		}

		// Song duration in a float, useful for the time left feature
		songLength = FlxG.sound.music.length;
		FlxTween.tween(timeBar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		FlxTween.tween(timeTxt, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		
		#if desktop
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength);
		#end
		setOnLuas('songLength', songLength);
		callOnLuas('onSongStart', []);
	}

	var debugNum:Int = 0;
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();
	private function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype','multiplicative');

		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}
		
		var songData = SONG;
		Conductor.changeBPM(songData.bpm);
		
		curSong = songData.song;

		if (SONG.needsVoices)
			//Use this path for bf vexation
			// if(Paths.formatToSongPath(SONG.song) == 'vexation')
			// {
				// vocals = new FlxSound().loadEmbedded(Paths.voicesOG(PlayState.SONG.song));
			// }
			// else
			// {
				vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
			// }
		else
			vocals = new FlxSound();

		vocals.pitch = playbackRate;
		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.inst(PlayState.SONG.song)));

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW STUFF
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped

		var songName:String = Paths.formatToSongPath(SONG.song);
		var file:String = Paths.json(songName + '/events');
		#if sys
		if (FileSystem.exists(Paths.modsJson(songName + '/events')) || FileSystem.exists(file)) {
		#else
		if (OpenFlAssets.exists(file)) {
		#end
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songName).events;
			for (event in eventsData) //Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
					var subEvent:EventNote = {
						strumTime: newEventNote[0] + ClientPrefs.noteOffset,
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
					};
					subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3)
				{
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote);
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				swagNote.gfNote = (section.gfSection && (songNotes[1]<4));
				swagNote.noteType = songNotes[3];
				if(!Std.isOfType(songNotes[3], String)) swagNote.noteType = editors.ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts
				
				swagNote.scrollFactor.set();

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				var floorSus:Int = Math.floor(susLength);
				if(floorSus > 0) {
					for (susNote in 0...floorSus+1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)), daNoteData, oldNote, true);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = (section.gfSection && (songNotes[1]<4));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						unspawnNotes.push(sustainNote);

						if (sustainNote.mustPress)
						{
							sustainNote.x += FlxG.width / 2; // general offset
						}
						else if(ClientPrefs.middleScroll)
						{
							sustainNote.x += 310;
							if(daNoteData > 1) //Up and Right
							{
								sustainNote.x += FlxG.width / 2 + 25;
							}
						}
					}
				}

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
				else if(ClientPrefs.middleScroll)
				{
					swagNote.x += 310;
					if(daNoteData > 1) //Up and Right
					{
						swagNote.x += FlxG.width / 2 + 25;
					}
				}

				if(!noteTypeMap.exists(swagNote.noteType)) {
					noteTypeMap.set(swagNote.noteType, true);
				}
			}
			daBeats += 1;
		}
		for (event in songData.events) //Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];
				var subEvent:EventNote = {
					strumTime: newEventNote[0] + ClientPrefs.noteOffset,
					event: newEventNote[1],
					value1: newEventNote[2],
					value2: newEventNote[3]
				};
				subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
				eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}

		// trace(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByShit);
		if(eventNotes.length > 1) { //No need to sort if there's a single one or none at all
			eventNotes.sort(sortByTime);
		}
		checkEventNote();
		generatedMusic = true;
	}

	function eventPushed(event:EventNote) {
		switch(event.event) {
			case 'Change Character':
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						charType = Std.parseInt(event.value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);
			case 'Deprave Spotlight':
				depraveBlack = new BGSprite(null, -800, -400, 0, 0);
				depraveBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				depraveBlack.alpha = 0.25;
				depraveBlack.visible = false;
				add(depraveBlack);

				depraveLight = new BGSprite('spotlight', 'whitty', 400, -400);
				depraveLight.alpha = 0.375;
				depraveLight.blend = ADD;
				depraveLight.visible = false;

				depraveSmokes.alpha = 0.7;
				depraveSmokes.blend = ADD;
				depraveSmokes.visible = false;
				add(depraveLight);
				// add(depraveSmokes);

				var offsetX = 200;
				var smoke:BGSprite = new BGSprite('smoke', 'whitty', -1550 + offsetX, 760 /*+ FlxG.random.float(-100, 100)*/, 1.2, 1.05);
				smoke.setGraphicSize(Std.int(smoke.width * FlxG.random.float(1.1, 1.22)));
				smoke.updateHitbox();
				smoke.velocity.x = FlxG.random.float(15, 22);
				smoke.active = true;
				// depraveSmokes.add(smoke);
				
				var smoke:BGSprite = new BGSprite('smoke', 'whitty', 1550 + offsetX, 760 /*+ FlxG.random.float(-100, 100)*/, 1.2, 1.05);
				smoke.setGraphicSize(Std.int(smoke.width * FlxG.random.float(1.1, 1.22)));
				smoke.updateHitbox();
				smoke.velocity.x = FlxG.random.float(-15, -22);
				smoke.active = true;
				smoke.flipX = true;
				// depraveSmokes.add(smoke);
		}

		if(!eventPushedMap.exists(event.event)) {
			eventPushedMap.set(event.event, true);
		}
	}

	function eventNoteEarlyTrigger(event:EventNote):Float {
		var returnedValue:Float = callOnLuas('eventEarlyTrigger', [event.event]);
		if(returnedValue != 0) {
			return returnedValue;
		}

		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByTime(Obj1:EventNote, Obj2:EventNote):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public var skipArrowStartTween:Bool = false; //for lua

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			// FlxG.log.add(i);
			var targetAlpha:Float = 1;
			if (player < 1 && ClientPrefs.middleScroll) targetAlpha = 0.35;

			var babyArrow:StrumNote = new StrumNote(ClientPrefs.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, player);
			babyArrow.downScroll = ClientPrefs.downScroll;
			if (!isStoryMode && !skipArrowStartTween)
			{
				babyArrow.y -= 10;
				babyArrow.alpha = 0;
				if(SONG.song.toLowerCase() == 'deprave') {
					FlxTween.tween(babyArrow, {y: babyArrow.y + 10}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
				} else {
					FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
				}
			}
			else
			{
				if(SONG.song.toLowerCase() == 'deprave') {
					babyArrow.alpha = 0;
				} else {
					babyArrow.alpha = targetAlpha;
				}
			}

			if (player == 1)
			{
				playerStrums.add(babyArrow);
			}
			else
			{
				if(ClientPrefs.middleScroll)
				{
					babyArrow.x += 310;
					if(i > 1) { //Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
				opponentStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (!startTimer.finished)
				startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;
			if (songSpeedTween != null)
				songSpeedTween.active = false;

			if(blammedLightsBlackTween != null)
				blammedLightsBlackTween.active = false;
			if(phillyCityLightsEventTween != null)
				phillyCityLightsEventTween.active = false;


			var chars:Array<Character> = [boyfriend, gf, dad];
			for (i in 0...chars.length) {
				if(chars[i].colorTween != null) {
					chars[i].colorTween.active = false;
				}
			}

			for (tween in modchartTweens) {
				tween.active = false;
			}
			for (timer in modchartTimers) {
				timer.active = false;
			}
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (FlxG.sound.music != null && !startingSong)
			{
				resyncVocals();
			}

			if (!startTimer.finished)
				startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;
			if (songSpeedTween != null)
				songSpeedTween.active = true;

			if(blammedLightsBlackTween != null)
				blammedLightsBlackTween.active = true;
			if(phillyCityLightsEventTween != null)
				phillyCityLightsEventTween.active = true;
			

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (i in 0...chars.length) {
				if(chars[i].colorTween != null) {
					chars[i].colorTween.active = true;
				}
			}
			
			for (tween in modchartTweens) {
				tween.active = true;
			}
			for (timer in modchartTimers) {
				timer.active = true;
			}
			paused = false;
			callOnLuas('onResume', []);

			#if desktop
			if (startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
			#end
		}

		super.closeSubState();
	}

	/*public function createTrailFrame(tag) {
		var num:Int = 0;
		var color:Int = -1;
		var image:String = '';
		var frame:String = 'BF idle dance';
		var x:Float = 0;
		var y:Float = 0;
		var scaleX:Float = 0;
		var scaleY:Float = 0;
		var offsetX:Float = 0;
		var offsetY:Float = 0;
		var flipX:Bool = false;

		if (tag == 'BF') {
			num = curTrailBF;
			curTrailBF = curTrailBF + 1;
			if (trailEnabledBF) {
				color = 0xFF00F7FF;
				image = boyfriend.imageFile;
				frame = boyfriend.animation.frameName;
				x = boyfriend.x;
				y = boyfriend.y;
				scaleX = boyfriend.scale.x; 
				scaleY = boyfriend.scale.y; 
				offsetX = boyfriend.offset.x;
				offsetY = boyfriend.offset.y;
				flipX = boyfriend.flipX;
			}
		}
		else {
			num = curTrailDad;
			curTrailDad = curTrailDad + 1;
			if (trailEnabledDad) {
				color = FF0800;
				image = dad.imageFile;
				frame = dad.animation.frameName;
				x = dad.x;
				y = dad.y;
				scaleX = dad.scale.x;
				scaleY = dad.scale.y;
				offsetX = dad.offset.x;
				offsetY = dad.offset.y;
				flipX = dad.flipX;
			}
		}

		if (num - trailLength + 1 >= 0) {
			for (i in (num - trailLength + 1)...(num - 1)) {
				psychicTrail + tag + i.alpha =  psychicTrail + tag + i.alpha - (0.6 / (trailLength - 1));
			}
		}
		remove(psychicTrail + tag + (num - trailLength));

		if (image != '') {
			trailTag = 'psychicTrail' + tag + num;
			trailTag = new FlxSprite(x, y);
			trailTag.frames = Paths.getSparrowAtlas(image);
			trailTag.offset.x, offsetX;
			trailTag.offset.y, offsetY;
			trailTag.scale.x, scaleX;
			trailTag.scale.x, scaleY;
			trailTag.flipX, flipX;
			trailTag.alpha, 0.6;
			trailTag.color, color;
			trailTag.blendMode =  ADD;
			trailTag.animation.addByPrefix('stuff', frame, 0, false);
			add(trailTag);
		}
	}*/

	override public function onFocus():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter(), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
			}
		}
		#end

		super.onFocus();
	}
	
	override public function onFocusLost():Void
	{
		#if desktop
		if (health > 0 && !paused)
		{
			DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
		}
		#end

		super.onFocusLost();
	}

	function resyncVocals():Void
	{
		if(finishTimer != null) return;

		vocals.pause();

		FlxG.sound.music.play();
		FlxG.sound.music.pitch = playbackRate;
		Conductor.songPosition = FlxG.sound.music.time;
		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = Conductor.songPosition;
			vocals.pitch = playbackRate;
		}
		vocals.play();
	}

	public function addBehindGF(obj:FlxObject)
	{
		insert(members.indexOf(gfGroup), obj);
	}
	public function addBehindBF(obj:FlxObject)
	{
		insert(members.indexOf(boyfriendGroup), obj);
	}
	public function addBehindDad (obj:FlxObject)
	{
		insert(members.indexOf(dadGroup), obj);
	}
	

	public var paused:Bool = false;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;

	function grabBF()
	{
		grabbed = true;
		vine.alpha = 1;
		vine.animation.play('vine');
		new FlxTimer().start(0.8, function(tmr:FlxTimer)
		{
			if (cpuControlled){
				heDone();
				FlxG.sound.play(Paths.sound('bf_grabbed_by_vine'), 0.9);
			}
			boyfriend.playAnim('heldByVine', true);
			boyfriend.specialAnim = true;
			FlxG.sound.play(Paths.sound('bf_grabbed_by_vine'), 0.9);
			startPressin();
			hideSpacebar();
			showSpacebar();
		});
	}

	function hideSpacebar() {
		spaceBar.alpha = 0;
	}

	function showSpacebar() {
		spaceBar.alpha = 1;
		spaceBar.animation.play('spaceBar');
	}
	
	function startPressin(){
		boyfriend.stunned = true;
		// FlxG.camera.shake(0.009, 0.1);
		stun = true;
		finished = false;
	}
	
	function heDone() {
		counter = 0;
		stun = false;
		finished = false;
		boyfriend.stunned = false;
		boyfriend.playAnim('axe', true);
		boyfriend.specialAnim = true;
		hideSpacebar();
		new FlxTimer().start(1.19, function(tmr:FlxTimer)
		{
			boyfriend.playAnim('dodge', true);
			boyfriend.specialAnim = true;
			vine.animation.reverse();
			boyfriend.dance();
			new FlxTimer().start(0.89, function(tmr:FlxTimer)
			{
				vine.alpha = 0;
			});
		});
	}

	var grabbed:Bool = false;
	var stun:Bool = false;
	var finished:Bool = false;
	var counter:Int = 0;

	override public function update(elapsed:Float)
	{
		if (FlxG.keys.justPressed.NINE)
		{
			iconP1.swapOldIcon();
		}

		if (curStage == 'shitty')
		{
			if(FlxG.keys.justPressed.SPACE) {
				remove(jumpscare);
				jumpscare.visible = false;
			}
		}

		if(SONG.song.toLowerCase() == 'infernum' || SONG.song.toLowerCase() == 'vexation' 
			|| SONG.song.toLowerCase() == 'infernum-hell' || SONG.song.toLowerCase() == 'vexation-hell')
			ClientPrefs.noteSkin == 'Default';

		if (dad.curCharacter.startsWith('WhittyCrazyV2'))
			circ.alpha = 0.7;

		if (stun && counter == 0 && FlxG.keys.justPressed.SPACE){
			counter = (counter + 1);
			finished = true;
		}
		else if (finished)
			heDone();

		callOnLuas('onUpdate', [elapsed]);
			// gf.visible = false;
		if(camEmitt)
			emitt();
		
		switch (curStage)
		{
			case 'CrazyCorruptionAlley' | 'CrazyVexationAlley':

				if(ClientPrefs.flashing)
					effect.alpha = health / 1.5;
		}

		switch (curStage)
		{
			case 'CrazyVexationAlley':

				FlxG.camera.shake(0.005, songLength);
				camHUD.shake(0.001, songLength);
		}

		if(!inCutscene) {
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed * playbackRate, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
			if(!startingSong && !endingSong && boyfriend.animation.curAnim.name.startsWith('idle')) {
				boyfriendIdleTime += elapsed;
				if(boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			} else {
				boyfriendIdleTime = 0;
			}
		}

		super.update(elapsed);

		if(ClientPrefs.showRating) {
			if(ratingName == '?') {
				scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Rating: ' + ratingName;
			} else {
				scoreTxt.text = 'Score: ' + songScore + ' | Misses: ' + songMisses + ' | Rating: ' + ratingName + ' (' + Highscore.floorDecimal(ratingPercent * 100, 2) + '%)' + ' - ' + ratingFC;//peeps wanted no integer rating
			}
		} else {
			if(ratingName == '?') {
				scoreTxt.text = 'ㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤScore: ' + songScore;
			} else {
				scoreTxt.text = 'ㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤㅤScore: ' + songScore;//peeps wanted no integer rating
			}
		}

		if(botplayTxt.visible) {
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (controls.PAUSE #if android || FlxG.android.justReleased.BACK #end && startedCountdown && canPause)
		{

		}

		if (controls.PAUSE && startedCountdown && canPause && SONG.song.toLowerCase() != 'vexation-hell')
		{
			var ret:Dynamic = callOnLuas('onPause', []);
			if(ret != FunkinLua.Function_Stop) {
				persistentUpdate = false;
				persistentDraw = true;
				paused = true;

				// 1 / 1000 chance for Gitaroo Man easter egg
				/*if (FlxG.random.bool(0.1))
				{
					// gitaroo man easter egg
					cancelMusicFadeTween();
					MusicBeatState.switchState(new GitarooPause());
				}
				else {*/
				if(FlxG.sound.music != null) {
					FlxG.sound.music.pause();
					vocals.pause();
				}
				openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
				//}
		
				#if desktop
				DiscordClient.changePresence(detailsPausedText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
			}
		}

		if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene && SONG.song.toLowerCase() != 'vexation-hell')
		{
			openChartEditor();
		}

		// FlxG.watch.addQuick('VOL', vocals.amplitudeLeft);
		// FlxG.watch.addQuick('VOLRight', vocals.amplitudeRight);

		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (150 * iconP2.scale.x) / 2 - iconOffset * 2;

		if (health > 2)
			health = 2;

		if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;

		if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene) {
			persistentUpdate = false;
			paused = true;
			cancelMusicFadeTween();
			MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
		}

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000 * playbackRate;
				if (Conductor.songPosition >= 0)
					startSong();
			}
		}
		else
		{
			Conductor.songPosition += FlxG.elapsed * 1000;

			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				// Interpolation type beat
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
					// Conductor.songPosition += FlxG.elapsed * 1000;
					// trace('MISSED FRAME');
				}

				if(updateTime) {
					var curTime:Float = Conductor.songPosition - ClientPrefs.noteOffset;
					if(curTime < 0) curTime = 0;
					songPercent = (curTime / songLength);

					var songCalc:Float = (songLength - curTime);
					if(ClientPrefs.timeBarType == 'Time Elapsed') songCalc = curTime;

					var secondsTotal:Int = Math.floor(songCalc / 1000);
					if(secondsTotal < 0) secondsTotal = 0;

					if(ClientPrefs.timeBarType != 'Song Name')
						timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
				}
			}

			// Conductor.lastSongPos = FlxG.sound.music.time;
		}

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * playbackRate), 0, 1));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * playbackRate), 0, 1));
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		// RESET = Quick Game Over Screen
		if (!ClientPrefs.noReset && controls.RESET && !inCutscene && !endingSong)
		{
			health = 0;
			trace("RESET = True");
		}
		doDeathCheck();

		if (unspawnNotes[0] != null)
		{
			var time:Float = 3000;//shitty is werid on 4:3
			if(songSpeed < 1) time /= songSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			var fakeCrochet:Float = (60 / SONG.bpm) * 1000;

			var off:Float = 0;
			if(Note.downScrollHoldEndOffset.exists(ClientPrefs.noteSkin))
			{
				off = Note.downScrollHoldEndOffset.get(ClientPrefs.noteSkin);
			}
			notes.forEachAlive(function(daNote:Note)
			{
				var strumGroup:FlxTypedGroup<StrumNote> = playerStrums;
				if(!daNote.mustPress) strumGroup = opponentStrums;

				var strumX:Float = strumGroup.members[daNote.noteData].x;
				var strumY:Float = strumGroup.members[daNote.noteData].y;
				var strumAngle:Float = strumGroup.members[daNote.noteData].angle;
				var strumDirection:Float = strumGroup.members[daNote.noteData].direction;
				var strumAlpha:Float = strumGroup.members[daNote.noteData].alpha;
				var strumScroll:Bool = strumGroup.members[daNote.noteData].downScroll;

				strumX += daNote.offsetX;
				strumY += daNote.offsetY;
				strumAngle += daNote.offsetAngle;
				strumAlpha *= daNote.multAlpha;

				if (strumScroll) //Downscroll
				{
					//daNote.y = (strumY + 0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
					daNote.distance = (0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
				}
				else //Upscroll
				{
					//daNote.y = (strumY - 0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
					daNote.distance = (-0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed);
				}

				var angleDir = strumDirection * Math.PI / 180;
				if (daNote.copyAngle)
					daNote.angle = strumDirection - 90 + strumAngle;

				if(daNote.copyAlpha)
					daNote.alpha = strumAlpha;
				
				if(daNote.copyX)
					daNote.x = strumX + Math.cos(angleDir) * daNote.distance;

				if(daNote.copyY)
				{
					daNote.y = strumY + Math.sin(angleDir) * daNote.distance;

					//Jesus christ this took me so much mother ducking time AAAAAAAAAA
					if(strumScroll && daNote.isSustainNote)
					{
						if (daNote.animation.curAnim.name.endsWith('end')) {
							daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * songSpeed + (46 * (songSpeed - 1));
							daNote.y -= 46 * (1 - (fakeCrochet / 600)) * songSpeed;
							if(PlayState.isPixelStage) {
								daNote.y += 8;
							} else {
								daNote.y -= 19;
								daNote.y += off;
							}
						} 
						daNote.y += (Note.swagWidth / 2) - (60.5 * (songSpeed - 1));
						daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (songSpeed - 1);
					}
				}

				if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote)
				{
					opponentNoteHit(daNote);
				}

				if(daNote.mustPress && cpuControlled) {
					if(daNote.isSustainNote) {
						if(daNote.canBeHit) {
							goodNoteHit(daNote);
						}
					} else if(daNote.strumTime <= Conductor.songPosition || (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress)) {
						goodNoteHit(daNote);
					}
				}
				
				var center:Float = strumY + Note.swagWidth / 2;
				if(strumGroup.members[daNote.noteData].sustainReduce && daNote.isSustainNote && (daNote.mustPress || !daNote.ignoreNote) &&
					(!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
				{
					if (strumScroll)
					{
						if(daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center)
						{
							var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
							swagRect.height = (center - daNote.y) / daNote.scale.y;
							swagRect.y = daNote.frameHeight - swagRect.height;

							daNote.clipRect = swagRect;
						}
					}
					else
					{
						if (daNote.y + daNote.offset.y * daNote.scale.y <= center)
						{
							var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
							swagRect.y = (center - daNote.y) / daNote.scale.y;
							swagRect.height -= swagRect.y;

							daNote.clipRect = swagRect;
						}
					}
				}

				// Kill extremely late notes and cause misses
				if (Conductor.songPosition > noteKillOffset + daNote.strumTime)
				{
					if (daNote.mustPress && !cpuControlled &&!daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)) {
						noteMiss(daNote);
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
		}
		checkEventNote();

		if (!inCutscene) {
			if(!cpuControlled) {
				keyShit();
			} else if(boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss')) {
				boyfriend.dance();
			}
		}
		
		if(ClientPrefs.developerMode) {
			if(!endingSong && !startingSong) {
				if (FlxG.keys.justPressed.ONE) { // End song
					KillNotes();
					FlxG.sound.music.onComplete();
				}
				if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
					setSongTime(Conductor.songPosition + 10000);
					clearNotesBefore(Conductor.songPosition);
				}
				if (FlxG.keys.justPressed.THREE) { // End song
					if(!cpuControlled && !botplayTxt.visible){
						cpuControlled = true;
						botplayTxt.visible = true;
					}
					else {
						cpuControlled = false;
						botplayTxt.visible = false;
					}
				}
				if (FlxG.keys.justPressed.FOUR) { // End song
					if(!practiceMode){
						practiceMode = true;
					}
					else {
						practiceMode = false;
					}
				}
			}
		}

		setOnLuas('cameraX', camFollowPos.x);
		setOnLuas('cameraY', camFollowPos.y);
		setOnLuas('botPlay', cpuControlled);
		
		for (shader in animatedShaders)
		{
			shader.update(elapsed);
		}
		#if LUA_ALLOWED
		
for (key => value in luaShaders)
{
	value.update(elapsed);
}
#end
		callOnLuas('onUpdatePost', [elapsed]);
		for (i in shaderUpdates){
			i(elapsed);
		}
	}

	function openChartEditor()
	{
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		MusicBeatState.switchState(new ChartingState());
		chartingMode = true;

		#if desktop
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !isDead)
		{
			var ret:Dynamic = callOnLuas('onGameOver', []);
			if(ret != FunkinLua.Function_Stop) {
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;

				vocals.stop();
				FlxG.sound.music.stop();

				persistentUpdate = false;
				persistentDraw = false;
				for (tween in modchartTweens) {
					tween.active = true;
				}
				for (timer in modchartTimers) {
					timer.active = true;
				}
				openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x - boyfriend.positionArray[0], boyfriend.getScreenPosition().y - boyfriend.positionArray[1], camFollowPos.x, camFollowPos.y));

				// MusicBeatState.switchState(new GameOverState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
				
				#if desktop
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.song + " (" + storyDifficultyText + ")", iconP2.getCharacter());
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var leStrumTime:Float = eventNotes[0].strumTime;
			if(Conductor.songPosition < leStrumTime) {
				break;
			}

			var value1:String = '';
			if(eventNotes[0].value1 != null)
				value1 = eventNotes[0].value1;

			var value2:String = '';
			if(eventNotes[0].value2 != null)
				value2 = eventNotes[0].value2;

			triggerEventNote(eventNotes[0].event, value1, value2);
			eventNotes.shift();
		}
	}

	public function getControl(key:String) {
		var pressed:Bool = Reflect.getProperty(controls, key);
		//trace('Control result: ' + pressed);
		return pressed;
	}

	function emitt() {
		particles.forEach(function(emitter:FlxEmitter) {
			if (!emitter.emitting)
				emitter.start(false, FlxG.random.float(0.1, 0.2), 100000);
			//trace('now it emits lol');
			emitter.visible = true;
		});
	}

	function stopEmitting() {
		particles.forEach(function(emitter:FlxEmitter) {
			emitter.visible = false;
		});
	}

	public function triggerEventNote(eventName:String, value1:String, value2:String) {
		switch(eventName) {
			// case 'Toggle Trail' :
				/*if ((value1 != null or value1 != '') && Std.parseInt(value1) > 0) {
					if (timerStartedDad) {
						new FlxTimer().start(trailDelay, function(tmr:FlxTimer) {
							createTrailFrame('Dad');
						}, 0);
						timerStartedDad = true;
					}
					trailEnabledDad = true;
					curTrailDad = 0;
				}
				else {
					trailEnabledDad = false;
				}
				
				if ((value2 != null or value2 != '') && Std.parseInt(value2) > 0){
					if (!timerStartedBF) {
						new FlxTimer().start(trailDelay, function(tmr:FlxTimer) {
							createTrailFrame('BF');
						}, 0);
						timerStartedBF = true;
					}
					trailEnabledBF = true;
					curTrailBF = 0;
				}
				else {
					trailEnabledBF = false;
				}*/
				// addTrail(value1, alpha, delay, ?color)
			case 'Cinematics' :
				var start:Null<Int> = Std.parseInt(value1);
				var finish:Null<Int> = Std.parseInt(value2);

				var cubeOut = FlxEase.cubeOut;

				if (start == 1) {	
					FlxTween.tween(upperBar, {y: upperBar.y + 60}, 0.5, {ease: cubeOut});
					FlxTween.tween(lowerBar, {y: lowerBar.y - 60}, 0.5, {ease: cubeOut});
					for (i in 0...strumLineNotes.length) {
						if (ClientPrefs.downScroll) {
							FlxTween.tween(strumLineNotes.members[i], {y: strumLineNotes.members[i].y - 35}, 0.5, {ease: cubeOut});
						}
						else {
							FlxTween.tween(strumLineNotes.members[i], {y: strumLineNotes.members[i].y + 35}, 0.5, {ease: cubeOut});
						}
					}
					FlxTween.tween(healthBarBurn, {alpha: 0}, 0.25);
					FlxTween.tween(healthBarBG, {alpha: 0}, 0.25);
					FlxTween.tween(timeBarBG, {alpha: 0}, 0.25);
					FlxTween.tween(healthBar, {alpha: 0}, 0.25);
					FlxTween.tween(scoreTxt, {alpha: 0}, 0.25);
					FlxTween.tween(timeBar, {alpha: 0}, 0.25);
					FlxTween.tween(timeTxt, {alpha: 0}, 0.25);
					FlxTween.tween(iconP1, {alpha: 0}, 0.25);
					FlxTween.tween(iconP2, {alpha: 0}, 0.25);
				}
				if (finish == 2) {	
					FlxTween.tween(upperBar, {y: upperBar.y - 60}, 0.5, {ease: cubeOut});
					FlxTween.tween(lowerBar, {y: lowerBar.y + 60}, 0.5, {ease: cubeOut});
					for (i in 0...strumLineNotes.length) {
						if (ClientPrefs.downScroll) {
							FlxTween.tween(strumLineNotes.members[i], {y: strumLineNotes.members[i].y + 35}, 0.5, {ease: cubeOut});
						}
						else {
							FlxTween.tween(strumLineNotes.members[i], {y: strumLineNotes.members[i].y - 35}, 0.5, {ease: cubeOut});
						}
					}
					FlxTween.tween(healthBarBurn, {alpha: 1}, 0.25);
					FlxTween.tween(healthBarBG, {alpha: 1}, 0.25);
					FlxTween.tween(timeBarBG, {alpha: 1}, 0.25);
					FlxTween.tween(healthBar, {alpha: 1}, 0.25);
					FlxTween.tween(scoreTxt, {alpha: 1}, 0.25);
					FlxTween.tween(timeBar, {alpha: 1}, 0.25);
					FlxTween.tween(timeTxt, {alpha: 1}, 0.25);
					FlxTween.tween(iconP1, {alpha: 1}, 0.25);
					FlxTween.tween(iconP2, {alpha: 1}, 0.25);
				}
			case 'Deprave Spotlight':
				var val1:Null<Int> = Std.parseInt(value1);
				var val2:Null<Int> = Std.parseInt(value2);
				if(val1 == null) val1 = 0;
				if(val2 == null) val2 = 0;
	
				switch(Std.parseInt(value1))
				{
					case 1, 2, 3: //enable and target dad
						if(val1 == 1) //enable
						{
							depraveBlack.visible = true;
							depraveLight.visible = true;
							depraveSmokes.visible = true;
							defaultCamZoom += 0.12;
						}
	
						var who:Character = dad;
						if(val1 > 2) who = boyfriend;
						//2 only targets dad
						depraveLight.alpha = 0;
						new FlxTimer().start(0.12, function(tmr:FlxTimer) {
							depraveLight.alpha = 0.375;
						});
						depraveLight.setPosition(who.getGraphicMidpoint().x - depraveLight.width / 2, who.y + who.height - depraveLight.height + 50);
						FlxG.camera.flash(FlxColor.WHITE, 1);
						ewBg.visible = true;
	
					default:
						depraveBlack.visible = false;
						depraveLight.visible = false;
						defaultCamZoom -= 0.12;
						FlxTween.tween(depraveSmokes, {alpha: 0}, 1, {onComplete: function(twn:FlxTween)
						{
							depraveSmokes.visible = false;
						}});
						FlxG.camera.flash(FlxColor.WHITE, 1);
						ewBg.visible = false;
				}
			case 'Trigger Vine Mechanic':
				grabBF();

			case 'Infernum Glow':
				var val1:Null<Int> = Std.parseInt(value1);
				var val2:Null<Int> = Std.parseInt(value2);

				if(val1 == null) val1 = 0;
				if(val2 == null) val2 = 0;

				if (val2 > 0){
					var color = FlxColor.fromRGB(255, 255, 255);
					switch(val2) {
						case 0: //White
							color = FlxColor.fromRGB(255, 255, 255);
						case 1: //Black
							color = FlxColor.fromRGB(0, 0, 0);
						case 2: //Red
							color = FlxColor.fromRGB(255, 0, 0);
						case 3: //Orange
							color = FlxColor.fromRGB(255,215,0);
						case 4: //Yellow
							color = FlxColor.fromRGB(255, 255, 0);
						case 5: //Green
							color = FlxColor.fromRGB(0, 255, 0);
						case 6: //Blue
							color = FlxColor.fromRGB(0, 255, 255);
						case 7: //Pink
							color = FlxColor.fromRGB(255, 192, 203);
						case 8: //Vex-Pink
							color = FlxColor.fromRGB(167, 3, 73);
					}
				}

				

				if (!ClientPrefs.lowQuality && particles != null) {
					switch(val1) {
						case 1:
							camEmitt = true;
							FlxTween.tween(fireEffect, {alpha: 1}, 2);
						case 0:
							camEmitt = false;
							stopEmitting();
							FlxTween.tween(fireEffect, {alpha: 0}, 2);
					}
					
				}
			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				var time:Float = Std.parseFloat(value2);
				if(Math.isNaN(time) || time <= 0) time = 0.6;

				if(value != 0) {
					if(dad.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					} else if (gf != null) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}

				}
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if(Math.isNaN(value)) value = 1;
				gfSpeed = value;

			case 'Set Property':
				var hi:Array<String> = value1.split('.');
				if(hi.length > 1) {
					FunkinLua.setVarInArray(FunkinLua.getPropertyLoopThingWhatever(hi, true, true), hi[hi.length-1], value2);
				} else {
					FunkinLua.setVarInArray(this, value1, value2);
				}

			case 'Flash' :
				/*var val1:Null<Int> = Std.parseInt(value1);
				var val2:Null<Int> = Std.parseInt(value2);
				if(val1 == null) val1 = 0;
				if(val2 == null) val2 = 1;
*/
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var r:Int = 0;
					var g:Int = 0;
					var b:Int = 0;
					if(split[0] != null) r = Std.parseInt(split[0].trim());
					if(split[1] != null) g = Std.parseInt(split[1].trim());
					if(split[2] != null) b = Std.parseInt(split[2].trim());
					if(Math.isNaN(r)) r = 0;
					if(Math.isNaN(g)) g = 0;
					if(Math.isNaN(b)) b = 0;

					if(r > 0 && g != 0 && b > 0) {
						targetsArray[i].flash(FlxColor.fromRGB(r, g, b));
					}
				}

				/*if(val1 > 0) {
					// if(value > 5) value = FlxG.random.int(1, 7, value);

					var color = FlxColor.fromRGB(255, 255, 255);
					switch(val1) {
						case 0: //White
							color = FlxColor.fromRGB(255, 255, 255);
						case 1: //Black
							color = FlxColor.fromRGB(0, 0, 0);
						case 2: //Red
							color = FlxColor.fromRGB(255, 0, 0);
						case 3: //Orange
							color = FlxColor.fromRGB(255,215,0);
						case 4: //Yellow
							color = FlxColor.fromRGB(255, 255, 0);
						case 5: //Green
							color = FlxColor.fromRGB(0, 255, 0);
						case 6: //Blue
							color = FlxColor.fromRGB(0, 255, 255);
						case 7: //Pink
							color = FlxColor.fromRGB(255, 192, 203);
					}
				}
				FlxG.camera.flash(val1, val2);*/
			case 'Blammed Lights':
				var lightId:Int = Std.parseInt(value1);
				if(Math.isNaN(lightId)) lightId = 0;

				if(lightId > 0 && curLightEvent != lightId) {
					if(lightId > 5) lightId = FlxG.random.int(1, 5, [curLightEvent]);

					var color:Int = 0xffffffff;
					switch(lightId) {
						case 1: //Blue
							color = 0xff31a2fd;
						case 2: //Green
							color = 0xff31fd8c;
						case 3: //Pink
							color = 0xfff794f7;
						case 4: //Red
							color = 0xfff96d63;
						case 5: //Orange
							color = 0xfffba633;
					}
					curLightEvent = lightId;

					if(blammedLightsBlack.alpha == 0) {
						if(blammedLightsBlackTween != null) {
							blammedLightsBlackTween.cancel();
						}
						blammedLightsBlackTween = FlxTween.tween(blammedLightsBlack, {alpha: 1}, 1, {ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween) {
								blammedLightsBlackTween = null;
							}
						});

						var chars:Array<Character> = [boyfriend, gf, dad];
						for (i in 0...chars.length) {
							if(chars[i].colorTween != null) {
								chars[i].colorTween.cancel();
							}
							chars[i].colorTween = FlxTween.color(chars[i], 1, FlxColor.WHITE, color, {onComplete: function(twn:FlxTween) {
								chars[i].colorTween = null;
							}, ease: FlxEase.quadInOut});
						}
					} else {
						if(blammedLightsBlackTween != null) {
							blammedLightsBlackTween.cancel();
						}
						blammedLightsBlackTween = null;
						blammedLightsBlack.alpha = 1;

						var chars:Array<Character> = [boyfriend, gf, dad];
						for (i in 0...chars.length) {
							if(chars[i].colorTween != null) {
								chars[i].colorTween.cancel();
							}
							chars[i].colorTween = null;
						}
						dad.color = color;
						boyfriend.color = color;
						gf.color = color;
					}
					
					if(curStage == 'philly') {
						if(phillyCityLightsEvent != null) {
							phillyCityLightsEvent.forEach(function(spr:BGSprite) {
								spr.visible = false;
							});
							phillyCityLightsEvent.members[lightId - 1].visible = true;
							phillyCityLightsEvent.members[lightId - 1].alpha = 1;
						}
					}

					if(curStage == 'CrazyVexationAlley') {
						fire.visible = false;
						matt.visible = false;
						crowd.visible = false;
					}
				} else {
					if(blammedLightsBlack.alpha != 0) {
						if(blammedLightsBlackTween != null) {
							blammedLightsBlackTween.cancel();
						}
						blammedLightsBlackTween = FlxTween.tween(blammedLightsBlack, {alpha: 0}, 1, {ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween) {
								blammedLightsBlackTween = null;
							}
						});
					}

					if(curStage == 'philly') {
						phillyCityLights.forEach(function(spr:BGSprite) {
							spr.visible = false;
						});
						phillyCityLightsEvent.forEach(function(spr:BGSprite) {
							spr.visible = false;
						});

						var memb:FlxSprite = phillyCityLightsEvent.members[curLightEvent - 1];
						if(memb != null) {
							memb.visible = true;
							memb.alpha = 1;
							if(phillyCityLightsEventTween != null)
								phillyCityLightsEventTween.cancel();

							phillyCityLightsEventTween = FlxTween.tween(memb, {alpha: 0}, 1, {onComplete: function(twn:FlxTween) {
								phillyCityLightsEventTween = null;
							}, ease: FlxEase.quadInOut});
						}
					}

					if(curStage == 'CrazyVexationAlley') {
						fire.visible = true;
						matt.visible = true;
						crowd.visible = true;
					}

					var chars:Array<Character> = [boyfriend, gf, dad];
					for (i in 0...chars.length) {
						if(chars[i].colorTween != null) {
							chars[i].colorTween.cancel();
						}
						chars[i].colorTween = FlxTween.color(chars[i], 1, chars[i].color, FlxColor.WHITE, {onComplete: function(twn:FlxTween) {
							chars[i].colorTween = null;
						}, ease: FlxEase.quadInOut});
					}

					curLight = 0;
					curLightEvent = 0;
				}

				
			case 'Add Camera Zoom':
				if(ClientPrefs.camZooms && FlxG.camera.zoom < 1.35) {
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if(Math.isNaN(camZoom)) camZoom = 0.015;
					if(Math.isNaN(hudZoom)) hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}

			case 'Play Animation':
				//trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch(value2.toLowerCase().trim()) {
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						var val2:Int = Std.parseInt(value2);
						if(Math.isNaN(val2)) val2 = 0;
		
						switch(val2) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}
				char.playAnim(value1, true);
				char.specialAnim = true;

			case 'Camera Follow Pos':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 0;
				if(Math.isNaN(val2)) val2 = 0;

				isCameraOnForcedPos = false;
				if(!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2))) {
					camFollow.x = val1;
					camFollow.y = val2;
					isCameraOnForcedPos = true;
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch(value1.toLowerCase()) {
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if(Math.isNaN(val)) val = 0;

						switch(val) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}
				char.idleSuffix = value2;
				char.recalculateDanceIdle();

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if(split[0] != null) duration = Std.parseFloat(split[0].trim());
					if(split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}

			case 'Change Character':
				var charType:Int = 0;
				switch(value1) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				switch(charType) {
					case 0:
						if(boyfriend.curCharacter != value2) {
							if(!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = 0.00001;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							iconP1.changeIcon(boyfriend.healthIcon);
						}
						setOnLuas('boyfriendName', boyfriend.curCharacter);

					case 1:
						if(dad.curCharacter != value2) {
							if(!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf');
							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad = dadMap.get(value2);
							if(!dad.curCharacter.startsWith('gf')) {
								if(wasGf && gf != null) {
									gf.visible = true;
								}
							} else if(gf != null) {
								gf.visible = false;
							}
							dad.alpha = lastAlpha;
							iconP2.changeIcon(dad.healthIcon);
						}
						setOnLuas('dadName', dad.curCharacter);

					case 2:
						if(gf != null) {
							if(gf.curCharacter != value2) {
								if(!gfMap.exists(value2)) {
									addCharacterToList(value2, charType);
								}

								var lastAlpha:Float = gf.alpha;
								gf.alpha = 0.00001;
								gf = gfMap.get(value2);
								gf.alpha = lastAlpha;
							}
							setOnLuas('gfName', gf.curCharacter);
						}
				}
				reloadHealthBarColors();
			
			case 'Change Scroll Speed':
				if (songSpeedType == "constant")
					return;
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 1;
				if(Math.isNaN(val2)) val2 = 0;

				var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;

				if(val2 <= 0)
				{
					songSpeed = newValue;
				}
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2 / playbackRate, {ease: FlxEase.linear, onComplete:
						function (twn:FlxTween)
						{
							songSpeedTween = null;
						}
					});
				}
		}
		callOnLuas('onEvent', [eventName, value1, value2]);
	}

	function moveCameraSection(?id:Int = 0):Void {
		if(SONG.notes[id] == null) return;

		if (gf != null && SONG.notes[id].gfSection)
		{
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];
			tweenCamIn();
			callOnLuas('onMoveCamera', ['gf']);
			setOnLuas('gfCamOffsetX', girlfriendCameraOffset[0]);
			setOnLuas('gfCamOffsetY', girlfriendCameraOffset[1]);
			return;
		}

		if (!SONG.notes[id].mustHitSection)
		{
			moveCamera(true);
			callOnLuas('onMoveCamera', ['dad']);
		}
		else
		{
			moveCamera(false);
			callOnLuas('onMoveCamera', ['boyfriend']);
		}
	}

	var cameraTwn:FlxTween;
	public function moveCamera(isDad:Bool)
	{
		if(isDad)
		{
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];
			setOnLuas('dadCamOffsetX', opponentCameraOffset[0]);
			setOnLuas('dadCamOffsetY', opponentCameraOffset[1]);
			
			tweenCamIn();
		}
		else
		{
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);

			switch (curStage)
			{
			}
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];

			setOnLuas('bfCamOffsetX', boyfriendCameraOffset[0]);
			setOnLuas('bfCamOffsetY', boyfriendCameraOffset[1]);

			if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
			{
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
					function (twn:FlxTween)
					{
						cameraTwn = null;
					}
				});
			}
		}
	}

	function tweenCamIn() {
		if (Paths.formatToSongPath(SONG.song) == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3) {
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut, onComplete:
				function (twn:FlxTween) {
					cameraTwn = null;
				}
			});
		}
	}

	function snapCamFollowToPos(x:Float, y:Float) {
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	function finishSong():Void
	{
		var finishCallback:Void->Void = function() //In case you want to change it in a specific song.
		{
	
			if (SONG.song.toLowerCase() == 'vexation') //unused deprave dialogue, didnt fit, but to sadboy
			{
				endingSong = true;
				canPause = false;
				vexationOutro();
			}
			else
				endSong();
		} 

		updateTime = false;
		FlxG.sound.music.volume = 0;
		vocals.volume = 0;
		vocals.pause();
		if(ClientPrefs.noteOffset <= 0) {
			finishCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer) {
				finishCallback();
			});
		}
	}

	/*function triggerModchart(modchart:Int) 
	{
		switch(modchart)
		{
			case 0:
				var twistLeft:Bool = true;
				if (twistLeft) {
                    for (i in 0...strumLineNotes.length){
						FlxTween.tween(strumLineNotes.members[i], {angle: 25}, 0.05, {ease: FlxEase.quadInOut});
					}
                    twistLeft = false;
            	}
				else if (twistLeft == false){
            
					for (i in 0...strumLineNotes.length){
						FlxTween.tween(strumLineNotes.members[i], {angle: -25}, 0.05, {ease: FlxEase.quadInOut});
					}
                    twistLeft = true;
				}
			case 1:
				var currentBeat:Float = (Conductor.songPosition / 1000)*(SONG.bpm/60);
				for (i in 0...strumLineNotes.length) {
					strumLineNotes.members[i].x = strumLineNotes.members[i].x + 32 * Math.sin((currentBeat + i*0.15) * Math.PI);
					strumLineNotes.members[i].y = strumLineNotes.members[i].y + 32 * Math.cos((currentBeat + i*0.15) * Math.PI);
				}
		}
	}*/

	public var transitioning = false;
	public function endSong():Void
	{
		//Should kill you if you tried to cheat
		if(!startingSong) {
			notes.forEach(function(daNote:Note) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			});
			for (daNote in unspawnNotes) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			}

			if(doDeathCheck()) {
				return;
			}
		}

                #if android
                androidc.visible = false;
                #end		
		timeBarBG.visible = false;
		timeBar.visible = false;
		timeTxt.visible = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;
		updateTime = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		if(achievementObj != null) {
			return;
		} else {
			var achieve:String = checkForAchievement();

			if(achieve != null) {
				startAchievement(achieve);
				return;
			}
		}
		#end

		
		#if LUA_ALLOWED
		var ret:Dynamic = callOnLuas('onEndSong', []);
		#else
		var ret:Dynamic = FunkinLua.Function_Continue;
		#end

		if(ret != FunkinLua.Function_Stop && !transitioning) {
			if (SONG.validScore)
			{
				#if !switch
				var percent:Float = ratingPercent;
				if(Math.isNaN(percent)) percent = 0;
				Highscore.saveScore(SONG.song, songScore, storyDifficulty, percent);
				#end
			}
			playbackRate = 1;

			if (chartingMode)
			{
				openChartEditor();
				return;
			}

			if (isStoryMode)
			{
				campaignScore += songScore;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					FlxG.sound.playMusic(Paths.music('freakyMenu'));

					cancelMusicFadeTween();
					if(FlxTransitionableState.skipNextTransIn) {
						CustomFadeTransition.nextCamera = null;
					}
					MusicBeatState.switchState(new StoryMenuState());

					// if ()
					if(!ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false)) {
						StoryMenuState.weekCompleted.set(WeekData.weeksList[storyWeek], true);

						if (SONG.validScore)
						{
							Highscore.saveWeekScore(WeekData.getWeekFileName(), campaignScore, storyDifficulty);
						}

						FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;
						FlxG.save.flush();
					}
					changedDifficulty = false;
				}
				else
				{
					var difficulty:String = CoolUtil.getDifficultyFilePath();

					trace('LOADING NEXT SONG');
					trace('Now Playing:' + Paths.formatToSongPath(PlayState.storyPlaylist[0]) + difficulty);

					var winterHorrorlandNext = (Paths.formatToSongPath(SONG.song) == "eggnog");
					if (winterHorrorlandNext)
					{
						var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
							-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
						blackShit.scrollFactor.set();
						add(blackShit);
						camHUD.visible = false;

						FlxG.sound.play(Paths.sound('Lights_Shut_off'));
					}

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					prevCamFollow = camFollow;
					prevCamFollowPos = camFollowPos;

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0] + difficulty, PlayState.storyPlaylist[0]);
					FlxG.sound.music.stop();

					if(winterHorrorlandNext) {
						new FlxTimer().start(1.5, function(tmr:FlxTimer) {
							cancelMusicFadeTween();
							LoadingState.loadAndSwitchState(new PlayState());
						});
					} else {
						cancelMusicFadeTween();
						LoadingState.loadAndSwitchState(new PlayState());
					}
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				cancelMusicFadeTween();
				if(FlxTransitionableState.skipNextTransIn) {
					CustomFadeTransition.nextCamera = null;
				}
				MusicBeatState.switchState(new FreeplayState());
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
				changedDifficulty = false;
			}
			transitioning = true;
		}
	}

	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementObject = null;
	function startAchievement(achieve:String) {
		achievementObj = new AchievementObject(achieve, camOther);
		achievementObj.onFinish = achievementEnd;
		add(achievementObj);
		trace('Giving achievement ' + achieve);
	}
	function achievementEnd():Void
	{
		achievementObj = null;
		if(endingSong && !inCutscene) {
			endSong();
		}
	}
	#end

	public function KillNotes() {
		while(notes.length > 0) {
			var daNote:Note = notes.members[0];
			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
		unspawnNotes = [];
		eventNotes = [];
	}

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0.0;
	private function popUpScore(note:Note = null):Void
	{
		var noteDiff:Float = Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset);
		//trace(noteDiff, ' ' + Math.abs(note.strumTime - Conductor.songPosition));

		// boyfriend.playAnim('hey');
		vocals.volume = 1;

		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.35;
		//

		var rating:FlxSprite = new FlxSprite();
		var score:Int = 350;

		//tryna do MS based judgment due to popular demand
		var daRating:String = Conductor.judgeNote(note, noteDiff / playbackRate);

		switch (daRating)
		{
			case "shit": // shit
				totalNotesHit += 0;
				score = 50;
				shits++;
			case "bad": // bad
				totalNotesHit += 0.5;
				score = 100;
				bads++;
			case "good": // good
				totalNotesHit += 0.75;
				score = 200;
				goods++;
			case "sick": // sick
				totalNotesHit += 1;
				sicks++;
		}


		if(daRating == 'sick' && !note.noteSplashDisabled)
		{
			spawnNoteSplashOnNote(note);
		}

		if(!practiceMode && !cpuControlled) {
			songScore += score;
			songHits++;
			totalPlayed++;
			RecalculateRating();

			if(ClientPrefs.scoreZoom)
			{
				if(scoreTxtTween != null) {
					scoreTxtTween.cancel();
				}
				scoreTxt.scale.x = 1.075;
				scoreTxt.scale.y = 1.075;
				scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
					onComplete: function(twn:FlxTween) {
						scoreTxtTween = null;
					}
				});
			}
		}

		/* if (combo > 60)
				daRating = 'sick';
			else if (combo > 12)
				daRating = 'good'
			else if (combo > 4)
				daRating = 'bad';
		 */

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';

		if (PlayState.isPixelStage)
		{
			pixelShitPart1 = 'pixelUI/';
			pixelShitPart2 = '-pixel';
		}

		rating.loadGraphic(Paths.image(pixelShitPart1 + daRating + pixelShitPart2));
		rating.cameras = [camHUD];
		rating.screenCenter();
		rating.x = coolText.x - 40;
		rating.y -= 60;
		rating.acceleration.y = 550 * playbackRate * playbackRate;
		rating.velocity.y -= FlxG.random.int(140, 175) * playbackRate;
		rating.velocity.x -= FlxG.random.int(0, 10) * playbackRate;
		rating.visible = !ClientPrefs.hideHud;
		rating.x += ClientPrefs.comboOffset[0];
		rating.y -= ClientPrefs.comboOffset[1];


		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'combo' + pixelShitPart2));
		comboSpr.cameras = [camHUD];
		comboSpr.screenCenter();
		comboSpr.x = coolText.x;
		comboSpr.acceleration.y = 600 * playbackRate * playbackRate;
		comboSpr.velocity.y -= 150 * playbackRate;
		comboSpr.visible = !ClientPrefs.hideHud;
		comboSpr.x += ClientPrefs.comboOffset[0];
		comboSpr.y -= ClientPrefs.comboOffset[1];


		comboSpr.velocity.x += FlxG.random.int(1, 10);
		insert(members.indexOf(strumLineNotes), rating);

		if (!PlayState.isPixelStage)
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = ClientPrefs.globalAntialiasing;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = ClientPrefs.globalAntialiasing;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * daPixelZoom * 0.85));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * daPixelZoom * 0.85));
		}

		comboSpr.updateHitbox();
		rating.updateHitbox();

		var seperatedScore:Array<Int> = [];

		if(combo >= 1000) {
			seperatedScore.push(Math.floor(combo / 1000) % 10);
		}
		seperatedScore.push(Math.floor(combo / 100) % 10);
		seperatedScore.push(Math.floor(combo / 10) % 10);
		seperatedScore.push(combo % 10);

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2));
			numScore.cameras = [camHUD];
			numScore.screenCenter();
			numScore.x = coolText.x + (43 * daLoop) - 90;
			numScore.y += 80;

			numScore.x += ClientPrefs.comboOffset[2];
			numScore.y -= ClientPrefs.comboOffset[3];

			if (!PlayState.isPixelStage)
			{
				numScore.antialiasing = ClientPrefs.globalAntialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			numScore.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			numScore.velocity.x = FlxG.random.float(-5, 5) * playbackRate;
			numScore.visible = !ClientPrefs.hideHud;

			//if (combo >= 10 || combo == 0)
				insert(members.indexOf(strumLineNotes), numScore);

			FlxTween.tween(numScore, {alpha: 0}, 0.2  / playbackRate, {
				onComplete: function(tween:FlxTween)
				{
					numScore.destroy();
				},
				startDelay: Conductor.crochet * 0.002 / playbackRate
			});

			daLoop++;
		}
		/* 
			trace(combo);
			trace(seperatedScore);
		 */

		coolText.text = Std.string(seperatedScore);
		// add(coolText);

		FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate, {
			startDelay: Conductor.crochet * 0.001 / playbackRate
		});

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate, {
			onComplete: function(tween:FlxTween)
			{
				coolText.destroy();
				comboSpr.destroy();

				rating.destroy();
			},
			startDelay: Conductor.crochet * 0.001 / playbackRate
		});
	}

	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		//trace('Pressed: ' + eventKey);

		if (!cpuControlled && !paused && key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || ClientPrefs.controllerMode))
		{
			if(!boyfriend.stunned && generatedMusic && !endingSong)
			{
				//more accurate hit time for the ratings?
				var lastTime:Float = Conductor.songPosition;
				Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !ClientPrefs.ghostTapping;

				// heavily based on my own code LOL if it aint broke dont fix it
				var pressNotes:Array<Note> = [];
				//var notesDatas:Array<Int> = [];
				var notesStopped:Bool = false;

				var sortedNotesList:Array<Note> = [];
				notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote)
					{
						if(daNote.noteData == key)
						{
							sortedNotesList.push(daNote);
							//notesDatas.push(daNote.noteData);
						}
						canMiss = true;
					}
				});
				sortedNotesList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

				if (sortedNotesList.length > 0) {
					for (epicNote in sortedNotesList)
					{
						for (doubleNote in pressNotes) {
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1) {
								doubleNote.kill();
								notes.remove(doubleNote, true);
								doubleNote.destroy();
							} else
								notesStopped = true;
						}
							
						// eee jack detection before was not super good
						if (!notesStopped) {
							goodNoteHit(epicNote);
							pressNotes.push(epicNote);
						}

					}
				}
				else if (canMiss) {
					noteMissPress(key);
					callOnLuas('noteMissPress', [key]);
				}

				// I dunno what you need this for but here you go
				//									- Shubs

				// Shubs, this is for the "Just the Two of Us" achievement lol
				//									- Shadow Mario
				keysPressed[key] = true;

				//more accurate hit time for the ratings? part 2 (Now that the calculations are done, go back to the time it was before for not causing a note stutter)
				Conductor.songPosition = lastTime;
			}

			var spr:StrumNote = playerStrums.members[key];
			if(spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
			callOnLuas('onKeyPress', [key]);
		}
		//trace('pressed: ' + controlArray);
	}
	
	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if(!cpuControlled && !paused && key > -1)
		{
			var spr:StrumNote = playerStrums.members[key];
			if(spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
			callOnLuas('onKeyRelease', [key]);
		}
		//trace('released: ' + controlArray);
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if(key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if(key == keysArray[i][j])
					{
						return i;
					}
				}
			}
		}
		return -1;
	}

	// Hold notes
	private function keyShit():Void
	{
		// HOLDING
		var up = controls.NOTE_UP;
		var right = controls.NOTE_RIGHT;
		var down = controls.NOTE_DOWN;
		var left = controls.NOTE_LEFT;
		var controlHoldArray:Array<Bool> = [left, down, up, right];
		
		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(ClientPrefs.controllerMode)
		{
			var controlArray:Array<Bool> = [controls.NOTE_LEFT_P, controls.NOTE_DOWN_P, controls.NOTE_UP_P, controls.NOTE_RIGHT_P];
			if(controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if(controlArray[i])
						onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
				}
			}
		}

		// FlxG.watch.addQuick('asdfa', upP);
		if (!boyfriend.stunned && generatedMusic)
		{
			// rewritten inputs???
			notes.forEachAlive(function(daNote:Note)
			{
				// hold note functions
				if (daNote.isSustainNote && controlHoldArray[daNote.noteData] && daNote.canBeHit 
				&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit) {
					goodNoteHit(daNote);
				}
			});

			if (controlHoldArray.contains(true) && !endingSong) {
				#if ACHIEVEMENTS_ALLOWED
				var achieve:String = checkForAchievement(['oversinging']);
				if (achieve != null) {
					startAchievement(achieve);
				}
				#end
			} else if (boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing')
			&& !boyfriend.animation.curAnim.name.endsWith('miss'))
				boyfriend.dance();
		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if(ClientPrefs.controllerMode)
		{
			var controlArray:Array<Bool> = [controls.NOTE_LEFT_R, controls.NOTE_DOWN_R, controls.NOTE_UP_R, controls.NOTE_RIGHT_R];
			if(controlArray.contains(true))
			{
				for (i in 0...controlArray.length)
				{
					if(controlArray[i])
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
				}
			}
		}
	}

	function noteMiss(daNote:Note):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		notes.forEachAlive(function(note:Note) {
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 1) {
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});
		combo = 0;

		health -= daNote.missHealth * healthLoss;
		if(instakillOnMiss)
		{
			vocals.volume = 0;
			doDeathCheck(true);
		}

		//For testing purposes
		//trace(daNote.missHealth);
		songMisses++;
		vocals.volume = 0;
		if(!practiceMode) songScore -= 10;
		
		totalPlayed++;
		RecalculateRating();

		var char:Character = boyfriend;
		if(daNote.gfNote) {
			char = gf;
		}

		if(char.hasMissAnimations)
		{
			var daAlt = '';
			if(daNote.noteType == 'Alt Animation') daAlt = '-alt';

			var animToPlay:String = singAnimations[Std.int(Math.abs(daNote.noteData))] + 'miss' + daAlt;
			char.playAnim(animToPlay, true);
		}

		callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
	}

	function noteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		if (!boyfriend.stunned)
		{
			health -= 0.05 * healthLoss;
			if(instakillOnMiss)
			{
				vocals.volume = 0;
				doDeathCheck(true);
			}

			if(ClientPrefs.ghostTapping) return;

			if (combo > 5 && gf != null && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
			}
			combo = 0;

			if(!practiceMode) songScore -= 10;
			if(!endingSong) {
				songMisses++;
			}
			totalPlayed++;
			RecalculateRating();

			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			// FlxG.sound.play(Paths.sound('missnote1'), 1, false);
			// FlxG.log.add('played imss note');

			/*boyfriend.stunned = true;

			// get stunned for 1/60 of a second, makes you able to
			new FlxTimer().start(1 / 60, function(tmr:FlxTimer)
			{
				boyfriend.stunned = false;
			});*/

			if(boyfriend.hasMissAnimations) {
				boyfriend.playAnim(singAnimations[Std.int(Math.abs(direction))] + 'miss', true);
			}
			vocals.volume = 0;
		}
	}

	function opponentNoteHit(note:Note):Void
	{
		if (Paths.formatToSongPath(SONG.song) != 'tutorial')
			camZooming = true;

		if(note.noteType == 'Hey!' && dad.animOffsets.exists('hey')) {
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
		} else if(!note.noAnimation) {
			var altAnim:String = "";

			var curSection:Int = Math.floor(curStep / 16);
			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].altAnim || note.noteType == 'Alt Animation') {
					altAnim = '-alt';
				}
			}

			var char:Character = dad;
			var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))] + altAnim;
			if(note.gfNote) {
				char = gf;
			}

			char.playAnim(animToPlay, true);
			char.holdTimer = 0;
		}

		if(dad.curCharacter.startsWith('WhittyCrazyV') || dad.curCharacter.startsWith('WhittyCrazyCorrupt')){ //<-- when any character starts with this, no matter what also i removed it on infernum bc healthdrain mechanic is enough
			FlxG.camera.shake(0.005, 0.28);
			health = health - 0.0015;
		}

		if(note.noteType == 'Hurt Note') {//<-- 2.5 whitty on pressure is crazy too but he hits hurt notes
			FlxG.camera.shake(0.009, 0.4);
			health = health - 0.005;
		}

		if (SONG.needsVoices)
			vocals.volume = 1;

		var time:Float = 0.15;
		if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
			time += 0.15;
		}
		StrumPlayAnim(true, Std.int(Math.abs(note.noteData)) % 4, time);
		note.hitByOpponent = true;

		callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote]);

		if (!note.isSustainNote)
		{
			note.kill();
			notes.remove(note, true);
			note.destroy();
		}
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled)
			{
				FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.hitsoundVolume);
			}

			if(cpuControlled && (note.ignoreNote || note.hitCausesMiss)) return;

			if(note.hitCausesMiss) {
				noteMiss(note);
				if(!note.noteSplashDisabled && !note.isSustainNote) {
					spawnNoteSplashOnNote(note);
				}

				switch(note.noteType) {
					case 'Hurt Note': //Hurt note
						if(boyfriend.animation.getByName('hurt') != null) {
							boyfriend.playAnim('hurt', true);
							boyfriend.specialAnim = true;
						}
				}
				
				note.wasGoodHit = true;
				if (!note.isSustainNote)
				{
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}
				return;
			}

			if (!note.isSustainNote)
			{
				combo += 1;
				popUpScore(note);
				if(combo > 9999) combo = 9999;
			}
			health += note.hitHealth * healthGain;

			if(!note.noAnimation) {
				var daAlt = '';
				if(note.noteType == 'Alt Animation') daAlt = '-alt';
	
				var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))];

					if(note.gfNote) 
					{
						if(gf != null)
						{
							gf.playAnim(animToPlay + daAlt, true);
							gf.holdTimer = 0;
						}
					} else {
						boyfriend.playAnim(animToPlay + daAlt, true);
						boyfriend.holdTimer = 0;
					}

				if(note.noteType == 'Hey!') {
					if(boyfriend.animOffsets.exists('hey')) {
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = 0.6;
					}
	
					if(gf != null && gf.animOffsets.exists('cheer')) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = 0.6;
					}
				}
			}

			if(cpuControlled) {
				var time:Float = 0.15;
				if(note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
					time += 0.15;
				}
				StrumPlayAnim(false, Std.int(Math.abs(note.noteData)) % 4, time);
			} else {
				playerStrums.forEach(function(spr:StrumNote)
				{
					if (Math.abs(note.noteData) == spr.ID)
					{
						spr.playAnim('confirm', true);
					}
				});
			}
			note.wasGoodHit = true;
			vocals.volume = 1;

			var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
			var leData:Int = Math.round(Math.abs(note.noteData));
			var leType:String = note.noteType;
			callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	function spawnNoteSplashOnNote(note:Note) {
		if(ClientPrefs.noteSplashes && note != null) {
			var strum:StrumNote = playerStrums.members[note.noteData];
			if(strum != null) {
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null) {
		var skin:String = 'noteSplashes';
		if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;
		
		var hue:Float = ClientPrefs.arrowHSV[data % 4][0] / 360;
		var sat:Float = ClientPrefs.arrowHSV[data % 4][1] / 100;
		var brt:Float = ClientPrefs.arrowHSV[data % 4][2] / 100;
		if(note != null) {
			skin = note.noteSplashTexture;
			hue = note.noteSplashHue;
			sat = note.noteSplashSat;
			brt = note.noteSplashBrt;
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin, hue, sat, brt);
		grpNoteSplashes.add(splash);
	}

	function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2, 'whitty'));
		// FlxG.sound.play(Paths.sound('thunder_1','whitty'));

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if(boyfriend.animOffsets.exists('scared')) {
			boyfriend.playAnim('scared', true);
		}
		if(gf != null && gf.animOffsets.exists('scared')) {
			gf.playAnim('scared', true);
		}

		if(ClientPrefs.camZooms) {
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;

			if(!camZooming) { //Just a way for preventing it to be permanently zoomed until Skid & Pump hits a note
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.5);
				FlxTween.tween(camHUD, {zoom: 1}, 0.5);
			}
			
		}
		FlxG.camera.shake(0.02, 0.2);

		if(ClientPrefs.flashing) {
			halloweenWhite.alpha = 0.4;
			FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075);
			FlxTween.tween(halloweenWhite, {alpha: 0}, 0.25, {startDelay: 0.15});
		}
	}

	private var preventLuaRemove:Bool = false;
	override function destroy() {
		preventLuaRemove = true;
		for (i in 0...luaArray.length) {
			luaArray[i].call('onDestroy', []);
			luaArray[i].stop();
		}
		luaArray = [];

		if(!ClientPrefs.controllerMode)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		FlxAnimationController.globalSpeed = 1;
		FlxG.sound.music.pitch = 1;
		super.destroy();
	}

	public static function cancelMusicFadeTween() {
		if(FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	public function removeLua(lua:FunkinLua) {
		if(luaArray != null && !preventLuaRemove) {
			luaArray.remove(lua);
		}
	}

	function BFZoom(zoom:Float, ?time:Int, ?sa:Float) {
		if(FlxG.camera.zoom != 1.4 || defaultCamZoom != 1.4) {
			defaultCamZoom = defaultCamZoom + zoom;
			FlxTween.tween(staticc, {alpha: sa}, time);
		}
		else
		{
			return;
		}
	}

	var jumpscare:FlxSprite;

	function addjumpscarebcimlazy(name:String = '0') {
		jumpscare = new FlxSprite().loadGraphic(Paths.image('shitty/' + name));
		add(jumpscare);
        jumpscare.cameras = [camHUD];
		jumpscare.alpha = 0;
		new FlxTimer().start(0.05, function(tmr:FlxTimer) {
			jumpscare.alpha = 1;
			camHUD.shake(0.05, 1);
			FlxG.sound.play(Paths.sound('vineboom'), 1);
			new FlxTimer().start(0.4, function(tmr:FlxTimer) {
				FlxTween.tween(jumpscare, {alpha:0}, 0.9, {ease: FlxEase.sineOut,
				onComplete: function(twn:FlxTween) {
					remove(jumpscare);
				}});
			});
		});
	}

	function jumpscaer() {
		switch (FlxG.random.int(0, 11)) //You can change it with any number if there are more
		{
			case 0:
				addjumpscarebcimlazy('0');
			case 1:
				addjumpscarebcimlazy('1');
			case 2:
				addjumpscarebcimlazy('2');
			case 3:
				addjumpscarebcimlazy('3');
			case 4:
				addjumpscarebcimlazy('4');
			case 5:
				addjumpscarebcimlazy('5');
			case 6:
				addjumpscarebcimlazy('6');
			case 7:
				addjumpscarebcimlazy('7');
			case 8:
				addjumpscarebcimlazy('8');
			case 9:
				addjumpscarebcimlazy('9');
			case 10:
				addjumpscarebcimlazy('10');
			case 11:
				addjumpscarebcimlazy('11');
		}
	}

	function setVoiceLine(voiceLineVal:String, duration:Float) {
		voiceLineVal = voicelineValue;
		FlxTween.tween(voiceLine, {alpha: 1}, 0.5);
		new FlxTimer().start(duration, function(tmr:FlxTimer)
		{
			FlxTween.tween(voiceLine, {alpha: 0}, 0.5);
		});
	}

	var lastStepHit:Int = -1;
	override function stepHit()
	{
		super.stepHit();
		if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)
			|| (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)))
		{
			resyncVocals();
		}

		if (curSong.toLowerCase() == 'vexation' || curSong.toLowerCase() == 'vexation-hell') {
			if(curStep == 1){
				grabBF();
			}
		}

		if(SONG.song.toLowerCase() == 'shitmore') {
			if(curStep == 120)
				jumpscaer();
		}

		if (curSong.toLowerCase() == 'deprave') {
			if(curStep == 120)
			{
				camGame.visible = false;
				camHUD.visible = false;
			}
			if(curStep == 128)
			{
				camGame.visible = true;
				camHUD.visible = true;
				FlxG.camera.flash(FlxColor.WHITE, 1);
			}
			if(curStep == 240) {
				// BFZoom(0.5, 1, 0.5);
			}
			if(curStep == 256) {
				// BFZoom(-0.5, 1, 0);
			}
		}

		if(curSong.toLowerCase() == 'pressure') {
			switch(curStep) {
				case 1273:
					FlxG.sound.play(Paths.sound('fire'));
					FlxG.sound.play(Paths.sound('micCrack'));
				case 1664:
					BFZoom(0.5, 1, 0.5);
				case 1692:
					FlxG.camera.flash(FlxColor.WHITE, 1);
				case 1693:
					camGame.visible = false;
					camHUD.visible = false;
			}
		}

		if (curSong.toLowerCase() == 'infernum') {

			switch(curStep) {
				case 544 | 929 | 2080 | 2352 | 2416 | 2672:
					FlxG.camera.flash(FlxColor.WHITE, 1);
			}
			switch(curStep) {
				case 544:
					block.visible = false;
				case 672:
        			BFZoom(0, 1, 0.5);
				case 736:
        			BFZoom(0.5, 1, 0.5);
    			case 800 :
        			BFZoom(-0.5, 1, 0);
    			case 1184 :
    			    BFZoom(0.5, 1, 0.5);
    			case 1312 :
   				    BFZoom(-0.5, 1, 0);
    			case 2096 :
					FlxTween.tween(camHUD, {alpha: 0}, 1);
    			case 2336 :
        			block.visible = true;
					matt.visible = true;
					victim.visible = true;
					victim2.visible = true;
					victim3.visible = true;
					nwBg2.alpha = 1;
					remove(nwBg);
					add(crack);
        			crack.animation.play('idle');
					FlxG.sound.play(Paths.sound('souljaboyCrank'), 0.7);
					FlxG.camera.shake(0.05, 1);
					nwBg2.animation.play("gameButMove");
    			case 2352 :
        			remove(crack);
					block.visible = false;
        			// remove(block);
				case 2400:
					FlxTween.tween(camHUD, {alpha: 1}, 1);
				case 2544:
					FlxTween.tween(FlxG.camera, {zoom: 1.7}, 7.98, {ease: FlxEase.expoIn});
				case 2658 | 2662 | 2665 | 2667 | 2669 |  2671:
					block.visible = true;
					camHUD.visible = false;
				case 2656 | 2660 | 2664 | 2666 | 2668 |  2670 | 2672:
					block.visible = false;
					camHUD.visible = true;
    			case 2928:
        			BFZoom(0.5, 1, 0.5);
    			case 3056:
        			BFZoom(-0.5, 1, 0);
				case 3440:
					gf.visible = false;
					defeatBg(true);
				case 3696:
					block.visible = true;
					camHUD.visible = false;
					defeatBg(false);
					gf.visible = true;
				case 3760:
					block.visible = false;
					camHUD.visible = true;
				case 4272:
					FlxTween.tween(camHUD, {alpha: 0}, 4.66);
					FlxG.camera.flash(FlxColor.WHITE, 10);
					whait.visible = true;
			}
		}

		if (curSong.toLowerCase() == 'infernum-hell') {

			switch(curStep) {
				case 544 | 929 | 2080 | 2336 | 2400 | 2656:
					FlxG.camera.flash(FlxColor.WHITE, 1);
			}
			switch(curStep) {
				case 544:
					block.visible = false;
				case 672:
        			BFZoom(0.5, 1, 0.5);
    			case 800 :
        			BFZoom(-0.5, 1, 0);
    			case 1184 :
    			    BFZoom(0.5, 1, 0.5);
    			case 1312 :
   				    BFZoom(-0.5, 1, 0);
    			case 2096 :
					FlxTween.tween(camHUD, {alpha: 0}, 1);
    			case 2336 :
					matt.visible = true;
					victim.visible = true;
					victim2.visible = true;
					victim3.visible = true;
					nwBg2.alpha = 1;
					remove(nwBg);
					FlxG.camera.shake(0.05, 1);
					nwBg2.animation.play("gameButMove");
				case 2384:
					FlxTween.tween(camHUD, {alpha: 1}, 1);
				case 2528:
					FlxTween.tween(FlxG.camera, {zoom: 1.7}, 7.98, {ease: FlxEase.expoIn});
    			case 2912:
        			BFZoom(0.5, 1, 0.5);
    			case 3040:
        			BFZoom(-0.5, 1, 0);
				case 3424:
					gf.visible = false;
					defeatBg(true);
				case 3680:
					defeatBg(false);
				case 4192:
					FlxTween.tween(camHUD, {alpha: 0}, 4.66);
					FlxG.camera.flash(FlxColor.WHITE, 10);
					whait.visible = true;
			}
		}

		if(curSong.toLowerCase() == 'infernum-bside') {
			switch(curStep) {
				case 2351 | 4272:
					remove(evilTrail);
					new FlxTimer().start(0.1, function(tmr:FlxTimer)
					{
						evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069); //nice (infernum-bside)
						evilTrail.color = FlxColor.fromRGB(76, 235, 255);
						addBehindDad(evilTrail); 
					});
			}
		}

		if (curSong.toLowerCase() == 'vexation') {

			switch(curStep) {
				case 128 | 384 | 896 | 1296 | 1329 | 1360 | 1472 | 1727 | 1791 | 1984 | 2528 | 5568 | 3040 | 3168 | 3807:
					FlxG.camera.flash(FlxColor.WHITE, 1);
				case 640 |1152 | 3551:
					BFZoom(0.5, 1, 0.5);
				case 768 | 1280 | 3679:	
					BFZoom(-0.5, 1, 0);
			}
			switch(curStep) {
				case 128:
					camHUD.visible = true;
    			case 1984 :
    			    nwBg2.alpha = 1;
					nwBg.visible = false;
					nwBg2.animation.play("gameButMove");
					remove(evilTrail);
					remove(moreevilTrail);
					new FlxTimer().start(0.1, function(tmr:FlxTimer)
					{
						evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069); //nice (vexation)
						addBehindDad(evilTrail); 
						moreevilTrail = new FlxTrail(boyfriend, null, 4, 24, 0.3, 0.069); //nice (vexation)
						addBehindBF(moreevilTrail); 
					});
					fire.visible = false;
					matt.visible = false;
					crowd.visible = false;
					gf.visible = false;
				case 2488:
					nwBg2.animation.play('game');
					camHUD.alpha -= 0.1;
					FlxG.sound.play(Paths.sound('souljaboyCrank'), 0.7);
					nwBg2.animation.play("game");
					dad.visible = false;
					whittay.alpha = 1;
					evilTrail.visible = false;
					whittay.animation.play("whittay");
    			case 2528 :
					nwBg2.alpha = 0;
					nwBg.visible = true;
					camHUD.alpha = 1;
					fire.visible = true;
					matt.visible = true;
					crowd.visible = true;
					gf.visible = true;
					dad.visible = true;
					remove(whittay);
					remove(evilTrail);
					remove(moreevilTrail);
					new FlxTimer().start(0.1, function(tmr:FlxTimer)
					{
						evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069); //nice (vexation)
						addBehindDad(evilTrail); 
						moreevilTrail = new FlxTrail(boyfriend, null, 4, 24, 0.3, 0.069); //nice (vexation)
						addBehindBF(moreevilTrail); 
					});
				case 2783:
					remove(evilTrail);
					remove(moreevilTrail);
					new FlxTimer().start(0.2, function(tmr:FlxTimer)
					{
						evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069); //nice (vexation)
						addBehindDad(evilTrail); 
						moreevilTrail = new FlxTrail(boyfriend, null, 4, 24, 0.3, 0.069); //nice (vexation)
						addBehindBF(moreevilTrail); 
					});
				case 3163:
					remove(evilTrail);
					new FlxTimer().start(0.1, function(tmr:FlxTimer)
					{
						evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069); //nice (vexation)
						addBehindDad(evilTrail); 
					});
    			case 3802 :
					FlxTween.tween(camHUD, {alpha: 0}, 1);
    			case 3840 :
					block = new FlxSprite(-400).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(block);
					block.visible = true;
			}
		}

		if(curSong.toLowerCase() == 'vexation-hell') {
			switch(curStep) {
				case 128 | 384 | 896 | 1472 | 1727 | 1791 | 1984 | 2528 | 5568 | 3040 | 3168 | 3680:
					FlxG.camera.flash(FlxColor.WHITE, 1);
				case 640 |1152 | 3424:
					BFZoom(0.5, 1, 0.5);
				case 768 | 1280 | 3552:	
					BFZoom(-0.5, 1, 0);
			}
			switch(curStep) {
				case 128:
					camHUD.visible = true;
    			case 1984 :
    			    nwBg2.alpha = 1;
					nwBg.visible = false;
					nwBg2.animation.play("gameButMove");
					remove(evilTrail);
					remove(moreevilTrail);
					new FlxTimer().start(0.1, function(tmr:FlxTimer)
					{
						evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069); //nice (vexation)
						addBehindDad(evilTrail); 
						moreevilTrail = new FlxTrail(boyfriend, null, 4, 24, 0.3, 0.069); //nice (vexation)
						addBehindBF(moreevilTrail); 
					});
					fire.visible = false;
					matt.visible = false;
					crowd.visible = false;
					gf.visible = false;
				case 2488:
					nwBg2.animation.play('game');
					camHUD.alpha -= 0.1;
					FlxG.sound.play(Paths.sound('souljaboyCrank'), 0.7);
					nwBg2.animation.play("game");
					dad.visible = false;
					whittay.alpha = 1;
					evilTrail.visible = false;
					whittay.animation.play("whittay");
    			case 2528 :
					nwBg2.alpha = 0;
					nwBg.visible = true;
					camHUD.alpha = 1;
					fire.visible = true;
					matt.visible = true;
					crowd.visible = true;
					gf.visible = true;
					dad.visible = true;
					remove(whittay);
					remove(evilTrail);
					remove(moreevilTrail);
					new FlxTimer().start(0.1, function(tmr:FlxTimer)
					{
						evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069); //nice (vexation)
						addBehindDad(evilTrail); 
						moreevilTrail = new FlxTrail(boyfriend, null, 4, 24, 0.3, 0.069); //nice (vexation)
						addBehindBF(moreevilTrail); 
					});
				case 2783:
					remove(evilTrail);
					remove(moreevilTrail);
					new FlxTimer().start(0.2, function(tmr:FlxTimer)
					{
						evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069); //nice (vexation)
						addBehindDad(evilTrail); 
						moreevilTrail = new FlxTrail(boyfriend, null, 4, 24, 0.3, 0.069); //nice (vexation)
						addBehindBF(moreevilTrail); 
					});
				case 3163:
					remove(evilTrail);
					new FlxTimer().start(0.1, function(tmr:FlxTimer)
					{
						evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069); //nice (vexation)
						addBehindDad(evilTrail); 
					});
    			case 3802 :
					FlxTween.tween(camHUD, {alpha: 0}, 1);
    			case 3840:
					block = new FlxSprite(-400).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(block);
					block.visible = true;
			}
		}

		if(curStep == lastStepHit) {
			return;
		}

		lastStepHit = curStep;
		setOnLuas('curStep', curStep);
		callOnLuas('onStepHit', []);
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	var lastBeatHit:Int = -1;
	
	
	
	
	override function beatHit()
	{
		super.beatHit();

		if(lastBeatHit >= curBeat) {
			//trace('BEAT HIT: ' + curBeat + ', LAST HIT: ' + lastBeatHit);
			return;
		}

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, ClientPrefs.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		if (SONG.notes[Math.floor(curStep / 16)] != null)
		{
			if (SONG.notes[Math.floor(curStep / 16)].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[Math.floor(curStep / 16)].bpm);
				//FlxG.log.add('CHANGED BPM!');
				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
			}
			setOnLuas('mustHitSection', SONG.notes[Math.floor(curStep / 16)].mustHitSection);
			setOnLuas('altAnim', SONG.notes[Math.floor(curStep / 16)].altAnim);
			setOnLuas('gfSection', SONG.notes[Math.floor(curStep / 16)].gfSection);
			// else
			// Conductor.changeBPM(SONG.bpm);
		}
		// FlxG.log.add('change bpm' + SONG.notes[Std.int(curStep / 16)].changeBPM);

		if (generatedMusic && PlayState.SONG.notes[Std.int(curStep / 16)] != null && !endingSong && !isCameraOnForcedPos)
		{
			moveCameraSection(Std.int(curStep / 16));
		}
		if (camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms && curBeat % 4 == 0)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;
		}

		iconP1.scale.set(1.2, 1.2);
		iconP2.scale.set(1.2, 1.2);

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		if (gf != null && curBeat % gfSpeed == 0 && !gf.stunned && gf.animation.curAnim.name != null && !gf.animation.curAnim.name.startsWith("sing"))
		{
			gf.dance();
		}

		if(curBeat % 2 == 0) {
			if (boyfriend.animation.curAnim.name != null && !boyfriend.animation.curAnim.name.startsWith("sing"))
			{
				boyfriend.dance();
			}
			if (dad.animation.curAnim.name != null && !dad.animation.curAnim.name.startsWith("sing") && !dad.stunned)
			{
				dad.dance();
			}
		} else if(dad.danceIdle && dad.animation.curAnim.name != null && !dad.curCharacter.startsWith('gf') && !dad.animation.curAnim.name.startsWith("sing") && !dad.stunned) {
		{
			dad.dance();
		}

		if(SONG.song.toLowerCase() == 'infernum-bside') {
			if(curBeat == 136) {
				bfire.visible = true;
				bfire2.visible = true;
				bfire3.visible = true;
				bfire4.visible = true;
				bfire5.visible = true;
				bfire6.visible = true;
				FlxG.camera.flash(FlxColor.WHITE, 1);
			}
		}

		if(curStage == 'shitmore') {
			shitmoresfriends.animation.play('bop');
			shitmoresfrends.animation.play('bop');
		}

		if(SONG.song.toLowerCase() == 'vejacion') {
			if(FlxG.random.bool(4))
				jumpscaer();
		}

		switch(SONG.song.toLowerCase()){
			case 'vejacion' :
				if (curBeat >= 138 && curBeat <= 212) {
					camGame.shake(0.05, 1);
					camHUD.shake(0.05, 1);
				}
				if (curBeat >= 261 && curBeat <= 281) {
					camGame.shake(0.05, 1);
					camHUD.shake(0.05, 1);
				}
				if (curBeat >= 303 && curBeat <= 354) {
					camGame.shake(0.08, 1);
					camHUD.shake(0.08, 1);
				}
				if (curBeat >= 370 && curBeat <= 478) {
					camGame.shake(0.08, 1);
					camHUD.shake(0.08, 1);
				}
				if (curBeat >= 527 && curBeat <= 544) {
					camGame.shake(0.1, 1);
					camHUD.shake(0.1, 1);
				}
				if (curBeat >= 557 && curBeat <= 640) {
					if(camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
					{
						FlxG.camera.zoom += 0.1;
						camHUD.zoom += 0.1;
					}
				}
				if (curBeat >= 640 && curBeat <= 729) {
					if(curBeat % 2 == 0 && camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
					{
						FlxG.camera.zoom += 0.1;
						camHUD.zoom += 0.1;
					}
				}
				if (curBeat >= 733 && curBeat <= 745) {
					camGame.shake(0.1, 1);
					camHUD.shake(0.1, 1);
				}
			case 'shitmore' :
				if (curBeat >= 1 && curBeat <= 32) {
					if(camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
					{
						FlxG.camera.zoom += 0.035;
						camHUD.zoom += 0.063;
					}
				}
				if (curBeat >= 32 && curBeat <= 223) {
					if(camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
					{
						FlxG.camera.zoom += 0.1;
						camHUD.zoom += 0.1;
					}
				}
				if (curBeat >= 240 && curBeat <= 432) {
					if(camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
					{
						FlxG.camera.zoom += 0.1;
						camHUD.zoom += 0.1;
					}
				}
			case 'deprave':
				if((curBeat >= 33 && curBeat <= 59) || (curBeat >= 65 && curBeat <= 91) || (curBeat >= 96 && curBeat <= 239))
				{
					if(camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
					{
						FlxG.camera.zoom += 0.015;
						camHUD.zoom += 0.03;
					}
				}
			case 'pressure':
				if((curBeat >= 96 && curBeat <= 188) || (curBeat >= 192 && curBeat <= 288) || (curBeat >= 352 && curBeat <= 416))
				{
					if(camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
					{
						FlxG.camera.zoom += 0.015;
						camHUD.zoom += 0.03;
					}
				}
				else if((curBeat >= 64 && curBeat <= 96)) //2er
				{
					if (curBeat % 2 == 0 && !ClientPrefs.lowQuality)
					{
						FlxG.camera.zoom += 0.015;
						camHUD.zoom += 0.03;
					}
				}
			case 'infernum' |'infernum-hell':
				if((curBeat >= 136 && curBeat <= 168) || (curBeat >= 200 && curBeat <= 296) || (curBeat >= 392 && curBeat <= 420) //LMAO 420 SKKSKSKSKSKSKS SKELETON EMOTICON 
					|| (curBeat >= 940 && curBeat <= 1000) || (curBeat >= 1037 && curBeat <= 1068))
				{
					if(camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
					{
						FlxG.camera.zoom += 0.015;
						camHUD.zoom += 0.03;
					}
				}
				else if((curBeat >= 328 && curBeat <= 384) || (curBeat >= 1004 && curBeat <= 1036)) //2er
				{
					if (curBeat % 2 == 0 && !ClientPrefs.lowQuality)
					{
						FlxG.camera.zoom += 0.015;
						camHUD.zoom += 0.03;
					}
				}
			case 'vexation' |'vexation-hell':
				if((curBeat >= 32 && curBeat <= 208) || (curBeat >= 224 && curBeat <= 272) || (curBeat >= 280 && curBeat <= 288) //LMAO 420 SKKSKSKSKSKSKS SKELETON EMOTICON 
					|| (curBeat >= 368 && curBeat <= 480) || (curBeat >= 616 && curBeat <= 624) || (curBeat >= 632 && curBeat <= 664) || (curBeat >= 760 && curBeat <= 936)
					|| (curBeat >= 944 && curBeat <= 952))
				{
					if(camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
					{
						FlxG.camera.zoom += 0.03;
						camHUD.zoom += 0.03;
					}
				}
				else if((curBeat >= 208 && curBeat <= 224) || (curBeat >= 272 && curBeat <= 280) || (curBeat >= 320 && curBeat <= 352)
					|| (curBeat >= 480 && curBeat <= 496) || (curBeat >= 528 && curBeat <= 616) || (curBeat >= 665 && curBeat <= 760) || (curBeat >= 934 && curBeat <= 944)) //2er
				{
					if (curBeat % 2 == 0 && !ClientPrefs.lowQuality)
					{
						FlxG.camera.zoom += 0.03;
						camHUD.zoom += 0.03;
					}
				}

			case 'abnormal':
				if((curBeat >= 1 && curBeat <= 92) || (curBeat >= 95 && curBeat <= 224) || (curBeat >= 287 && curBeat <= 351))
				{
					if(camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
					{
						FlxG.camera.zoom += 0.015;
						camHUD.zoom += 0.03;
					}
				}
			case 'ignition':
				if((curBeat >= 32 && curBeat <= 60) || (curBeat >= 64 && curBeat <= 220) || (curBeat >= 224 && curBeat <= 252))
				{
					if(camZooming && FlxG.camera.zoom < 1.35 && ClientPrefs.camZooms)
					{
						FlxG.camera.zoom += 0.015;
						camHUD.zoom += 0.03;
					}
				}
				if((curBeat >= 1 && curBeat <= 32) || (curBeat >= 252 && curBeat <= 319))
				{
					if (curBeat % 2 == 0 && !ClientPrefs.lowQuality)
					{
						FlxG.camera.zoom += 0.03;
						camHUD.zoom += 0.03;
					}
				}
		}

		if(SONG.song.toLowerCase() == 'pressure') {
			if(curBeat == 187)
				setVoiceLine('1', 1);
		}

		if(SONG.song.toLowerCase() == 'abnormal') {
			if(curBeat == 95) {
				lightningStrikeShit();
				rain.visible = true;
			}
		}

		if(SONG.song.toLowerCase() == 'infernum-bside') //2er
		{
			if (camZooming && FlxG.camera.zoom < 1.35 && curBeat % 2 == 0 && !ClientPrefs.lowQuality)
			{
				FlxG.camera.zoom += 0.0515;
				camHUD.zoom += 0.021;
			}
		}

		if(SONG.song.toLowerCase() == 'infernum' || SONG.song.toLowerCase() == 'infernum-hell') {
			if(curBeat == 381)
				setVoiceLine('2', 1);
			else if(curBeat == 626)
				setVoiceLine('4', 1);
			else if(curBeat == 641)
				setVoiceLine('5', 1);
			else if(curBeat == 1000)
				setVoiceLine('3', 1);
		}

		switch (curStage)
		{
			case 'CrazyCorruptionAlley' :
				matt.animation.play('bop', true);	
			case 'CrazyVexationAlley':
				matt.animation.play('bop', true);	
				crowd.animation.play('bop'); //reducing lag :P	
				circ.animation.play('glow');	
		}

		if (curStage == 'corruptionAlley' && FlxG.random.bool(30) && curBeat > lightningStrikeBeat + lightningOffset && SONG.song.toLowerCase() == 'pressure')
		{
			lightningStrikeShit();
		}
		lastBeatHit = curBeat;

		setOnLuas('curBeat', curBeat); //DAWGG?????
		callOnLuas('onBeatHit', []);

	public var closeLuas:Array<FunkinLua> = [];

	public function callOnLuas(event:String, args:Array<Dynamic>):Dynamic {
		var returnVal:Dynamic = FunkinLua.Function_Continue;
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			var ret:Dynamic = luaArray[i].call(event, args);
			if(ret != FunkinLua.Function_Continue) {
				returnVal = ret;
			}
		}

		for (i in 0...closeLuas.length) {
			luaArray.remove(closeLuas[i]);
			closeLuas[i].stop();
		}
		#end
		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic) {
		#if LUA_ALLOWED
		for (i in 0...luaArray.length) {
			luaArray[i].set(variable, arg);
		}
		#end
	}

	function StrumPlayAnim(isDad:Bool, id:Int, time:Float) {
		var spr:StrumNote = null;
		if(isDad) {
			spr = strumLineNotes.members[id];
		} else {
			spr = playerStrums.members[id];
		}

		if(spr != null) {
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public var ratingName:String = '?';
	public var ratingPercent:Float;
	public var ratingFC:String;
	public function RecalculateRating() {
		setOnLuas('score', songScore);
		setOnLuas('misses', songMisses);
		setOnLuas('hits', songHits);

		var ret:Dynamic = callOnLuas('onRecalculateRating', []);
		if(ret != FunkinLua.Function_Stop)
		{
			if(totalPlayed < 1) //Prevent divide by 0
				ratingName = '?';
			else
		    {
				// Rating Percent
				ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				//trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				if(ratingPercent >= 1)
				{
					ratingName = ratingStuff[ratingStuff.length-1][0]; //Uses last string
				}
				else
				{
					for (i in 0...ratingStuff.length-1)
					{
						if(ratingPercent < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
					}
				}
			}

			// Rating FC
			ratingFC = "";
			if (sicks > 0) ratingFC = "SFC";
			if (goods > 0) ratingFC = "GFC";
			if (bads > 0 || shits > 0) ratingFC = "FC";
			if (songMisses > 0 && songMisses < 10) ratingFC = "SDCB";
			else if (songMisses >= 10) ratingFC = "Clear";
		}
		setOnLuas('rating', ratingPercent);
		setOnLuas('ratingName', ratingName);
		setOnLuas('ratingFC', ratingFC);
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null):String
	{
		if(chartingMode) return null;

		var usedPractice:Bool = (ClientPrefs.getGameplaySetting('practice', false) || ClientPrefs.getGameplaySetting('botplay', false));
		for (i in 0...achievesToCheck.length) {
			var achievementName:String = achievesToCheck[i];
			if(!Achievements.isAchievementUnlocked(achievementName) && !cpuControlled) {
				var unlock:Bool = false;
				switch(achievementName)
				{
					case 'week1_nomiss' | 'week2_nomiss' | 'week3_nomiss' | 'week4_nomiss' | 'week5_nomiss' | 'week6_nomiss' | 'week7_nomiss':
				if(isStoryMode && campaignMisses + songMisses < 1 && CoolUtil.difficultyString() == 'HARD' && storyPlaylist.length <= 1 && !changedDifficulty && !usedPractice)
				{
					var weekName:String = WeekData.getWeekFileName();
							switch(weekName) //I know this is a lot of duplicated code, but it's easier readable and you can add weeks with different names than the achievement tag
							{
								case 'week1':
									if(achievementName == 'week1_nomiss') unlock = true;
								case 'week2':
									if(achievementName == 'week2_nomiss') unlock = true;
								case 'week3':
									if(achievementName == 'week3_nomiss') unlock = true;
								case 'week4':
									if(achievementName == 'week4_nomiss') unlock = true;
								case 'week5':
									if(achievementName == 'week5_nomiss') unlock = true;
								case 'week6':
									if(achievementName == 'week6_nomiss') unlock = true;
								case 'week7':
									if(achievementName == 'week7_nomiss') unlock = true;
							}
						}
					case 'ur_bad':
						if(ratingPercent < 0.2 && !practiceMode) {
							unlock = true;
						}
					case 'ur_good':
						if(ratingPercent >= 1 && !usedPractice) {
							unlock = true;
						}
					case 'roadkill_enthusiast':
						if(Achievements.henchmenDeath >= 100) {
							unlock = true;
						}
					case 'oversinging':
						if(boyfriend.holdTimer >= 10 && !usedPractice) {
							unlock = true;
						}
					case 'hype':
						if(!boyfriendIdled && !usedPractice) {
							unlock = true;
						}
					case 'two_keys':
						if(!usedPractice) {
							var howManyPresses:Int = 0;
							for (j in 0...keysPressed.length) {
								if(keysPressed[j]) howManyPresses++;
							}

							if(howManyPresses <= 2) {
								unlock = true;
							}
						}
					case 'toastie':
						if(/*ClientPrefs.framerate <= 60 &&*/ ClientPrefs.lowQuality && !ClientPrefs.globalAntialiasing)
						{
							unlock = true;
						}
					case 'debugger':
						if(Paths.formatToSongPath(SONG.song) == 'test' && !usedPractice) {
							unlock = true;
						}
				}

			if(unlock) {
				Achievements.unlockAchievement(achievementName);
				return achievementName;
			    }
			}
		}
		return null;
	}
	#end

	var curLight:Int = 0;
	var curLightEvent:Int = 0;
}
