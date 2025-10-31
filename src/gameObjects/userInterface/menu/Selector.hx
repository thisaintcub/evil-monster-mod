package gameObjects.userInterface.menu;

import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import meta.data.dependency.FNFSprite;
import meta.data.font.Alphabet;

class Selector extends FlxTypedSpriteGroup<FlxSprite>
{
	var leftSelector:FNFSprite;
	var rightSelector:FNFSprite;

	public var optionChosen:Alphabet;
	public var chosenOptionString:String = '';

	public var optionName:String = "";
	public var options:Array<String>;

	public var isNumber(get, never):Bool;

	public var darkBG:Bool = false;

	public function new(x:Float = 0, y:Float = 0, word:String, options:Array<String>)
	{
		super(x, y);

		optionName = word;
		this.options = options;

		var shiftX = 48, shiftY = 35;

		leftSelector = createSelector(shiftX, shiftY, word, 'left');
		rightSelector = createSelector(shiftX + ((word.length) * 50) + (shiftX * 0.25) + ((isNumber) ? 20 : 0), shiftY, word, 'right');
		add(leftSelector);
		add(rightSelector);

		chosenOptionString = Std.string(Init.trueSettings.get(word));

		var inc:Int = isNumber ? 200 : 0;
		optionChosen = new Alphabet(FlxG.width * 0.5 + inc, shiftY + 20, chosenOptionString, !isNumber, false);
		add(optionChosen);
	}

	public function createSelector(objectX:Float = 0, objectY:Float = 0, word:String, dir:String):FNFSprite
	{
		var returnSelector = new FNFSprite(objectX, objectY);
		returnSelector.frames = Paths.getSparrowAtlas('menus/base/storymenu/campaign_menu_UI_assets');

		returnSelector.animation.addByPrefix('idle', 'arrow $dir', 24, false);
		returnSelector.animation.addByPrefix('press', 'arrow push $dir', 24, false);
		returnSelector.addOffset('press', 0, -10);
		returnSelector.playAnim('idle');

		return returnSelector;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		for (object in 0...objectArray.length)
			objectArray[object].setPosition(x + positionLog[object][0], y + positionLog[object][1]);
	}

	public function selectorPlay(whichSelector:String, animPlayed:String = 'idle')
	{
		switch (whichSelector)
		{
			case 'left':
				leftSelector.playAnim(animPlayed);
			case 'right':
				rightSelector.playAnim(animPlayed);
		}
	}

	var objectArray:Array<FlxSprite> = [];
	var positionLog:Array<Array<Float>> = [];

	override public function add(object:FlxSprite):FlxSprite
	{
		objectArray.push(object);
		positionLog.push([object.x, object.y]);
		return super.add(object);
	}

	public function updateSelection(newSelection:Int, min:Int = 0, max:Int = 100, inc:Int = 5):Void
	{
		var ogValue = Init.trueSettings.get(optionName);
		var increase = inc * newSelection;

		if (newSelection != 0)
			selectorPlay(newSelection == -1 ? 'left' : 'right', 'press');
		FlxG.sound.play(Paths.sound('clickSfx'));

		ogValue = flixel.math.FlxMath.bound(ogValue + increase, min, max);
		chosenOptionString = Std.string(ogValue);
		optionChosen.text = Std.string(ogValue);

		Init.trueSettings.set(optionName, ogValue);
		Init.saveSettings();
	}

	@:noCompletion
	function get_isNumber():Bool
	{
		return (Init.trueSettings.get(optionName) is Int || Init.trueSettings.get(optionName) is Float);
	}
}
