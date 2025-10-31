package meta.data.font;

import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxTimer;
import meta.data.font.Alphabet.AlphaCharacter;

using StringTools;

class Dialogue extends FlxSpriteGroup
{
	public var textSpeed:Float = 0.05;
	public var textSize:Float = 1;
	public var textPosition:Int = 0;

	private var _buildText:String;
	private var _finalText:String;

	private var splitWords:Array<String> = [];

	private var dialogueMaxSize:FlxPoint;

	public function new(x:Float, y:Float, text:String = "", width:Int, height:Int)
	{
		super(x, y);
		_finalText = text;
		dialogueMaxSize = new FlxPoint(width, height);
	}

	public function buildText():Void
	{
		textPosition = 0;

		var curRow = 0;
		var loopNum = 0;
		var lastWasSpace = false;

		if (group.members.length > 0)
		{
			for (_sprite in group.members)
				_sprite.destroy();

			clear();
		}

		splitWords = _finalText.split("");

		new FlxTimer().start(textSpeed, function(timer:FlxTimer)
		{
			if (_finalText.fastCodeAt(loopNum) == "\n".code)
				curRow++;

			if (splitWords[curRow] == " ")
				lastWasSpace = true;

			var isNumber:Bool = AlphaCharacter.numbers.contains(splitWords[curRow]);
			var isSymbol:Bool = AlphaCharacter.symbols.contains(splitWords[curRow]);
		});
	}
}
