package gameObjects;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import gameObjects.background.*;
import meta.CoolUtil;
import meta.data.Conductor;
import meta.data.dependency.FNFSprite;
import meta.state.PlayState;

using StringTools;

/**
	This is the stage class. It sets up everything you need for stages in a more organised and clean manner than the
	base game. It's not too bad, just very crowded. I'll be adding stages as a separate
	thing to the weeks, making them not hardcoded to the songs.
**/
class Stage extends FlxTypedGroup<FlxBasic>
{
	public var cameraZoom:Float = 1.05;
	public var cameraSpeed:Float = 1.0;

	public var curStage = 'room';

	public var room:FNFSprite;
	public var gradient:FNFSprite;
	private var gradientTween:FlxTween;

	public var foreground:FlxTypedGroup<FlxBasic>;

	public function new(curStage)
	{
		super();
		this.curStage = curStage;

		switch (CoolUtil.spaceToDash(PlayState.SONG.song.toLowerCase()))
		{
			default:
				curStage = 'room';
		}

		PlayState.curStage = curStage;

		foreground = new FlxTypedGroup<FlxBasic>();

		//
		switch (curStage)
		{
			default:
				cameraZoom = 0.55;
				curStage = 'room';

				room = new FNFSprite(0, 0).loadGraphic(Paths.image('backgrounds/room'));

				gradient = new FNFSprite(400, -400).loadGraphic(Paths.image('backgrounds/gradient'));
				gradient.alpha = 0;
				add(gradient);
		}
	}

	// get the dad's position
	public function dadPosition(curStage, boyfriend:Character, dad:Character, camPos:FlxPoint):Void
	{
		var characterArray:Array<Character> = [dad, boyfriend];
	}

	public function repositionPlayers(curStage, boyfriend:Character, dad:Character):Void
	{
		switch (curStage)
		{
			case 'room':
				dad.x += 650;
				dad.y -= 200;
		}
	}

	public function stageUpdate(curBeat:Int, boyfriend:Boyfriend, dadOpponent:Character)
	{
		if (curBeat % 4 == 0) 
		{
			if(gradientTween != null)
				gradientTween.cancel();
	
			gradient.alpha = 1;
			gradientTween = FlxTween.tween(gradient, {alpha: 0}, 1.5);
		}
	}

	public function stageUpdateConstant(elapsed:Float, boyfriend:Boyfriend, dadOpponent:Character)
	{
		//
	}

	override function add(Object:FlxBasic):FlxBasic
	{
		if (Init.trueSettings.get('Disable Antialiasing') && Std.isOfType(Object, FlxSprite))
			cast(Object, FlxSprite).antialiasing = false;
		return super.add(Object);
	}
}
