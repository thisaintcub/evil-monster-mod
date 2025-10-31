package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import gameObjects.userInterface.*;
import gameObjects.userInterface.menu.*;
import gameObjects.userInterface.notes.*;
import gameObjects.userInterface.notes.Strumline.UIStaticArrow;
import meta.data.Conductor;
import meta.data.Section.SwagSection;
import meta.data.Timings;
import meta.state.PlayState;

using StringTools;

/**
	Forever Assets is a class that manages the different asset types, basically a compilation of switch statements that are
	easy to edit for your own needs. Most of these are just static functions that return information
**/
class ForeverAssets
{
	//
	public static function generateCombo(asset:String, number:String, allSicks:Bool, assetModifier:String = 'base', changeableSkin:String = 'default',
			baseLibrary:String, negative:Bool, createdColor:FlxColor, scoreInt:Int):FlxSprite
	{
		var width = 100;
		var height = 140;

		var newSprite:FlxSprite = new FlxSprite().loadGraphic(Paths.image(ForeverTools.returnSkinAsset(asset, assetModifier, changeableSkin, baseLibrary)),
			true, width, height);

		switch (assetModifier)
		{
			default:
				newSprite.alpha = 1;
				newSprite.screenCenter();
				newSprite.x += (43 * scoreInt) + 20;
				newSprite.y += 60;

				newSprite.color = FlxColor.WHITE;
				if (negative)
					newSprite.color = createdColor;

				newSprite.animation.add('base', [
					(Std.parseInt(number) != null ? Std.parseInt(number) + 1 : 0) + (!allSicks ? 0 : 11)
				], 0, false);
				newSprite.animation.play('base');
		}

		newSprite.antialiasing = true;
		newSprite.setGraphicSize(Std.int(newSprite.width * 0.5));
		newSprite.updateHitbox();
		newSprite.acceleration.y = FlxG.random.int(200, 300);
		newSprite.velocity.y = -FlxG.random.int(140, 160);
		newSprite.velocity.x = FlxG.random.float(-5, 5);

		return newSprite;
	}

	public static function generateRating(asset:String, perfectSick:Bool, timing:String, assetModifier:String = 'base', changeableSkin:String = 'default',
			baseLibrary:String):FlxSprite
	{
		var width = 500;
		var height = 163;
		var rating:FlxSprite = new FlxSprite().loadGraphic(Paths.image(ForeverTools.returnSkinAsset('judgements', assetModifier, changeableSkin,
			baseLibrary)), true, width, height);

		switch (assetModifier)
		{
			default:
				rating.alpha = 1;
				rating.screenCenter();
				rating.x = (FlxG.width * 0.55) - 40;
				rating.y -= 60;
				rating.acceleration.y = 550;
				rating.velocity.y = -FlxG.random.int(140, 175);
				rating.velocity.x = -FlxG.random.int(0, 10);
				rating.animation.add('base', [
					Std.int((Timings.judgementsMap.get(asset)[0] * 2) + (perfectSick ? 0 : 2) + (timing == 'late' ? 1 : 0))
				], 24, false);
				rating.animation.play('base');
		}

		rating.antialiasing = true;
		rating.setGraphicSize(Std.int(rating.width * 0.7));

		return rating;
	}

	public static function generateUIArrows(x:Float, y:Float, ?staticArrowType:Int = 0, assetModifier:String):UIStaticArrow
	{
		var newStaticArrow:UIStaticArrow = new UIStaticArrow(x, y, staticArrowType);
		switch (assetModifier)
		{
			case 'chart editor':
				newStaticArrow.loadGraphic(Paths.image('UI/forever/base/chart editor/note_array'), true, 157, 156);
				newStaticArrow.animation.add('static', [staticArrowType]);
				newStaticArrow.animation.add('pressed', [16 + staticArrowType], 12, false);
				newStaticArrow.animation.add('confirm', [4 + staticArrowType, 8 + staticArrowType, 16 + staticArrowType], 24, false);

				newStaticArrow.addOffset('static');
				newStaticArrow.addOffset('pressed');
				newStaticArrow.addOffset('confirm');

			default:
				var stringSect:String = '';

				stringSect = UIStaticArrow.getArrowFromNumber(staticArrowType);

				newStaticArrow.frames = Paths.getSparrowAtlas('notes/default/arrows');
				newStaticArrow.animation.addByPrefix('static', 'arrow' + stringSect.toUpperCase());
				newStaticArrow.animation.addByPrefix('pressed', stringSect + ' press', 24, false);
				newStaticArrow.animation.addByPrefix('confirm', stringSect + ' confirm', 24, false);

				newStaticArrow.antialiasing = true;
				newStaticArrow.setGraphicSize(Std.int(newStaticArrow.width * 0.7));

				var offsetMiddleX = 0;
				var offsetMiddleY = 0;
				if (staticArrowType > 0 && staticArrowType < 3)
				{
					offsetMiddleX = 2;
					offsetMiddleY = 2;
					if (staticArrowType == 1)
					{
						offsetMiddleX -= 1;
						offsetMiddleY += 2;
					}
				}

				newStaticArrow.addOffset('static');
				switch (staticArrowType)
				{
					case 0: newStaticArrow.addOffset('pressed', -6, -2);
						newStaticArrow.addOffset('confirm', 30, 14);

					case 1: newStaticArrow.addOffset('pressed', -3, -2);
						newStaticArrow.addOffset('confirm', 16, 22);
						
					case 2: newStaticArrow.addOffset('pressed', 1, -6);
						newStaticArrow.addOffset('confirm', 20, 22);

					case 3: newStaticArrow.addOffset('pressed', -.5, -2);
						newStaticArrow.addOffset('confirm', 40, 20);
					default:
				}
				// newStaticArrow.addOffset('pressed', -2, -2);
				// newStaticArrow.addOffset('confirm', 36 + offsetMiddleX, 36 + offsetMiddleY);
		}

		return newStaticArrow;
	}

	/**
		Notes!
	**/
	public static function generateArrow(assetModifier, strumTime, noteData, noteType, noteAlt, ?isSustainNote:Bool = false, ?prevNote:Note = null):Note
	{
		var newNote:Note;
		newNote = Note.returnDefaultNote(assetModifier, strumTime, noteData, noteType, noteAlt, isSustainNote, prevNote);

		if (isSustainNote && prevNote != null)
		{
			if (prevNote.isSustainNote)
				newNote.noteVisualOffset = prevNote.noteVisualOffset;
			else
				newNote.noteVisualOffset = ((prevNote.width * 0.5) - (newNote.width * 0.5));
		}

		return newNote;
	}

	/**
		Checkmarks!
	**/
	public static function generateCheckmark(x:Float, y:Float, asset:String, assetModifier:String = 'base', changeableSkin:String = 'default',
			baseLibrary:String)
	{
		var newCheckmark:Checkmark = new Checkmark(x, y);
		switch (assetModifier)
		{
			default:
				newCheckmark.frames = Paths.getSparrowAtlas(ForeverTools.returnSkinAsset(asset, assetModifier, changeableSkin, baseLibrary));
				newCheckmark.antialiasing = true;

				newCheckmark.animation.addByPrefix('false finished', 'uncheckFinished');
				newCheckmark.animation.addByPrefix('false', 'uncheck', 12, false);
				newCheckmark.animation.addByPrefix('true finished', 'checkFinished');
				newCheckmark.animation.addByPrefix('true', 'check', 12, false);
				newCheckmark.setGraphicSize(Std.int(newCheckmark.width * 0.7));
				newCheckmark.updateHitbox();

				var offsetByX = 45;
				var offsetByY = 5;

				newCheckmark.addOffset('false', offsetByX, offsetByY);
				newCheckmark.addOffset('true', offsetByX, offsetByY);
				newCheckmark.addOffset('true finished', offsetByX, offsetByY);
				newCheckmark.addOffset('false finished', offsetByX, offsetByY);
		}

		return newCheckmark;
	}
}
