package;

#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.net.curl.CURLCode;
import flixel.graphics.FlxGraphic;
import WeekData;

using StringTools;

class StoryMenuState extends MusicBeatState
{
	// Wether you have to beat the previous week for playing this one
	// Not recommended, as people usually download your mod for, you know,
	// playing just the modded week then delete it.
	// defaults to True
	public static var weekCompleted:Map<String, Bool> = new Map<String, Bool>();

	var scoreText:FlxText;

	private static var lastDifficultyName:String = '';
	var curDifficulty:Int = 1;

	var txtWeekTitle:FlxText;
	var fuck:Int = 0;

	private static var curWeek:Int = 0;

	var txtTracklist:FlxText;

	var grpWeekText:FlxTypedGroup<MenuItem>;
	var grpChar:FlxTypedSpriteGroup<FlxSprite>;

	var grpLocks:FlxTypedGroup<FlxSprite>;

	var difficultySelectors:FlxGroup;
	var sprDifficulty:FlxSprite;
	var leftArrow:FlxSprite;
	var rightArrow:FlxSprite;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		PlayState.isStoryMode = true;
		WeekData.reloadWeekFiles(true);
		if(curWeek >= WeekData.weeksList.length) curWeek = 0;
		persistentUpdate = persistentDraw = true;

		curWeek = 0;

		scoreText = new FlxText(10, 10, 0, "SCORE: 49324858", 36);
		scoreText.setFormat("VCR OSD Mono", 32);

		txtWeekTitle = new FlxText(FlxG.width * 0.7, 10, 0, "", 32);
		txtWeekTitle.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = 0.7;

		var rankText:FlxText = new FlxText(0, 10);
		rankText.text = 'RANK: GREAT';
		rankText.setFormat(Paths.font("vcr.ttf"), 32);
		rankText.size = scoreText.size;
		rankText.screenCenter(X);

		var ui_tex = Paths.getSparrowAtlas('storymenu/campaign_menu_UI_assets');

		grpChar = new FlxTypedSpriteGroup<FlxSprite>();
		add(grpChar);

		var black2:FlxSprite = new FlxSprite(800).makeGraphic(1280, 720, FlxColor.BLACK);
		// black2.alpha = 0.9;
		add(black2);
		
		grpWeekText = new FlxTypedGroup<MenuItem>();
		add(grpWeekText);

		grpLocks = new FlxTypedGroup<FlxSprite>();
		add(grpLocks);

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		for (i in 0...WeekData.weeksList.length)
		{
			var char:FlxSprite = new FlxSprite(fuck * 1560, 0);
			char.frames = Paths.getSparrowAtlas('storymenu/' + WeekData.weeksList[i]);
			char.animation.addByPrefix('idle', 'idle', 24, true);
			char.animation.play('idle', true);
			grpChar.add(char);

			WeekData.setDirectoryFromWeek(WeekData.weeksLoaded.get(WeekData.weeksList[i]));
			var weekThing:MenuItem = new MenuItem(820, 400, WeekData.weeksList[i] + 'text');
			weekThing.screenCenter(Y);
			weekThing.y += (400 + (weekThing.height + 20) * i);
			weekThing.targetY = i;
			grpWeekText.add(weekThing);
			weekThing.antialiasing = ClientPrefs.globalAntialiasing;
			// weekThing.updateHitbox();

			// Needs an offset thingie
			if (weekIsLocked(i))
			{
				var lock:FlxSprite = new FlxSprite(weekThing.width + 10 + weekThing.x);
				lock.frames = ui_tex;
				lock.animation.addByPrefix('lock', 'lock');
				lock.animation.play('lock');
				lock.ID = i;
				lock.antialiasing = ClientPrefs.globalAntialiasing;
				grpLocks.add(lock);
			}
			fuck += 1;
		}

		WeekData.setDirectoryFromWeek(WeekData.weeksLoaded.get(WeekData.weeksList[0]));

		difficultySelectors = new FlxGroup();
		add(difficultySelectors);

		leftArrow = new FlxSprite(grpWeekText.members[0].x, grpWeekText.members[0].y - 400);
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "arrow left");
		leftArrow.animation.addByPrefix('press', "arrow push left");
		leftArrow.animation.play('idle');
		leftArrow.antialiasing = ClientPrefs.globalAntialiasing;
		difficultySelectors.add(leftArrow);

		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
		if(lastDifficultyName == '')
		{
			lastDifficultyName = CoolUtil.defaultDifficulty;
		}
		curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(lastDifficultyName)));
		
		sprDifficulty = new FlxSprite(0, leftArrow.y);
		sprDifficulty.antialiasing = ClientPrefs.globalAntialiasing;
		changeDifficulty();

		difficultySelectors.add(sprDifficulty);

		rightArrow = new FlxSprite(leftArrow.x + 376, leftArrow.y);
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'arrow right');
		rightArrow.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow.animation.play('idle');
		rightArrow.antialiasing = ClientPrefs.globalAntialiasing;
		difficultySelectors.add(rightArrow);

		var tracksSprite:FlxSprite = new FlxSprite(leftArrow.x, leftArrow.y - 200).loadGraphic(Paths.image('storymenu/Menu_Tracks'));
		tracksSprite.antialiasing = ClientPrefs.globalAntialiasing;
		add(tracksSprite);

		txtTracklist = new FlxText(grpWeekText.members[0].x, tracksSprite.y + 50, 0, "", 32);
		txtTracklist.alignment = LEFT;
		txtTracklist.font = rankText.font;
		txtTracklist.color = 0xFFe55777;
		add(txtTracklist);
		// add(rankText);
		add(scoreText);
		add(txtWeekTitle);

		changeWeek();

		super.create();
	}

	override function closeSubState() {
		persistentUpdate = true;
		changeWeek();
		super.closeSubState();
	}

	override function update(elapsed:Float)
	{
		// scoreText.setFormat('VCR OSD Mono', 32);
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 30, 0, 1)));
		if(Math.abs(intendedScore - lerpScore) < 10) lerpScore = intendedScore;

		scoreText.text = "WEEK SCORE:" + lerpScore;

		// FlxG.watch.addQuick('font', scoreText.font);

		difficultySelectors.visible = !weekIsLocked(curWeek);

		if (!movedBack && !selectedWeek && WeekData.weeksList.length > 0)
		{
			var upP = controls.UI_UP_P;
			var downP = controls.UI_DOWN_P;
			var leftP = controls.UI_LEFT_P;
			var rightP = controls.UI_RIGHT_P;
			if (upP)
			{
				changeWeek(-1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}

			if (downP)
			{
				changeWeek(1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}

			if (leftP)
				rightArrow.animation.play('press')
			else
				rightArrow.animation.play('idle');

			if (rightP)
				leftArrow.animation.play('press');
			else
				leftArrow.animation.play('idle');

			if (rightP)
				changeDifficulty(1);
			else if (leftP)
				changeDifficulty(-1);
			else if (upP || downP)
				changeDifficulty();

			if(FlxG.keys.justPressed.CONTROL)
			{
				persistentUpdate = false;
				openSubState(new GameplayChangersSubstate());
			}
			else if(controls.RESET)
			{
				persistentUpdate = false;
				openSubState(new ResetScoreSubState('', curDifficulty, '', curWeek));
				//FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			else if (controls.ACCEPT)
			{
				selectWeek();
			}
		}

		if (controls.BACK && !movedBack && !selectedWeek)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			movedBack = true;
			MusicBeatState.switchState(new MainMenuState());
		}

		super.update(elapsed);

		grpLocks.forEach(function(lock:FlxSprite)
		{
			lock.y = grpWeekText.members[lock.ID].y;
		});
	}

	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;

	function selectWeek()
	{
		if (!weekIsLocked(curWeek))
		{
			if (stopspamming == false)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));

				grpWeekText.members[curWeek].startFlashing();
				stopspamming = true;
			}

			// We can't use Dynamic Array .copy() because that crashes HTML5, here's a workaround.
			var songArray:Array<String> = [];
			var leWeek:Array<Dynamic> = WeekData.weeksLoaded.get(WeekData.weeksList[curWeek]).songs;
			for (i in 0...leWeek.length) {
				songArray.push(leWeek[i][0]);
			}

			// Nevermind that's stupid lmao
			PlayState.storyPlaylist = songArray;
			PlayState.isStoryMode = true;
			selectedWeek = true;

			var diffic = CoolUtil.getDifficultyFilePath(curDifficulty);
			if(diffic == null) diffic = '';

			PlayState.storyDifficulty = curDifficulty;

			PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
			PlayState.campaignScore = 0;
			PlayState.campaignMisses = 0;
			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				LoadingState.loadAndSwitchState(new PlayState(), true);
				FreeplayState.destroyFreeplayVocals();
			});
		} else {
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}
	}

	var tweenDifficulty:FlxTween;
	var lastImagePath:String;
	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = CoolUtil.difficulties.length-1;
		if (curDifficulty >= CoolUtil.difficulties.length)
			curDifficulty = 0;

		var image:Dynamic = Paths.image('menudifficulties/' + Paths.formatToSongPath(CoolUtil.difficulties[curDifficulty]));
		var newImagePath:String = '';
		if(Std.isOfType(image, FlxGraphic))
		{
			var graphic:FlxGraphic = image;
			newImagePath = graphic.assetsKey;
		}
		else
			newImagePath = image;

		if(newImagePath != lastImagePath)
		{
			sprDifficulty.loadGraphic(image);
			sprDifficulty.x = leftArrow.x + 60;
			sprDifficulty.x += (308 - sprDifficulty.width) / 2;
			sprDifficulty.alpha = 0;
			sprDifficulty.y = leftArrow.y - 15;

			if(tweenDifficulty != null) tweenDifficulty.cancel();
			tweenDifficulty = FlxTween.tween(sprDifficulty, {y: leftArrow.y + 15, alpha: 1}, 0.07, {onComplete: function(twn:FlxTween)
			{
				tweenDifficulty = null;
			}});
		}
		lastImagePath = newImagePath;
		lastDifficultyName = CoolUtil.difficulties[curDifficulty];

		#if !switch
		intendedScore = Highscore.getWeekScore(WeekData.weeksList[curWeek], curDifficulty);
		#end
	}

	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	function changeWeek(change:Int = 0):Void
	{

		if (change == 1 && curWeek != WeekData.weeksList.length - 1) {
			FlxTween.tween(grpChar ,{x: grpChar.x - 1560}, 0.6, {ease: FlxEase.expoOut});
			FlxTween.tween(grpWeekText.members[0], {alpha: 0}, 0.06, {ease: FlxEase.expoOut,
				onComplete: function(twn:FlxTween) {
				}
			});
		}
		else if (change == -1 && curWeek != 0) {
			FlxTween.tween(grpChar ,{x: grpChar.x + 1560}, 0.6, {ease: FlxEase.expoOut});
			FlxTween.tween(grpWeekText.members[0], {alpha: 1}, 0.06, {ease: FlxEase.expoOut,
				onComplete: function(twn:FlxTween) {
				}
			});
		}

		if ((change == 1 && curWeek != WeekData.weeksList.length - 1) || (change == -1 && curWeek > 0)) // This is a.                                                                              sandwich
		{
			// FlxTween.tween(songText ,{alpha: 1, x: (FlxG.width / 2) - (25 / 2 * songs[curweek + change].songName.length)}, 0.2, {ease: FlxEase.expoOut});
			// FlxTween.tween(prevsongText ,{alpha: 0, x: (FlxG.width / 2) - (25 / 2 * songs[curweek + change].songName.length)}, 0.2, {ease: FlxEase.expoOut});
			
		}

		curWeek += change;

		
		if (curWeek < 0)
			curWeek = 0;
		else if (curWeek >= WeekData.weeksList.length -1)
			curWeek = WeekData.weeksList.length -1 ;

		var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[curWeek]);
		WeekData.setDirectoryFromWeek(leWeek);

		var leName:String = leWeek.storyName;
		txtWeekTitle.text = leName.toUpperCase();
		txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);

		var bullShit:Int = 0;

		for (item in grpWeekText.members)
		{
			item.targetY = bullShit - curWeek;
			if (item.targetY == Std.int(0) && !weekIsLocked(curWeek))
				item.alpha = 1;
			else
				item.alpha = 0.6;
			bullShit++;
		}

		PlayState.storyWeek = curWeek;

		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
		var diffStr:String = WeekData.getCurrentWeek().difficulties;
		if(diffStr != null) diffStr = diffStr.trim(); //Fuck you HTML5

		if(diffStr != null && diffStr.length > 0)
		{
			var diffs:Array<String> = diffStr.split(',');
			var i:Int = diffs.length - 1;
			while (i > 0)
			{
				if(diffs[i] != null)
				{
					diffs[i] = diffs[i].trim();
					if(diffs[i].length < 1) diffs.remove(diffs[i]);
				}
				--i;
			}

			if(diffs.length > 0 && diffs[0].length > 0)
			{
				CoolUtil.difficulties = diffs;
			}
		}
		
		curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(CoolUtil.defaultDifficulty)));
		var newPos:Int = CoolUtil.difficulties.indexOf(lastDifficultyName);
		//trace('Pos of ' + lastDifficultyName + ' is ' + newPos);
		if(newPos > -1)
		{
			curDifficulty = newPos;
		}
		updateText();
	}

	function weekIsLocked(weekNum:Int) {
		var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[weekNum]);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!weekCompleted.exists(leWeek.weekBefore) || !weekCompleted.get(leWeek.weekBefore)));
	}

	function updateText()
	{

		var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[curWeek]);
		var stringThing:Array<String> = [];
		for (i in 0...leWeek.songs.length) {
			stringThing.push(leWeek.songs[i][0]);
		}

		txtTracklist.text = '';
		for (i in 0...stringThing.length)
		{
			txtTracklist.text += stringThing[i] + '\n';
		}

		txtTracklist.text = txtTracklist.text.toUpperCase();

		#if !switch
		intendedScore = Highscore.getWeekScore(WeekData.weeksList[curWeek], curDifficulty);
		#end
	}
}
