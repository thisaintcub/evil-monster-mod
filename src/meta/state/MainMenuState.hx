package meta.state;

import openfl.display.BitmapData;
import openfl.utils.Assets;
import flixel.system.FlxAssets.FlxShader;
import openfl.filters.ShaderFilter;
import flixel.FlxG;
import meta.MusicBeat.MusicBeatState;
import meta.data.*;
import meta.data.dependency.Discord;
import meta.data.dependency.FNFSprite;
import flixel.input.mouse.FlxMouseEvent;
import flixel.util.FlxColor;

using StringTools;

class MainMenuState extends MusicBeatState
{
	static var initialized:Bool = false;
	var bg:FNFSprite;
	var bgOriginal:FNFSprite;
	var time:Float = 0;

	override public function create():Void
	{
		controls.setKeyboardScheme(None, false);

        //var jpeg = new FlxShader();
        //jpeg.glFragmentSource = Assets.getText("res/shaders/jpegcompression.frag");
        //FlxG.camera.filters = [new ShaderFilter(jpeg)];

		bgColor = FlxColor.BLACK;

		super.create();

		FlxG.mouse.visible = true;
		#if discord_rpc
		Discord.changePresence('boo', 'boo');
		#end

		ForeverTools.resetMenuMusic(true);

		bgOriginal = new FNFSprite(0, 0).loadGraphic(Paths.image('menus/mainmenu/pattern'));

		bg = new FNFSprite(0, 0);
		bg.makeGraphic(Std.int(bgOriginal.width), Std.int(bgOriginal.height), FlxColor.TRANSPARENT, true);
		bg.setGraphicSize(FlxG.width, FlxG.height);
		bg.updateHitbox();
		add(bg);

		var logo:FNFSprite = new FNFSprite(0, 50).loadGraphic(Paths.image('menus/mainmenu/logo'));
		logo.screenCenter(X);
		add(logo);

		var play:FNFSprite = new FNFSprite(0, 475).loadGraphic(Paths.image('menus/mainmenu/play'));
		play.setGraphicSize(play.width * .5);
		play.updateHitbox();
		play.screenCenter(X);
		add(play);

		var settings:FNFSprite = new FNFSprite(0, 575).loadGraphic(Paths.image('menus/mainmenu/settings'));
		settings.setGraphicSize(settings.width * .5);
		settings.updateHitbox();
		settings.screenCenter(X);
		add(settings);

        FlxMouseEvent.add(play, onPlayClick, null, null, null);
        FlxMouseEvent.add(settings, onSettingsClick, null, null, null);

		persistentUpdate = true;

		initialized = true;

		bitmapData = bg.graphic.bitmap;
		originalData = bgOriginal.graphic.bitmap;
	}

	var transitioning:Bool = false;

	private function onPlayClick(o:FNFSprite)
	{
		// so it doesnt mute
		var s = FlxG.sound.play(Paths.sound('steps'));
		s.persist = true;

		PlayState.SONG = Song.loadFromJson('mash');

		moveToState(new PlayState());
	}

	private function onSettingsClick(o:FNFSprite)
	{
		moveToState(new OptionsMenuState());
	}

	private function moveToState(target:flixel.FlxState)
	{
		if (!transitioning)
		{
			transitioning = true;

			FlxG.sound.play(Paths.sound('clickSfx'), 0.7);

			if (FlxG.sound.music != null)
				FlxG.sound.music.stop();

			FlxG.mouse.visible = false;

			Main.switchState(target);
		}
	}

	var bitmapData:BitmapData;
	var originalData:BitmapData;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		super.update(elapsed);

		time += elapsed;
		
		bitmapData.lock();
		
		for (y in 0...Std.int(bgOriginal.height))
		{
			var wave = Math.sin(y * 0.02 + time * 3) * 15;
			
			for (x in 0...Std.int(bgOriginal.width))
			{
				var sourceX = Std.int(x + wave);
				var sourceY = y;
				
				if (sourceX < 0) sourceX = 0;
				else if (sourceX > Std.int(bgOriginal.width) - 1) sourceX = Std.int(bgOriginal.width) - 1;
				
				var pixel = originalData.getPixel32(sourceX, sourceY);
				bitmapData.setPixel32(x, y, pixel);
			}
		}
		
		bitmapData.unlock();
	}
}