package meta.subState;

import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import meta.MusicBeat.MusicBeatSubState;
import meta.state.*;

class GameOverSubstate extends MusicBeatSubState
{
	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.ACCEPT)
			endBullshit();

		if (controls.BACK)
			Main.switchState(new MainMenuState());
	}

	var isEnding:Bool = false;

	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;

			// so it doesnt mute
			var s = FlxG.sound.play(Paths.sound('steps'));
			s.persist = true;
			
			Main.switchState(new PlayState());
		}
	}
}
