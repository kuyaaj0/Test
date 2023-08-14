package;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

class BackgroundDancer extends FlxSprite
{
	public function new(x:Float, y:Float)
	{
		super(x, y);

		frames = Paths.getSparrowAtlas("stagepeople");
		animation.addByIndices('danceLeft', 'Dancers', [0, 1, 2, 3, 4, 5, 6, 7, 8], "", 24, false);
		animation.addByIndices('danceRight', 'Dancers', [9, 10, 11, 12, 13, 14, 15, 16, 17], "", 24, false);
		animation.play('danceLeft');
		antialiasing = ClientPrefs.globalAntialiasing;
	}

	var danceDir:Bool = false;

	public function dance():Void
	{
		danceDir = !danceDir;

		if (danceDir)
			animation.play('danceRight', true);
		else
			animation.play('danceLeft', true);
	}
}
