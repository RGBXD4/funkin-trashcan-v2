package states;

import backend.WeekData;
import backend.Highscore;
import backend.Song;

import objects.MusicPlayer;

import options.GameplayChangersSubstate;
import substates.ResetScoreSubState;

import flixel.math.FlxMath;
import flixel.util.FlxDestroyUtil;

import openfl.utils.Assets;
import flixel.addons.display.FlxBackdrop;
import openfl.utils.Assets as OpenFlAssets;

import haxe.Json;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	private static var curSelected:Int = 0;
	var lerpSelected:Float = 0;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = Difficulty.getDefault();

	var scoreText:FlxText;

	var composerText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;
	var intendedFC:String = "";

	private var curPlaying:Bool = false;

	var intendedColor:Int;

	var missingTextBG:FlxSprite;
	var missingText:FlxText;

	var bottomString:String;
	var bottomText:FlxText;
	var bottomBG:FlxSprite;

	var player:MusicPlayer;

	//actual freeplay stuff

	var bg:FlxSprite;
	var patron:FlxBackdrop;

	var left:FlxSprite;
	var right:FlxSprite;
	var arrowsGroup:FlxTypedGroup<FlxSprite>;

	var portada:FlxSprite;
	var titulo:FlxSprite;

	var fcStamp:FlxSprite;
	var sfcStamp:FlxSprite;

	var bloque:FlxSprite;
	var void:FlxSprite;

	override function create()
	{
		//Paths.clearStoredMemory();
		//Paths.clearUnusedMemory();
		
		persistentUpdate = true;
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		if(WeekData.weeksList.length < 1)
		{
			FlxTransitionableState.skipNextTransIn = true;
			persistentUpdate = false;
			MusicBeatState.switchState(new states.ErrorState("NO WEEKS ADDED FOR FREEPLAY\n\nPress ACCEPT to go to the Week Editor Menu.\nPress BACK to return to Main Menu.",
				function() MusicBeatState.switchState(new states.editors.WeekEditorState()),
				function() MusicBeatState.switchState(new states.MainMenuState())));
			return;
		}

		for (i in 0...WeekData.weeksList.length)
		{
			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var leSongs:Array<String> = [];
			var leChars:Array<String> = [];

			if(weekIsLocked(WeekData.weeksList[i])) continue;

			for (j in 0...leWeek.songs.length)
			{
				leSongs.push(leWeek.songs[j][0]);
				leChars.push(leWeek.songs[j][1]);
			}

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2];
				if(colors == null || colors.length < 3)
				{
					colors = [146, 113, 253];
				}
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]), song[3]);
			}
		}
		Mods.loadTopMod();
		Mods.currentModDirectory = songs[curSelected].folder;

		bg = new FlxSprite().loadGraphic(Paths.image('menu/freeplayshit/bg'));
		//bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.scrollFactor.set(0);
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.data.antialiasing;
		add(bg);

        patron = new FlxBackdrop(Paths.image('menu/patron'));
		patron.alpha = 0.5;
		patron.setGraphicSize(Std.int(patron.width * 0.5));
		patron.scrollFactor.set();
		patron.velocity.set(-80, -80);
		add(patron);

        var barras:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menu/freeplayshit/barra'));
	    barras.screenCenter();
		barras.antialiasing = ClientPrefs.data.antialiasing;
		add(barras);

		right = new FlxSprite(1150, 0);
        right.frames = Paths.getSparrowAtlas('menu/freeplayshit/flecha_champeada');
		right.scale.set(0.5, 0.5);
		right.screenCenter(Y);
		right.scrollFactor.set(0);
        right.antialiasing = true;
        right.animation.addByPrefix('idle', 'Flecha', 30, true);
		right.animation.addByPrefix('push', 'flecha select', 30, true);
        right.animation.play('idle');
        
		left = new FlxSprite(5, 0);
        left.frames = Paths.getSparrowAtlas('menu/freeplayshit/flecha_champeada');
        left.scale.set(0.5, 0.5);
		left.screenCenter(Y);
        left.flipX = true;
		left.scrollFactor.set(0);
        left.antialiasing = true;
        left.animation.addByPrefix('idle', 'Flecha', 30, true);
		left.animation.addByPrefix('push', 'flecha select', 30, true);
        left.animation.play('idle');

		add(left);
		add(right);

		void = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		void.alpha = 0;
		add(void);

		bloque = new FlxSprite().loadGraphic(Paths.image('menu/freeplayshit/bloque'));
		bloque.screenCenter();
		bloque.scale.set(0.65,0.65);
		bloque.antialiasing = ClientPrefs.data.antialiasing;
		add(bloque);

		portada = new FlxSprite(40,10);
		changePortrait(songs[curSelected].songName, lastDifficultyName);
		portada.scale.set(0.6, 0.6);
		portada.antialiasing = ClientPrefs.data.antialiasing;
		portada.screenCenter(Y);
		add(portada);
		trace('portrait y: ' + portada.y);

		titulo = new FlxSprite(525,90);
		if (!Paths.fileExists('images/menu/freeplayshit/titulos/' + songs[curSelected].songName + '.png', IMAGE))	titulo.loadGraphic(Paths.lifeIsLikeAVideoGame('titulos/${songs[curSelected].songName}'));	
		else	titulo.loadGraphic(Paths.image('menu/freeplayshit/titulos/' + songs[curSelected].songName));
		titulo.scale.set(0.7, 0.7);
		titulo.antialiasing = ClientPrefs.data.antialiasing;
		add(titulo);

		fcStamp = new FlxSprite(350, -250);
        fcStamp.frames = Paths.getSparrowAtlas('menu/freeplayshit/Sello FC');
        fcStamp.antialiasing = ClientPrefs.data.antialiasing;
        fcStamp.animation.addByPrefix('fc', 'Full Combo Stamp', 24, false);
		fcStamp.animation.addByPrefix('onlyStamp', 'Stamp', 24, false);
		fcStamp.animation.play('fc');
		fcStamp.visible = false;
		add(fcStamp);

		sfcStamp = new FlxSprite(350, -250);
        sfcStamp.frames = Paths.getSparrowAtlas('menu/freeplayshit/Sello PC');
        sfcStamp.antialiasing = ClientPrefs.data.antialiasing;
        sfcStamp.animation.addByPrefix('fc', 'Full Combo Stamp', 24, false);
		sfcStamp.animation.addByPrefix('onlyStamp', 'Stamp', 24, false);
		sfcStamp.animation.play('fc');
		sfcStamp.visible = false;
		add(sfcStamp);

		arrowsGroup = new FlxTypedGroup<FlxSprite>();
		add(arrowsGroup);

		for (i in 0...2) { //i didnt make this for horizontal arrows bc i didnt want to
			var vertArrow = new FlxSprite(315, 0);
			vertArrow.frames = Paths.getSparrowAtlas('menu/freeplayshit/flecha_champeada');
			vertArrow.scale.set(0.5, 0.5);
			vertArrow.scrollFactor.set(0);
			vertArrow.antialiasing = true;
			vertArrow.animation.addByPrefix('idle', 'Flecha', 30, true);
			vertArrow.animation.addByPrefix('push', 'flecha select', 30, true);
			vertArrow.alpha = 0;
			vertArrow.animation.play('idle');
			switch (i) {
				case 0: 
					vertArrow.angle = -90;	//up arrow
					vertArrow.y = 25;
				case 1: 
					vertArrow.angle = 90;	//down arrow
					vertArrow.y = 535;
			}
			arrowsGroup.add(vertArrow);
		}

		WeekData.setDirectoryFromWeek();

		composerText = new FlxText(675, 400, 0, "By: Skibidi Sigma Pomni", 32);
		composerText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, LEFT);

		scoreText = new FlxText(composerText.x, 475, 0, "sonic!", 32);
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);

		add(scoreText);
		add(composerText);

		missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		missingTextBG.alpha = 0.6;
		missingTextBG.visible = false;
		add(missingTextBG);
		
		missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
		missingText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingText.scrollFactor.set();
		missingText.visible = false;
		add(missingText);

		if(curSelected >= songs.length) curSelected = 0;
		bg.color = songs[curSelected].color;
		intendedColor = bg.color;
		lerpSelected = curSelected;
		
		player = new MusicPlayer(this);
		add(player);
		
		updateTexts();
		super.create();
	}

	override function closeSubState()
	{
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int, author:String)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color, author));
	}

	function weekIsLocked(name:String):Bool
	{
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	var instPlaying:Int = -1;
	public static var vocals:FlxSound = null;
	public static var opponentVocals:FlxSound = null;
	var holdTime:Float = 0;

	var stopMusicPlay:Bool = false;

	var arrowLEFTTween:FlxTween;
	var arrowRIGHTTween:FlxTween;

	var diffTrigger:Bool = false;
	override function update(elapsed:Float)
	{
		if(WeekData.weeksList.length < 1)
			return;

		if (FlxG.sound.music.volume < 0.7)
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;

		lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 24)));
		lerpRating = FlxMath.lerp(intendedRating, lerpRating, Math.exp(-elapsed * 12));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		intendedFC = Highscore.getFC(songs[curSelected].songName, curDifficulty);

		var ratingSplit:Array<String> = Std.string(CoolUtil.floorDecimal(lerpRating * 100, 2)).split('.');
		if(ratingSplit.length < 2) //No decimals, add an empty space
			ratingSplit.push('');
		
		while(ratingSplit[1].length < 2) //Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;
		
		var arrowUPTween:FlxTween;
		var arrowDOWNTween:FlxTween;
		if (!player.playingMusic)
		{
			scoreText.text = 'Score: $lerpScore';
			composerText.text = 'By: ${songs[curSelected].author}';
			positionHighscore();
			
			if(songs.length > 1 && !diffTrigger)
			{
				if(FlxG.keys.justPressed.HOME)
				{
					curSelected = 0;
					changeSelection();
					holdTime = 0;	
				}
				else if(FlxG.keys.justPressed.END)
				{
					curSelected = songs.length - 1;
					changeSelection();
					holdTime = 0;	
				}
				if (controls.UI_LEFT_P)
				{
					if (arrowLEFTTween != null)	arrowLEFTTween.cancel();
					left.animation.play('push');

					arrowLEFTTween = FlxTween.tween(left,{x: -15},0.15,{ease:FlxEase.cubeIn,onComplete: function(twn:FlxTween)
					{
						FlxTween.tween(left,{x: 5},0.15,{ease:FlxEase.cubeOut});
						left.animation.play('idle');
					}});

					changeSelection(-shiftMult);
					holdTime = 0;
				}
				if (controls.UI_RIGHT_P)
				{
					if (arrowRIGHTTween != null)	arrowRIGHTTween.cancel();
					right.animation.play('push');

					arrowRIGHTTween = FlxTween.tween(right,{x: 1160},0.15,{ease:FlxEase.cubeIn,onComplete: function(twn:FlxTween)
					{
						FlxTween.tween(right,{x: 1150},0.15,{ease:FlxEase.cubeOut});
						right.animation.play('idle');
					}});

					changeSelection(shiftMult);
					holdTime = 0;
				}

				if(controls.UI_LEFT || controls.UI_RIGHT)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_RIGHT ? -shiftMult : shiftMult));
				}

				if(FlxG.mouse.wheel != 0)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
					changeSelection(-shiftMult * FlxG.mouse.wheel, false);
				}
			}
			else if(diffTrigger)
			{
				if (controls.UI_UP_P)
				{
					changeDiff(-1);
					_updateSongLastDifficulty();
					if (arrowLEFTTween != null)	arrowLEFTTween.cancel();
					arrowsGroup.members[0].animation.play('push');

					arrowLEFTTween = FlxTween.tween(arrowsGroup.members[0],{y: 5},0.15,{ease:FlxEase.cubeIn,onComplete: function(twn:FlxTween)
					{
						FlxTween.tween(arrowsGroup.members[0],{y: 25},0.15,{ease:FlxEase.cubeOut});
						arrowsGroup.members[0].animation.play('idle');
					}});

				}
				if (controls.UI_DOWN_P)
				{
					var down = arrowsGroup.members[1];
					if (arrowRIGHTTween != null)	arrowRIGHTTween.cancel();
					down.animation.play('push');

					arrowRIGHTTween = FlxTween.tween(down,{y: 550},0.15,{ease:FlxEase.cubeIn,onComplete: function(twn:FlxTween)
					{
						FlxTween.tween(down,{y: 535},0.15,{ease:FlxEase.cubeOut});
						down.animation.play('idle');
					}});
					changeDiff(1);
					_updateSongLastDifficulty();
				}

			}
		}

		if (controls.BACK)
		{
			if (player.playingMusic)
			{
				FlxG.sound.music.stop();
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;
				instPlaying = -1;

				player.playingMusic = false;
				player.switchPlayMusic();

				FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);
				FlxTween.tween(FlxG.sound.music, {volume: 1}, 1);
			}
			else if (diffTrigger)
			{
				new FlxTimer().start(0.05, function (tmr:FlxTimer) {
					diffTrigger = false;
					for (tilin in arrowsGroup) FlxTween.tween(tilin,{alpha: 0},0.15,{ease:FlxEase.bounceIn});
					trace('diff changer disabled.');
				});
				FlxTween.tween(void,{alpha: 0},0.15,{ease:FlxEase.cubeOut});
				FlxG.sound.play(Paths.sound('cancelMenu'));
			}
			else 
			{
				persistentUpdate = false;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
			}
		}

		if(FlxG.keys.justPressed.CONTROL && !player.playingMusic)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
		}

		else if(controls.ACCEPT && Difficulty.list.length > 1 && !player.playingMusic && !diffTrigger)
		{
			FlxTween.tween(void,{alpha: 0.75},0.15,{ease:FlxEase.cubeOut});
			new FlxTimer().start(0.05, function (tmr:FlxTimer) {
				diffTrigger = true;
				changeDiff(0, false);
				trace('change the diff.');
			});

			for (tilin in arrowsGroup) FlxTween.tween(tilin,{alpha: 1},0.15,{ease:FlxEase.bounceIn});
			FlxTween.tween(void,{alpha: 0.75},0.15,{ease:FlxEase.cubeOut});
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}

		else if (controls.ACCEPT && !player.playingMusic || controls.ACCEPT && diffTrigger)	{
			persistentUpdate = false;
			var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
			var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
	
			try
			{
				Song.loadFromJson(poop, songLowercase);
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = curDifficulty;
	
				trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
			}
			catch(e:haxe.Exception)
			{
				trace('ERROR! ${e.message}');
	
				var errorStr:String = e.message;
				if(errorStr.contains('There is no TEXT asset with an ID of')) errorStr = 'Missing file: ' + errorStr.substring(errorStr.indexOf(songLowercase), errorStr.length-1); //Missing chart
				else errorStr += '\n\n' + e.stack;
	
				missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
				missingText.screenCenter(Y);
				missingText.visible = true;
				missingTextBG.visible = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
	
				updateTexts(elapsed);
				super.update(elapsed);
				return;
			}
			trace('Playing $poop');
			startSong();
		}

		else if(controls.RESET && !player.playingMusic)
		{
			persistentUpdate = false;
			openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}

		updateTexts(elapsed);
		super.update(elapsed);
	}
	
	function getVocalFromCharacter(char:String)
	{
		try
		{
			var path:String = Paths.getPath('characters/$char.json', TEXT);
			#if MODS_ALLOWED
			var character:Dynamic = Json.parse(File.getContent(path));
			#else
			var character:Dynamic = Json.parse(Assets.getText(path));
			#end
			return character.vocals_file;
		}
		catch (e:Dynamic) {}
		return null;
	}

	function startSong() {
		LoadingState.prepareToSong();
		LoadingState.loadAndSwitchState(new PlayState());
		#if !SHOW_LOADING_SCREEN FlxG.sound.music.stop(); #end
		stopMusicPlay = true;

		destroyFreeplayVocals();
		#if (MODS_ALLOWED && DISCORD_ALLOWED)
		DiscordClient.loadModRPC();
		#end
	}
	public static function destroyFreeplayVocals() {
		if(vocals != null) vocals.stop();
		vocals = FlxDestroyUtil.destroy(vocals);

		if(opponentVocals != null) opponentVocals.stop();
		opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
	}

	function changeDiff(change:Int = 0, playSound:Bool = true)
	{
		if (player.playingMusic)
			return;

		//if (playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curDifficulty = FlxMath.wrap(curDifficulty + change, 0, Difficulty.list.length-1);
		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		intendedFC = Highscore.getFC(songs[curSelected].songName, curDifficulty);
		#end

		lastDifficultyName = Difficulty.getString(curDifficulty, false);
		var displayDiff:String = Difficulty.getString(curDifficulty);

		if (diffTrigger) {
			//fc thing for difficulties
			fcStampChecker(intendedFC, true);
		
			//change portrait but dificultado
			changePortrait(songs[curSelected].songName, displayDiff);				
			
		}
		
		positionHighscore();
		missingText.visible = false;
		missingTextBG.visible = false;
	}

	var coolTween:FlxTween;
	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if (player.playingMusic)
			return;

		curSelected = FlxMath.wrap(curSelected + change, 0, songs.length-1);

		_updateSongLastDifficulty();

		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		var newColor:Int = songs[curSelected].color;
		if(newColor != intendedColor)
		{
			intendedColor = newColor;
			FlxTween.cancelTweensOf(bg);
			FlxTween.color(bg, 1, bg.color, intendedColor);
		}

		Mods.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;
		Difficulty.loadFromWeek();
		trace('current mod directory: ${Mods.currentModDirectory}');
		
		var savedDiff:String = songs[curSelected].lastDifficulty;
		var lastDiff:Int = Difficulty.list.indexOf(lastDifficultyName);
		if(savedDiff != null && !Difficulty.list.contains(savedDiff) && Difficulty.list.contains(savedDiff))
			curDifficulty = Math.round(Math.max(0, Difficulty.list.indexOf(savedDiff)));
		else if(lastDiff > -1)
			curDifficulty = lastDiff;
		else if(Difficulty.list.contains(Difficulty.getDefault()))
			curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
		else
			curDifficulty = 0;

		var displayDiff:String = Difficulty.getString(curDifficulty);

		if (!diffTrigger) {
			changeDiff();
			_updateSongLastDifficulty();

			changePortrait(songs[curSelected].songName, displayDiff);
			changeTitle(songs[curSelected].songName);
			fcStampChecker(intendedFC, playSound);
		}
	}

	function changePortrait(newPortada:String, curDiff:String = "")
	{
		#if MODS_ALLOWED
		if (!Paths.fileExists('images/menu/freeplayshit/portraits/' + newPortada + '.png', IMAGE)) { //si no hay portada en assets
			if (!FileSystem.exists(Paths.mods(Mods.currentModDirectory + '/images/covers/$newPortada.png'))) {
				portada.loadGraphic(Paths.image('menu/freeplayshit/portraits/null como el del mod de zink'));
				trace('couldnt find portrait in "${Paths.mods(Mods.currentModDirectory + '/images/covers/$newPortada')}!');
			}
			else {
				if (Difficulty.list.length > 1 && curDiff != "Normal")	portada.loadGraphic(Paths.lifeIsLikeAVideoGame('covers/${newPortada} $curDiff'));
				else	portada.loadGraphic(Paths.lifeIsLikeAVideoGame('covers/${newPortada}'));	//se carga la que esta en mods!	
			}
		}
		else {
			if (Difficulty.list.length > 1)	portada.loadGraphic(Paths.image('menu/freeplayshit/portraits/${newPortada} $curDiff'));	
			else portada.loadGraphic(Paths.image('menu/freeplayshit/portraits/' + newPortada));
			trace('portrait loaded: "menu/freeplayshit/portraits/' + newPortada + '"');
		}
		#end
	}

	function changeTitle(newTitle:String)
		{
			#if MODS_ALLOWED
			if (!Paths.fileExists('images/menu/freeplayshit/titulos/' + newTitle + '.png', IMAGE))	
				if (!FileSystem.exists(Paths.mods(Mods.currentModDirectory + '/images/titulos/$newTitle.png'))) titulo.loadGraphic(Paths.image('menu/freeplayshit/titulos/mario'));
				else titulo.loadGraphic(Paths.lifeIsLikeAVideoGame('titulos/${newTitle}'));	
			else
				titulo.loadGraphic(Paths.image('menu/freeplayshit/titulos/' + newTitle));
			#end
		}

	function fcStampChecker(typeFC:String, playSound:Bool = true) 
	{
		if (intendedFC == "" || intendedFC == "SDCB" || intendedFC == "Clear") {
			trace('malo qliao askjajks ($intendedFC)');
			fcStamp.visible = false;
			sfcStamp.visible = false;
		}
		else {
			if (intendedFC == "SFC") {
				fcStamp.visible = false;
				sfcStamp.visible = true;

				sfcStamp.animation.finish();
				if (playSound) sfcStamp.animation.play('onlyStamp');
				else sfcStamp.animation.play('fc');
			}
			else {
				fcStamp.visible = true;
				sfcStamp.visible = false;

				fcStamp.animation.finish();
				if (playSound) fcStamp.animation.play('onlyStamp');
				else fcStamp.animation.play('fc');
			}
				
			trace('buenardo ($intendedFC)');
		}
	}
	inline private function _updateSongLastDifficulty() songs[curSelected].lastDifficulty = Difficulty.getString(curDifficulty, false);
	private function positionHighscore()	return;
	

	var _drawDistance:Int = 4;
	var _lastVisibles:Array<Int> = [];
	public function updateTexts(elapsed:Float = 0.0) return;

	override function destroy():Void
	{
		super.destroy();

		FlxG.autoPause = ClientPrefs.data.autoPause;
		if (!FlxG.sound.music.playing && !stopMusicPlay)
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
	}	
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var author:String = "";
	public var color:Int = -7179779;
	public var folder:String = "";
	public var lastDifficulty:String = null;

	public function new(song:String, week:Int, songCharacter:String, color:Int, author:String)
	{
		this.songName = song;
		this.week = week;
		this.author = author;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Mods.currentModDirectory;
		if(this.folder == null) this.folder = '';
	}
}
