package;

#if desktop
import Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
#if MODS_ALLOWED
import sys.FileSystem;
import sys.io.File;
#end
import lime.utils.Assets;

using StringTools;

class CreditsState extends MusicBeatState
{
	var curSelected:Int = -1;

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var iconArray:Array<AttachedSprite> = [];
	private var creditsStuff:Array<Array<String>> = [];

	var bg:FlxSprite;
	var front:FlxSprite;
	var descText:FlxText;
	var descBox:AttachedSprite;

	override function create()
	{
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		bg = new FlxSprite().loadGraphic(Paths.image('creditsBG'));
		add(bg);
		
		front = new FlxSprite(1000).loadGraphic(Paths.image('creditsFG'));
		add(front);
		
		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		FlxTween.tween(front, {x: 40}, 1, {ease:FlxEase.sineOut});

		#if MODS_ALLOWED
		//trace("finding mod shit");
		for (folder in Paths.getModDirectories())
		{
			var creditsFile:String = Paths.mods(folder + '/data/credits.txt');
			if (FileSystem.exists(creditsFile))
			{
				var firstarray:Array<String> = File.getContent(creditsFile).split('\n');
				for(i in firstarray)
				{
					var arr:Array<String> = i.replace('\\n', '\n').split("::");
					if(arr.length >= 5) arr.push(folder);
					creditsStuff.push(arr);
				}
				creditsStuff.push(['']);
			}
		};
		var folder = "";
			var creditsFile:String = Paths.mods('data/credits.txt');
			if (FileSystem.exists(creditsFile))
			{
				var firstarray:Array<String> = File.getContent(creditsFile).split('\n');
				for(i in firstarray)
				{
					var arr:Array<String> = i.replace('\\n', '\n').split("::");
					if(arr.length >= 5) arr.push(folder);
					creditsStuff.push(arr);
				}
				creditsStuff.push(['']);
			}
		#end

		var pisspoop:Array<Array<String>> = [ //Name - Icon name - Description - Link
			["Whitty's Insanity Unleashed PLUS Team"],
			[''],
			['Steve The Flop',		'nickiminaj',		'Director, Coder, Composer etc',						'https://www.youtube.com/@SteveTheFlop'],
			['Da Jhonixx',			'jhonixx',			'Charter, Composer for vexation-HELL',					'https://www.youtube.com/@JhoniXX'],
			['Dennisdrs',			'dennisdrs',		'Secondary Charter                  ',					'https://www.youtube.com/@Dennisdrs'],
			['Cristi-Brawl',		'cristibrawl',		'Play tester',									        'https://youtube.com/@CorruptingCristysBallz'],
			['DevilGuy', 			'devilguy', 		'Vexation V6 x V6 charter', 							'https://www.youtube.com/@devilguy2135/featured'],
			['Deimos', 				'deimos', 			'Dialogue writer', 										'https://www.youtube.com/channel/UCy5EbJFX99Fh23KiZD65ioA'],
			['Morse Code', 			'morsecode', 		'Dialogue writer, Composer of Ignition', 				'https://www.youtube.com/channel/UCOGAZA-XFP59wVikz8zjDrg'],
			['GachaMation', 		'gachamate', 		'B-Side Sprites',						 				'https://www.youtube.com/channel/UCKo_HebSfdf4X1EdpUdevBA'],
			["Whitty's Insanity Unleashed Team"],
			[''],
			['Shadorot',			'shadorot',			'Main Director',										'https://www.youtube.com/@Shadorot'],
			['CosmeticCloud',		'cosmetic',			'Musician (and eventually artist)',						'https://www.youtube.com/@cosmeticcloudofficial7737'],
			['Axelepic',			'axelepic',			'Sprite maker, Art',									'https://youtube.com/@Axelepic'],
			['Psych Engine Team'],
			[''],
			['Shadow Mario',		'shadowmario',		'Main Programmer of Psych Engine',						'https://twitter.com/Shadow_Mario_'],
			['RiverOaken',			'riveroaken',		'Main Artist/Animator of Psych Engine',					'https://twitter.com/river_oaken'],
			['bb-panzu',			'bb-panzu',			'Additional Programmer of Psych Engine',				'https://twitter.com/bbsub3'],
			['Engine Contributors'],
			[''],
			['shubs',				'shubs',			'New Input System Programmer',							'https://twitter.com/yoshubs'],
			['SqirraRNG',			'gedehari',			'Chart Editor\'s Sound Waveform base',					'https://twitter.com/gedehari'],
			['iFlicky',				'iflicky',			'Delay/Combo Menu Song Composer\nand Dialogue Sounds',	'https://twitter.com/flicky_i'],
			['PolybiusProxy',		'polybiusproxy',	'.MP4 Video Loader Extension',							'https://twitter.com/polybiusproxy'],
			['Keoiki',				'keoiki',			'Note Splash Animations',								'https://twitter.com/Keoiki_'],
			['Smokey',				'smokey',			'Spritemap Texture Support',							'https://twitter.com/Smokey_5_'],
			/* SHADER PEOPLE. ADDING EM IN ONCE IT'S FINISHEDDD
			['kem0x',				'kem0x',			'External Shader Support',								'https://twitter.com/Smokey_5_'],
			['SqirraRNG',			'gedehari',			'Runtime shaders workaround.',							'https://twitter.com/Smokey_5_'],
			['Fireable'*			'fireable',			'Lua Implementation',									'https://twitter.com/Smokey_5_'],	*/
			["Funkin' Crew"],
			[''],
			['ninjamuffin99',		'ninjamuffin99',	"Programmer of Friday Night Funkin'",					'https://twitter.com/ninja_muffin99'],
			['PhantomArcade',		'phantomarcade',	"Animator of Friday Night Funkin'",						'https://twitter.com/PhantomArcade3K'],
			['evilsk8r',			'evilsk8r',			"Artist of Friday Night Funkin'",						'https://twitter.com/evilsk8r'],
			['kawaisprite',			'kawaisprite',		"Composer of Friday Night Funkin'",						'https://twitter.com/kawaisprite']
		];
		
		for(i in pisspoop){
			creditsStuff.push(i);
		}
	
		for (i in 0...creditsStuff.length)
		{
			var isSelectable:Bool = !unselectableCheck(i);
			var optionText:Alphabet = new Alphabet(0, 80 * i, creditsStuff[i][0], true, !isSelectable);
			optionText.isMenuItem = true;
			optionText.yAdd -= 70;
			if(isSelectable) {
				optionText.x += 70;
			}
			optionText.forceX = optionText.x;
			// optionText.yMult = 90;
			optionText.targetY = i;
			grpOptions.add(optionText);

			if(isSelectable) {
				if(creditsStuff[i][5] != null)
				{
					Paths.currentModDirectory = creditsStuff[i][5];
				}

				var icon:AttachedSprite = new AttachedSprite('credits/' + creditsStuff[i][1]);
				icon.xAdd = optionText.width + 10;
				icon.sprTracker = optionText;
	
				// using a FlxGroup is too much feet!
				iconArray.push(icon);
				add(icon);
				Paths.currentModDirectory = '';

				if(curSelected == -1) curSelected = i;
			}
		}

		descBox = new AttachedSprite();
		descBox.makeGraphic(1, 1, FlxColor.BLACK);
		descBox.xAdd = -10;
		descBox.yAdd = -10;
		descBox.alphaMult = 0.6;
		descBox.alpha = 0.6;
		add(descBox);

		descText = new FlxText(50, 600, 1180, "", 32);
		descText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.4;
		descBox.sprTracker = descText;
		add(descText);

		changeSelection();
		super.create();
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;

		if (upP)
		{
			changeSelection(-1);
		}
		if (downP)
		{
			changeSelection(1);
		}

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}
		if(controls.ACCEPT) {
			CoolUtil.browserLoad(creditsStuff[curSelected][3]);
		}

		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();

		super.update(elapsed);
	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		do {
			curSelected += change;
			if (curSelected < 0)
				curSelected = creditsStuff.length - 1;
			if (curSelected >= creditsStuff.length)
				curSelected = 0;
		} while(unselectableCheck(curSelected));

		var bullShit:Int = 0;

		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			if(!unselectableCheck(bullShit-1)) {
				item.alpha = 0.6;
				if (item.targetY == 0) {
					item.alpha = 1;
				}
			}
		}
		descText.text = creditsStuff[curSelected][2];
	}

	private function unselectableCheck(num:Int):Bool {
		return creditsStuff[num].length <= 1;
	}
}