package meta.data;

import flixel.FlxG;

using StringTools;

class Highscore
{
	public static var songScores:Map<String, Int> = new Map();

	public static function saveScore(song:String, score:Int = 0,):Void
	{
		var daSong:String = song;

		if (songScores.exists(daSong))
		{
			if (songScores.get(daSong) < score)
				setScore(daSong, score);
		}
		else
			setScore(daSong, score);
	}

	static function setScore(song:String, score:Int):Void
	{
		songScores.set(song, score);
		FlxG.save.data.songScores = songScores;
		FlxG.save.flush();
	}

	public static function getScore(song:String):Int
	{
		if (!songScores.exists(song))
			setScore(song, 0);

		return songScores.get(song);
	}

	public static function load():Void
	{
		if (FlxG.save.data.songScores != null)
			songScores = FlxG.save.data.songScores;
	}
}
