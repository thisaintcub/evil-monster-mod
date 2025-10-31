package meta.state;

import flixel.FlxG;
import meta.MusicBeat.MusicBeatState;
import meta.data.*;
import meta.data.dependency.Discord;
import meta.data.dependency.FNFSprite;
import flixel.input.mouse.FlxMouseEvent;

using StringTools;

class MainMenuState extends MusicBeatState
{
	static var initialized:Bool = false;
	var bg:FNFSprite;
	var time:Float = 0;

	override public function create():Void
	{
		controls.setKeyboardScheme(None, false);

		super.create();

		FlxG.mouse.visible = true;
		#if discord_rpc
		Discord.changePresence('boo', 'boo');
		#end

		ForeverTools.resetMenuMusic(true);

		bg = new FNFSprite(0, 0).loadGraphic(Paths.image('menus/mainmenu/pattern'));
		bg.setGraphicSize(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.screenCenter();
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

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		super.update(elapsed);
	}
}