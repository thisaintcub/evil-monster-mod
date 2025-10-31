package;

import flixel.FlxG;
import meta.data.*;
import sys.FileSystem;

/**
	This class is used as an extension to many other forever engine stuffs, please don't delete it as it is not only exclusively used in forever engine
	custom stuffs, and is instead used globally.
**/
class ForeverTools
{
	public static function resetMenuMusic(resetVolume:Bool = false)
	{
		if (((FlxG.sound.music != null) && (!FlxG.sound.music.playing)) || (FlxG.sound.music == null))
		{
			FlxG.sound.playMusic(Paths.music('evilmenu'), (resetVolume) ? 0 : 0.7);

			if (resetVolume)
				FlxG.sound.music.fadeIn(4, 0, 0.7);
		}
	}

	public static function returnSkinAsset(asset:String, assetModifier:String = 'base', changeableSkin:String = 'default', baseLibrary:String,
			?defaultChangeableSkin:String = 'default', ?defaultBaseAsset:String = 'base'):String
	{
		var realAsset = '$baseLibrary/$changeableSkin/$assetModifier/$asset';
		if (!FileSystem.exists(Paths.getPath('images/' + realAsset + '.png', IMAGE)))
		{
			realAsset = '$baseLibrary/$defaultChangeableSkin/$assetModifier/$asset';
			if (!FileSystem.exists(Paths.getPath('images/' + realAsset + '.png', IMAGE)))
				realAsset = '$baseLibrary/$defaultChangeableSkin/$defaultBaseAsset/$asset';
		}

		return realAsset;
	}

	public static function killMusic(songsArray:Array<FlxSound>)
	{
		for (i in 0...songsArray.length)
		{
			songsArray[i].stop();
			songsArray[i].destroy();
		}
	}
}
