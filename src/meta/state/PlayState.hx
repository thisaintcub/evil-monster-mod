package meta.state;

import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.effects.FlxTrail;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRandom;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxTimer;
import gameObjects.*;
import gameObjects.userInterface.*;
import gameObjects.userInterface.notes.*;
import gameObjects.userInterface.notes.Strumline.UIStaticArrow;
import meta.*;
import meta.MusicBeat.MusicBeatState;
import meta.data.*;
import meta.data.Song.SwagSong;
import meta.state.menus.*;
import meta.subState.*;
import openfl.display.GraphicsShader;
import openfl.events.KeyboardEvent;
import openfl.filters.ShaderFilter;
import openfl.media.Sound;
import openfl.utils.Assets;
import sys.io.File;

using StringTools;

#if desktop
import meta.data.dependency.Discord;
#end

class PlayState extends MusicBeatState
{
	public static var current:PlayState;

	public static var curStage:String = '';
	public static var SONG:SwagSong;

	public static var storyPlaylist:Array<String> = [];

	public static var songMusic:FlxSound;

	var vocalsP1:FlxSound;
	var vocalsP2:FlxSound;

	public static var vocalArray:Array<FlxSound> = [];

	private var vocalsFinished:Bool = false;

	public static var campaignScore:Int = 0;

	public static var opponent:Character;
	public static var boyfriend:Boyfriend;

	public static var assetModifier:String = 'base';
	public static var changeableSkin:String = 'default';

	private var unspawnNotes:Array<Note> = [];
	private var ratingArray:Array<String> = [];
	private var allSicks:Bool = true;

	// if you ever wanna add more keys
	private var numberOfKeys:Int = 4;

	// get it cus release
	// I'm funny just trust me
	// EDIT [2024/04/12]
	// lol she removed the old variable that existed here
	// so this joke doesn't make sense because there's nothing to joke about
	// oh my god i just realized that LOL @crowplexus
	private var camFollow:FlxObject;
	private var camFollowPos:FlxObject;

	// Discord RPC variables
	public static var songDetails:String = "";
	public static var detailsSub:String = "";
	public static var detailsPausedText:String = "";

	private static var prevCamFollow:FlxObject;

	private var curSong:String = "";

	public var health:Float = 1; // mario

	public static var deaths:Int = 0; // 64

	public var combo:Int = 0;
	public var misses:Int = 0;

	public var generatedMusic:Bool = false;

	var paused:Bool = false;
	var startingSong:Bool = false;
	var startedCountdown:Bool = false;
	var inCutscene:Bool = false;
	var canPause:Bool = true;

	var previousFrameTime:Int = 0;
	var songTime:Float = 0;

	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camAlt:FlxCamera;

	public var camDisplaceX:Float = 0;
	public var camDisplaceY:Float = 0; // might not use depending on result

	public var forceZoom:Array<Float> = [0, 0, 0, 0];
	public var songScore:Int = 0;

	private var stageBuild:Stage;

	public static var iconRPC:String = "";
	public static var songLength:Float = 0;

	// strumlines
	public var cpuStrums:Strumline;
	public var plrStrums:Strumline;
	public var strumLines:FlxTypedGroup<Strumline>;

	public var comboGroup:FlxSpriteGroup;

	function resetStatics()
	{
		assetModifier = 'base';
		changeableSkin = 'default';
		PlayState.SONG.validScore = true;
	}

	override public function create()
	{
		super.create();

		current = this;

		resetStatics();
		Timings.callAccuracy();

		resetMusic();
		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		camGame = FlxG.camera;
		camHUD = new FlxCamera();
		camAlt = new FlxCamera();

		camHUD.bgColor = 0x00000000;
		camAlt.bgColor = 0x00000000;

		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camAlt, false);

		if (SONG == null)
			SONG = Song.loadFromJson('mesh');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		curStage = "";
		if (SONG.stage != null)
			curStage = SONG.stage;

		comboGroup = new FlxSpriteGroup();
		if (Init.trueSettings.get('Fixed Judgements'))
			comboGroup.camera = camHUD;

		displayRating('sick', true, true);
		// popUpCombo(true);

		stageBuild = new Stage(curStage);
		add(stageBuild);

		opponent = new Character().setCharacter(50, 850, SONG.player2);
		boyfriend = new Boyfriend();
		boyfriend.setCharacter(130, 300, SONG.player1);

		var camPos:FlxPoint = new FlxPoint(1100, 700);

		stageBuild.repositionPlayers(curStage, boyfriend, opponent);
		stageBuild.dadPosition(curStage, boyfriend, opponent, camPos);

		if (SONG.assetModifier != null && SONG.assetModifier.length > 1)
			assetModifier = SONG.assetModifier;

		changeableSkin = Init.trueSettings.get("UI Skin");

		add(opponent);
		if (curStage == 'room')
			add(stageBuild.room);
		add(boyfriend);

		add(stageBuild.foreground);

		Conductor.songPosition = -(Conductor.crochet * 4);

		strumLines = new FlxTypedGroup<Strumline>();

		generateSong(SONG.song);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollow.setPosition(camPos.x, camPos.y);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(camPos.x, camPos.y);
		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}

		add(camFollow);
		add(camFollowPos);

		camGame.follow(camFollowPos, LOCKON, 1);
		camGame.zoom = stageBuild.cameraZoom;
		camGame.focusOn(camFollow.getPosition());
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		startingSong = startedCountdown = true;

		add(comboGroup);

		var placement = (FlxG.width * 0.5);
		cpuStrums = new Strumline(placement - (FlxG.width * 0.23), this, opponent, false, true, 4, Init.trueSettings.get('Downscroll'));
		cpuStrums.visible = false; // yeah!
		plrStrums = new Strumline(placement + (FlxG.width * 0.23), this, boyfriend, true, false, 4, Init.trueSettings.get('Downscroll'));

		strumLines.add(cpuStrums);
		strumLines.add(plrStrums);

		strumLines.camera = camHUD;
		add(strumLines);

		// holy shit code
		if (curStage == 'room')
		{
			remove(boyfriend);
			boyfriend.camera = camHUD;
			add(boyfriend);
		}

		keysArray = [
			copyKey(Init.gameControls.get('LEFT')[0]),
			copyKey(Init.gameControls.get('DOWN')[0]),
			copyKey(Init.gameControls.get('UP')[0]),
			copyKey(Init.gameControls.get('RIGHT')[0])
		];

		if (!Init.trueSettings.get('Controller Mode'))
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		Paths.clearUnusedMemory();

		songIntroCutscene();
	}

	public static function copyKey(arrayToCopy:Array<FlxKey>):Array<FlxKey>
	{
		var copiedArray:Array<FlxKey> = arrayToCopy.copy();
		var i:Int = 0;
		var len:Int = copiedArray.length;

		while (i < len)
		{
			if (copiedArray[i] == NONE)
			{
				copiedArray.remove(NONE);
				--i;
			}
			i++;
			len = copiedArray.length;
		}
		return copiedArray;
	}

	var keysArray:Array<Dynamic>;

	public function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);

		if ((key >= 0)
			&& !plrStrums.autoplay
			&& (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || Init.trueSettings.get('Controller Mode'))
			&& (FlxG.keys.enabled && !paused && (FlxG.state.active || FlxG.state.persistentUpdate)))
		{
			if (generatedMusic)
			{
				var previousTime:Float = Conductor.songPosition;
				Conductor.songPosition = songMusic.time;
				// improved this a little bit, maybe its a lil
				var possibleNoteList:Array<Note> = [];
				var pressedNotes:Array<Note> = [];

				plrStrums.notesGroup.forEachAlive(function(daNote:Note)
				{
					if ((daNote.noteData == key) && daNote.canBeHit && !daNote.isSustainNote && !daNote.tooLate && !daNote.wasGoodHit)
						possibleNoteList.push(daNote);
				});
				possibleNoteList.sort((a, b) -> Std.int(a.strumTime - b.strumTime));

				// if there is a list of notes that exists for that control
				if (possibleNoteList.length > 0)
				{
					var eligable = true;
					var firstNote = true;
					// loop through the possible notes
					for (coolNote in possibleNoteList)
					{
						for (noteDouble in pressedNotes)
						{
							if (Math.abs(noteDouble.strumTime - coolNote.strumTime) < 10)
								firstNote = false;
							else
								eligable = false;
						}

						if (eligable)
						{
							goodNoteHit(coolNote, boyfriend, plrStrums, firstNote); // then hit the note
							pressedNotes.push(coolNote);
						}
						// end of this little check
					}
					//
				}
				else // else just call bad notes
					if (!Init.trueSettings.get('Ghost Tapping'))
						missNoteCheck(true, key, boyfriend, true);
				Conductor.songPosition = previousTime;
			}

			if (plrStrums.receptors.members[key] != null && plrStrums.receptors.members[key].animation.curAnim.name != 'confirm')
				plrStrums.receptors.members[key].playAnim('pressed');
		}
	}

	public function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);

		if (FlxG.keys.enabled && !paused && (FlxG.state.active || FlxG.state.persistentUpdate))
		{
			// receptor reset
			if (key >= 0 && plrStrums.receptors.members[key] != null)
				plrStrums.receptors.members[key].playAnim('static');
		}
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if (key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if (key == keysArray[i][j])
						return i;
				}
			}
		}
		return -1;
	}

	override public function destroy()
	{
		if (!Init.trueSettings.get('Controller Mode'))
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		super.destroy();
	}

	var lastBar:Int = 0;

	override public function update(elapsed:Float)
	{
		stageBuild.stageUpdateConstant(elapsed, boyfriend, opponent);

		super.update(elapsed);

		if (health > 2)
			health = 2;

		// dialogue checks
		if (dialogueBox != null && dialogueBox.alive)
		{
			// wheee the shift closes the dialogue
			if (FlxG.keys.justPressed.SHIFT)
				dialogueBox.closeDialog();

			// the change I made was just so that it would only take accept inputs
			if (controls.ACCEPT && dialogueBox.textStarted)
			{
				FlxG.sound.play(Paths.sound('clickSfx'));
				dialogueBox.curPage += 1;

				if (dialogueBox.curPage == dialogueBox.dialogueData.dialogue.length)
					dialogueBox.closeDialog()
				else
					dialogueBox.updateDialog();
			}
		}

		if (!inCutscene)
		{
			if (startingSong)
			{
				if (startedCountdown)
				{
					Conductor.songPosition += elapsed * 1000;
					if (Conductor.songPosition >= 0)
						startSong();
				}
			}
			else
			{
				Conductor.songPosition += elapsed * 1000;

				if (!paused)
				{
					songTime += FlxG.game.ticks - previousFrameTime;
					previousFrameTime = FlxG.game.ticks;

					if (Conductor.lastSongPos != Conductor.songPosition)
					{
						songTime = (songTime + Conductor.songPosition) * 0.5;
						Conductor.lastSongPos = Conductor.songPosition;
					}
				}
			}

			if (generatedMusic && PlayState.SONG.notes[curBar] != null)
			{
				if (curBar != lastBar)
				{
					// section reset stuff
					var lastMustHit:Bool = PlayState.SONG.notes[lastBar].mustHitSection;
					if (PlayState.SONG.notes[curBar].mustHitSection != lastMustHit)
					{
						camDisplaceX = 0;
						camDisplaceY = 0;
					}
					lastBar = Std.int(curBeat * 0.25);
				}

				/*if (!PlayState.SONG.notes[curBar].mustHitSection)
					{
						var char = opponent;

						var getCenterX = char.getMidpoint().x + 100;
						var getCenterY = char.getMidpoint().y - 100;

						camFollow.setPosition(getCenterX + camDisplaceX + char.characterData.camOffsetX,
							getCenterY + camDisplaceY + char.characterData.camOffsetY);
					}
					else
					{
						var char = boyfriend;

						var getCenterX = char.getMidpoint().x - 100;
						var getCenterY = char.getMidpoint().y - 100;

						camFollow.setPosition(getCenterX + camDisplaceX - char.characterData.camOffsetX,
							getCenterY + camDisplaceY + char.characterData.camOffsetY);
				}*/
			}

			var lerpVal = (elapsed * 2.4) * stageBuild.cameraSpeed;
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

			var easeLerp = 1 - Main.framerateAdjust(0.05);
			// camera stuffs
			camGame.zoom = FlxMath.lerp(stageBuild.cameraZoom + forceZoom[0], camGame.zoom, easeLerp);
			camHUD.zoom = FlxMath.lerp(1 + forceZoom[1], camHUD.zoom, easeLerp);

			// not even forcezoom anymore but still
			camGame.angle = FlxMath.lerp(0 + forceZoom[2], camGame.angle, easeLerp);
			camHUD.angle = FlxMath.lerp(0 + forceZoom[3], camHUD.angle, easeLerp);

			// Controls

			// RESET = Quick Game Over Screen
			if (controls.RESET && !startingSong)
				health = 0;

			if (health <= 0 && startedCountdown)
			{
				paused = true;
				persistentUpdate = false;
				persistentDraw = false;

				resetMusic();

				deaths += 1;

				openSubState(new GameOverSubstate());

				#if discord_rpc
				Discord.changePresence("Game Over - " + songDetails, detailsSub, iconRPC);
				#end
			}

			// spawn in the notes from the array
			if ((unspawnNotes[0] != null) && ((unspawnNotes[0].strumTime - Conductor.songPosition) < 3500))
			{
				var dunceNote:Note = unspawnNotes[0];
				// push note to its correct strumline
				strumLines.members[Math.floor((dunceNote.noteData + (dunceNote.mustPress ? 4 : 0)) / numberOfKeys)].push(dunceNote);
				unspawnNotes.splice(unspawnNotes.indexOf(dunceNote), 1);
			}

			noteCalls();

			if (Init.trueSettings.get('Controller Mode'))
				controllerInput();
		}
	}

	// maybe theres a better place to put this, idk -saw
	function controllerInput()
	{
		var justPressArray:Array<Bool> = [controls.LEFT_P, controls.DOWN_P, controls.UP_P, controls.RIGHT_P];

		var justReleaseArray:Array<Bool> = [controls.LEFT_R, controls.DOWN_R, controls.UP_R, controls.RIGHT_R];

		if (justPressArray.contains(true))
		{
			for (i in 0...justPressArray.length)
			{
				if (justPressArray[i])
					onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
			}
		}

		if (justReleaseArray.contains(true))
		{
			for (i in 0...justReleaseArray.length)
			{
				if (justReleaseArray[i])
					onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
			}
		}
	}

	function noteCalls()
	{
		// reset strums
		for (strumline in strumLines)
		{
			// handle strumline stuffs
			for (uiNote in strumline.receptors)
			{
				if (strumline.autoplay)
					strumCallsAuto(uiNote);
			}
		}

		// if the song is generated
		if (generatedMusic && startedCountdown)
		{
			for (strumline in strumLines)
			{
				// set the notes x and y
				var downscrollMultiplier = 1;
				if (Init.trueSettings.get('Downscroll'))
					downscrollMultiplier = -1;

				strumline.allNotes.forEachAlive(function(daNote:Note)
				{
					var roundedSpeed = FlxMath.roundDecimal(daNote.noteSpeed, 2);
					var receptorPosY:Float = strumline.receptors.members[Math.floor(daNote.noteData)].y + Note.swagWidth / 6;
					var psuedoY:Float = (downscrollMultiplier * -((Conductor.songPosition - daNote.strumTime) * (0.45 * roundedSpeed)));
					var psuedoX = 25 + daNote.noteVisualOffset;

					daNote.y = receptorPosY
						+ (Math.cos(flixel.math.FlxAngle.asRadians(daNote.noteDirection)) * psuedoY)
						+ (Math.sin(flixel.math.FlxAngle.asRadians(daNote.noteDirection)) * psuedoX);
					// painful math equation
					daNote.x = strumline.receptors.members[Math.floor(daNote.noteData)].x
						+ (Math.cos(flixel.math.FlxAngle.asRadians(daNote.noteDirection)) * psuedoX)
						+ (Math.sin(flixel.math.FlxAngle.asRadians(daNote.noteDirection)) * psuedoY);

					switch (daNote.noteData)
					{
						case 0 | 3:
							daNote.x += 25;
						case 1:
							daNote.x += 2;
					}

					// also set note rotation
					daNote.angle = -daNote.noteDirection;

					// shitty note hack I hate it so much
					var center:Float = receptorPosY + Note.swagWidth * 0.5;
					if (daNote.isSustainNote)
					{
						if (daNote.noteData == 0 || daNote.noteData == 3)
							daNote.x += 25;

						daNote.y -= ((daNote.height * 0.5) * downscrollMultiplier);
						if ((daNote.animation.curAnim.name.endsWith('holdend')) && (daNote.prevNote != null))
						{
							daNote.y -= ((daNote.prevNote.height * 0.5) * downscrollMultiplier);
							if (Init.trueSettings.get('Downscroll'))
							{
								daNote.y += (daNote.height * 2);
								if (daNote.endHoldOffset == Math.NEGATIVE_INFINITY)
									daNote.endHoldOffset = (daNote.prevNote.y - (daNote.y + daNote.height));
								else
									daNote.y += daNote.endHoldOffset;
								
								daNote.y += 250;
							}
							else
								daNote.y += ((daNote.height * 0.5) * downscrollMultiplier);

							/*switch (daNote.noteData)
								{
									case 0: daNote.x += 25;
									case 1: daNote.x += 2;
									case 3: daNote.x += 25;
							}*/
						}
						if (Init.trueSettings.get('Downscroll')) {
							daNote.y -= 250;
						}
						else
						{
							daNote.y += 50;
						}

						if (Init.trueSettings.get('Downscroll'))
						{
							daNote.flipY = true;
							if ((daNote.parentNote != null && daNote.parentNote.wasGoodHit)
								&& daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center
								&& (strumline.autoplay || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
							{
								var swagRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
								swagRect.height = (center - daNote.y) / daNote.scale.y;
								swagRect.y = daNote.frameHeight - swagRect.height;
								daNote.clipRect = swagRect;
							}
						}
						else
						{
							if ((daNote.parentNote != null && daNote.parentNote.wasGoodHit)
								&& daNote.y + daNote.offset.y * daNote.scale.y <= center
								&& (strumline.autoplay || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
							{
								var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
								swagRect.y = (center - daNote.y) / daNote.scale.y;

								if (daNote.noteData == 0 || daNote.noteData == 3)
									swagRect.y -= 10;

								swagRect.height -= swagRect.y;
								daNote.clipRect = swagRect;
							}
						}
					}
					// hell breaks loose here, we're using nested scripts!
					mainControls(daNote, strumline.character, strumline, strumline.autoplay);

					// check where the note is and make sure it is either active or inactive
					if (daNote.y > FlxG.height)
					{
						daNote.active = false;
						daNote.visible = false;
					}
					else
					{
						daNote.visible = true;
						daNote.active = true;
					}

					if (!daNote.tooLate && daNote.strumTime < Conductor.songPosition - (Timings.msThreshold) && !daNote.wasGoodHit)
					{
						if ((!daNote.tooLate) && (daNote.mustPress))
						{
							if (!daNote.isSustainNote)
							{
								daNote.tooLate = true;
								for (note in daNote.childrenNotes)
									note.tooLate = true;

								vocalsP2.volume = 0;
								missNoteCheck((Init.trueSettings.get('Ghost Tapping')) ? true : false, daNote.noteData, boyfriend, true);
								// ambiguous name
								Timings.updateAccuracy(0);
							}
							else if (daNote.isSustainNote)
							{
								if (daNote.parentNote != null)
								{
									var parentNote = daNote.parentNote;
									if (!parentNote.tooLate)
									{
										var breakFromLate:Bool = false;
										for (note in parentNote.childrenNotes)
										{
											// trace('hold amount ${parentNote.childrenNotes.length}, note is late?' + note.tooLate + ', ' + breakFromLate);
											if (note.tooLate && !note.wasGoodHit)
												breakFromLate = true;
										}
										if (!breakFromLate)
										{
											missNoteCheck((Init.trueSettings.get('Ghost Tapping')) ? true : false, daNote.noteData, boyfriend, true);
											for (note in parentNote.childrenNotes)
												note.tooLate = true;
										}
										//
									}
								}
							}
						}
					}

					// if the note is off screen (above)
					if ((((!Init.trueSettings.get('Downscroll')) && (daNote.y < -daNote.height))
						|| ((Init.trueSettings.get('Downscroll')) && (daNote.y > (FlxG.height + daNote.height))))
						&& (daNote.tooLate || daNote.wasGoodHit))
						destroyNote(strumline, daNote);
				});
			}
		}

		// reset bf's animation
		var holdControls:Array<Bool> = [controls.LEFT, controls.DOWN, controls.UP, controls.RIGHT];
		if ((boyfriend != null && boyfriend.animation != null)
			&& (boyfriend.holdTimer > Conductor.stepCrochet * (4 * 0.001) && (!holdControls.contains(true) || plrStrums.autoplay)))
		{
			if (boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
				boyfriend.dance();
		}
	}

	function destroyNote(strumline:Strumline, daNote:Note)
	{
		daNote.active = false;
		daNote.exists = false;

		var chosenGroup = (daNote.isSustainNote ? strumline.holdsGroup : strumline.notesGroup);
		// note damage here I guess
		daNote.kill();
		if (strumline.allNotes.members.contains(daNote))
			strumline.allNotes.remove(daNote, true);
		if (chosenGroup.members.contains(daNote))
			chosenGroup.remove(daNote, true);
		daNote.destroy();
	}

	function goodNoteHit(coolNote:Note, character:Character, characterStrums:Strumline, ?canDisplayJudgement:Bool = true)
	{
		if (!coolNote.wasGoodHit)
		{
			coolNote.wasGoodHit = true;
			vocalsP2.volume = 1;

			characterPlayAnimation(coolNote, character);
			if (characterStrums.receptors.members[coolNote.noteData] != null)
				characterStrums.receptors.members[coolNote.noteData].playAnim('confirm', false);

			// special thanks to sam, they gave me the original system which kinda inspired my idea for this new one
			if (canDisplayJudgement)
			{
				// get the note ms timing
				var noteDiff:Float = Math.abs(coolNote.strumTime - Conductor.songPosition);
				var isLate:Bool = coolNote.strumTime < Conductor.songPosition;

				// loop through all avaliable judgements
				var foundRating:String = 'miss';
				var lowestThreshold:Float = Math.POSITIVE_INFINITY;
				for (myRating in Timings.judgementsMap.keys())
				{
					var myThreshold:Float = Timings.judgementsMap.get(myRating)[1];
					if (noteDiff <= myThreshold && (myThreshold < lowestThreshold))
					{
						foundRating = myRating;
						lowestThreshold = myThreshold;
					}
				}

				if (!coolNote.isSustainNote)
				{
					increaseCombo(foundRating, coolNote.noteData, character);
					// popUpScore(foundRating, isLate, characterStrums, coolNote);
					if (coolNote.childrenNotes.length > 0)
						Timings.notesHit++;
					healthCall(Timings.judgementsMap.get(foundRating)[3]);
				}
				else if (coolNote.isSustainNote)
				{
					// call updated accuracy stuffs
					if (coolNote.parentNote != null)
					{
						Timings.updateAccuracy(100, true, coolNote.parentNote.childrenNotes.length);
						healthCall(100 / coolNote.parentNote.childrenNotes.length);
					}
				}
			}

			if (!coolNote.isSustainNote)
				destroyNote(characterStrums, coolNote);
			//
		}
	}

	function missNoteCheck(?includeAnimation:Bool = false, direction:Int = 0, character:Character, popMiss:Bool = false, lockMiss:Bool = false)
	{
		if (includeAnimation)
		{
			var stringDirection:String = UIStaticArrow.getArrowFromNumber(direction);

			character.playAnim('sing' + stringDirection.toUpperCase() + 'miss', lockMiss);
		}

		decreaseCombo(popMiss);
	}

	function characterPlayAnimation(coolNote:Note, character:Character)
	{
		// alright so we determine which animation needs to play
		// get alt strings and stuffs
		var stringArrow:String = '';
		var altString:String = '';

		var baseString = 'sing' + UIStaticArrow.getArrowFromNumber(coolNote.noteData).toUpperCase();

		// I tried doing xor and it didnt work lollll
		if (coolNote.noteAlt > 0)
			altString = '-alt';
		if (((SONG.notes[curBar] != null) && (SONG.notes[curBar].altAnim)) && (character.animOffsets.exists(baseString + '-alt')))
		{
			if (altString != '-alt')
				altString = '-alt';
			else
				altString = '';
		}

		stringArrow = baseString + altString;
		// if (coolNote.foreverMods.get('string')[0] != "")
		//	stringArrow = coolNote.noteString;

		character.playAnim(stringArrow, true);
		character.holdTimer = 0;
	}

	private function strumCallsAuto(cStrum:UIStaticArrow, ?callType:Int = 1, ?daNote:Note):Void
	{
		switch (callType)
		{
			case 1:
				// end the animation if the calltype is 1 and it is done
				if ((cStrum.animation.finished) && (cStrum.canFinishAnimation))
					cStrum.playAnim('static');
			default:
				// check if it is the correct strum
				if (daNote.noteData == cStrum.ID)
				{
					// if (cStrum.animation.curAnim.name != 'confirm')
					cStrum.playAnim('confirm'); // play the correct strum's confirmation animation (haha rhymes)

					// stuff for sustain notes
					if ((daNote.isSustainNote) && (!daNote.animation.curAnim.name.endsWith('holdend')))
						cStrum.canFinishAnimation = false; // basically, make it so the animation can't be finished if there's a sustain note below
					else
						cStrum.canFinishAnimation = true;
				}
		}
	}

	private function mainControls(daNote:Note, char:Character, strumline:Strumline, autoplay:Bool):Void
	{
		var notesPressedAutoplay = [];

		// here I'll set up the autoplay functions
		if (autoplay)
		{
			// check if the note was a good hit
			if (daNote.strumTime <= Conductor.songPosition)
			{
				// use a switch thing cus it feels right idk lol
				// make sure the strum is played for the autoplay stuffs
				/*
					charStrum.forEach(function(cStrum:UIStaticArrow)
					{
						strumCallsAuto(cStrum, 0, daNote);
					});
				 */

				// kill the note, then remove it from the array
				var canDisplayJudgement = false;
				if (strumline.displayJudgements)
				{
					canDisplayJudgement = true;
					for (noteDouble in notesPressedAutoplay)
					{
						if (noteDouble.noteData == daNote.noteData)
						{
							// if (Math.abs(noteDouble.strumTime - daNote.strumTime) < 10)
							canDisplayJudgement = false;
							// removing the fucking check apparently fixes it
							// god damn it that stupid glitch with the double judgements is annoying
						}
						//
					}
					notesPressedAutoplay.push(daNote);
				}
				goodNoteHit(daNote, char, strumline, canDisplayJudgement);
			}
			//
		}

		var holdControls:Array<Bool> = [controls.LEFT, controls.DOWN, controls.UP, controls.RIGHT];
		if (!autoplay)
		{
			// check if anything is held
			if (holdControls.contains(true))
			{
				// check notes that are alive
				strumline.allNotes.forEachAlive(function(coolNote:Note)
				{
					if ((coolNote.parentNote != null && coolNote.parentNote.wasGoodHit)
						&& coolNote.canBeHit
						&& coolNote.mustPress
						&& !coolNote.tooLate
						&& coolNote.isSustainNote
						&& holdControls[coolNote.noteData])
						goodNoteHit(coolNote, char, strumline);
				});
			}
		}
	}

	override public function onFocus():Void
	{
		if (!paused)
			updateRPC(false);
		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		super.onFocusLost();
	}

	public static function updateRPC(pausedRPC:Bool)
	{
		#if discord_rpc
		var displayRPC:String = (pausedRPC) ? detailsPausedText : songDetails;

		if (PlayState.current.health > 0)
		{
			if (Conductor.songPosition > 0 && !pausedRPC)
				Discord.changePresence(displayRPC, detailsSub, iconRPC, true, songLength - Conductor.songPosition);
			else
				Discord.changePresence(displayRPC, detailsSub, iconRPC);
		}
		#end
	}

	function popUpScore(baseRating:String, isLate:Bool, strumline:Strumline, coolNote:Note)
	{
		// set up the rating
		var score:Int = 50;

		if (baseRating != "sick")
			if (allSicks)
				allSicks = false;

		displayRating(baseRating, isLate);
		Timings.updateAccuracy(Timings.judgementsMap.get(baseRating)[3]);
		score = Std.int(Timings.judgementsMap.get(baseRating)[2]);

		songScore += score;

		// popUpCombo();
	}

	function decreaseCombo(?popMiss:Bool = false)
	{
		if (combo > 0)
			combo = 0; // bitch lmao
		else
			combo--;

		// misses
		songScore -= 10;
		misses++;

		// display negative combo
		if (popMiss)
		{
			// doesnt matter miss ratings dont have timings
			// displayRating("miss", true);
			healthCall(Timings.judgementsMap.get("miss")[3]);
		}
		// popUpCombo();

		// gotta do it manually here lol
		Timings.updateFCDisplay();
	}

	function increaseCombo(?baseRating:String, ?direction = 0, ?character:Character)
	{
		// trolled this can actually decrease your combo if you get a bad/shit/miss
		if (baseRating != null)
		{
			if (Timings.judgementsMap.get(baseRating)[3] > 0)
			{
				if (combo < 0)
					combo = 0;
				combo += 1;
			}
			else
				missNoteCheck(true, direction, character, false, true);
		}
	}

	public function displayRating(daRating:String, isLate:Bool, ?cache:Bool = false)
	{
		if (Init.trueSettings.get('Simply Judgements') && comboGroup.members.length > 0)
		{
			for (sprite in comboGroup.members)
			{
				if (sprite != null)
					sprite.destroy();
				comboGroup.remove(sprite);
			}
		}

		/* so you might be asking
			"oh but if the rating isn't sick why not just reset it"
			because miss judgements can pop, and they dont mess with your sick combo
		 */

		final timing = isLate ? "late" : "early";
		var rating = ForeverAssets.generateRating('$daRating', (daRating == 'sick' ? allSicks : false), timing, assetModifier, changeableSkin, 'UI');
		if (cache)
			rating.alpha = 0.000001;
		comboGroup.add(rating);

		if (!Init.trueSettings.get('Simply Judgements'))
		{
			FlxTween.tween(rating, {alpha: 0}, 0.2, {
				onComplete: function(tween:FlxTween)
				{
					rating.destroy();
				},
				startDelay: Conductor.crochet * 0.00125
			});
		}
		else
		{
			FlxTween.tween(rating, {y: rating.y + 20}, 0.2, {
				type: FlxTweenType.BACKWARD,
				ease: FlxEase.circOut
			});
			FlxTween.tween(rating, {"scale.x": 0, "scale.y": 0}, 0.1, {
				onComplete: function(tween:FlxTween)
				{
					rating.destroy();
				},
				startDelay: Conductor.crochet * 0.00125
			});
		}
		// */

		if (!cache)
		{
			if (Init.trueSettings.get('Fixed Judgements'))
			{
				// bound to camera
				rating.camera = camHUD;
				rating.screenCenter();
			}

			// return the actual rating to the array of judgements
			Timings.gottenJudgements.set(daRating, Timings.gottenJudgements.get(daRating) + 1);

			// set new smallest rating
			if (Timings.smallestRating != daRating)
			{
				if (Timings.judgementsMap.get(Timings.smallestRating)[0] < Timings.judgementsMap.get(daRating)[0])
					Timings.smallestRating = daRating;
			}
		}
	}

	private var createdColor = FlxColor.fromRGB(204, 66, 66);

	function popUpCombo(?cache:Bool = false)
	{
		var comboString:String = Std.string(combo);
		var negative = false;
		if ((comboString.startsWith('-')) || (combo == 0))
			negative = true;
		var stringArray:Array<String> = comboString.split("");

		for (scoreInt in 0...stringArray.length)
		{
			var numScore = ForeverAssets.generateCombo('combo', stringArray[scoreInt], (!negative ? allSicks : false), assetModifier, changeableSkin, 'UI',
				negative, createdColor, scoreInt);
			if (cache)
				numScore.alpha = 0.000001;
			comboGroup.add(numScore);

			// hardcoded lmao
			if (!Init.trueSettings.get('Simply Judgements'))
			{
				FlxTween.tween(numScore, {alpha: 0}, 0.2, {
					onComplete: function(tween:FlxTween)
					{
						numScore.destroy();
					},
					startDelay: Conductor.crochet * 0.002
				});
			}
			else
			{
				// centers combo
				numScore.y += 10;
				numScore.x -= 95;
				numScore.x -= ((comboString.length - 1) * 22);
				FlxTween.tween(numScore, {y: numScore.y + 20}, 0.1, {
					type: FlxTweenType.BACKWARD,
					ease: FlxEase.circOut,
				});
			}
			// hardcoded lmao
			if (Init.trueSettings.get('Fixed Judgements'))
				numScore.y += 50;
			numScore.x += 100;
		}
	}

	function healthCall(?ratingMultiplier:Float = 0)
	{
		// health += 0.012;
		var healthBase:Float = 0.06;
		health += (healthBase * (ratingMultiplier / 100));
	}

	function startSong():Void
	{
		startingSong = false;
		previousFrameTime = FlxG.game.ticks;

		if (!paused)
		{
			songMusic.play();
			songMusic.onComplete = endSong;

			for (vocals in vocalArray)
				vocals.play();

			resyncVocals();

			#if desktop
			// Song duration in a float, useful for the time left feature
			songLength = songMusic.length;

			// Updating Discord Rich Presence (with Time Left)
			updateRPC(false);
			#end
		}
	}

	private function generateSong(dataPath:String):Void
	{
		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		songDetails = CoolUtil.dashToSpace(SONG.song);
		detailsPausedText = "Paused - " + songDetails;
		detailsSub = "";

		updateRPC(false);

		curSong = songData.song;
		songMusic = new FlxSound().loadEmbedded(Paths.inst(SONG.song), false, true);

		if (SONG.needsVoices)
		{
			vocalsP1 = new FlxSound().loadEmbedded(Paths.voices(SONG.song, opponent.curCharacter));
			vocalsP2 = new FlxSound().loadEmbedded(Paths.voices(SONG.song, boyfriend.curCharacter));

			vocalArray.push(vocalsP1);
			vocalArray.push(vocalsP2);
		}
		else
		{
			vocalsP1 = new FlxSound();
			vocalsP2 = new FlxSound();
		}

		FlxG.sound.list.add(songMusic);

		for (vocals in vocalArray)
		{
			vocals.onComplete = function()
			{
				vocalsFinished = true;
			};
			FlxG.sound.list.add(vocals);
		}

		unspawnNotes = ChartLoader.generateChartType(SONG);
		unspawnNotes.sort(sortByShit);
		generatedMusic = true;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);

	function resyncVocals():Void
	{
		if (_exiting)
			return;

		for (vocals in vocalArray)
			vocals.pause();
		songMusic.play();
		Conductor.songPosition = songMusic.time;

		if (vocalsFinished)
			return;

		for (vocals in vocalArray)
		{
			vocals.time = Conductor.songPosition;
			vocals.play();
		}
	}

	override function stepHit()
	{
		super.stepHit();
		if (songMusic.time >= Conductor.songPosition + 20 || songMusic.time <= Conductor.songPosition - 20)
			resyncVocals();
	}

	private function charactersDance(curBeat:Int)
	{
		if ((boyfriend.animation.curAnim.name.startsWith("idle") || boyfriend.animation.curAnim.name.startsWith("dance"))
			&& (curBeat % 2 == 0 || boyfriend.characterData.quickDancer))
			boyfriend.dance();

		if ((opponent.animation.curAnim.name.startsWith("idle") || opponent.animation.curAnim.name.startsWith("dance"))
			&& (curBeat % 2 == 0 || opponent.characterData.quickDancer))
			opponent.dance();
	}

	override function beatHit()
	{
		super.beatHit();

		if ((camGame.zoom < 1.35 && curBeat % 4 == 0))
		{
			// yeah
			// camGame.zoom += 0.015;
			// camHUD.zoom += 0.05;
		}

		if (SONG.notes[curBar] != null)
			if (SONG.notes[curBar].changeBPM)
				Conductor.changeBPM(SONG.notes[curBar].bpm);

		charactersDance(curBeat);

		// stage stuffs
		stageBuild.stageUpdate(curBeat, boyfriend, opponent);
	}

	// substate stuffs

	public static function resetMusic()
	{
		if (songMusic != null)
			songMusic.stop();

		for (vocals in vocalArray)
			vocals.stop();
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			songMusic.pause();
			for (vocals in vocalArray)
				vocals.pause();
		}

		// trace('open substate');
		super.openSubState(SubState);
		// trace('open substate end ');
	}

	override function closeSubState()
	{
		if (paused)
		{
			if (songMusic != null && !startingSong)
				resyncVocals();

			// resume all tweens and timers
			FlxTimer.globalManager.forEach(function(tmr:FlxTimer)
			{
				if (!tmr.finished)
					tmr.active = true;
			});

			FlxTween.globalManager.forEach(function(twn:FlxTween)
			{
				if (!twn.finished)
					twn.active = true;
			});

			paused = false;

			///*
			updateRPC(false);
			// */
		}

		Paths.clearUnusedMemory();

		super.closeSubState();
	}

	/*
		Extra functions and stuffs
	 */
	/// song end function at the end of the playstate lmao ironic I guess
	private var endSongEvent:Bool = false;

	function endSong():Void
	{
		canPause = false;
		songMusic.volume = 0;
		for (vocals in vocalArray)
			vocals.volume = 0;
		if (SONG.validScore)
			Highscore.saveScore(SONG.song, songScore);

		deaths = 0;

		Main.switchState(new MainMenuState());
	}

	private function songEndSpecificActions()
	{
		switch (SONG.song.toLowerCase())
		{
			default:
				callDefaultSongEnd();
		}
	}

	private function callDefaultSongEnd()
	{
		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;

		PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase());
		ForeverTools.killMusic([songMusic]);
		ForeverTools.killMusic(vocalArray);

		FlxG.switchState(() -> new PlayState());
	}

	var dialogueBox:DialogueBox;

	public function songIntroCutscene()
	{
		switch (curSong.toLowerCase())
		{
			default:
				callTextbox();
		}
	}

	function callTextbox()
	{
		var dialogPath = Paths.json(SONG.song.toLowerCase() + '/dialogue');
		if (sys.FileSystem.exists(dialogPath))
		{
			startedCountdown = false;

			dialogueBox = DialogueBox.createDialogue(sys.io.File.getContent(dialogPath));
			dialogueBox.camera = camAlt;
			dialogueBox.whenDaFinish = uncomfyBeginning;

			add(dialogueBox);
		}
		else
			uncomfyBeginning();
	}

	private function uncomfyBeginning():Void
	{
		inCutscene = false;
		Conductor.songPosition = -(Conductor.crochet * 20);

		camHUD.visible = true;

		new FlxTimer().start(Conductor.crochet * 0.001, function(tmr:FlxTimer) startedCountdown = true, 22); // 20 beats :sob:
	}

	override function add(Object:FlxBasic):FlxBasic
	{
		if (Init.trueSettings.get('Disable Antialiasing') && Std.isOfType(Object, FlxSprite))
			cast(Object, FlxSprite).antialiasing = false;
		return super.add(Object);
	}
}
