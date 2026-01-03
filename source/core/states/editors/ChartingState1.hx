package core.states.editors;

import core.Section.SwagSection;
import objects.Note;
import core.Song.SwagSong;
import flixel.addons.display.FlxGridOverlay;

/*class ChartingState extends BeatState {
	public static var _song:SwagSong;

	override function create() {
		FlxG.mouse.visible = true;
		TimingStruct.clear();

		if (Core.song != null)
			_song = Core.song; 
		else {
			_song = {
				id: new Map(),
				diff: new Map()
			};
		}

		super.create();
	}

	override function update(elapsed:Float) {
		super.update(elapsed);

		if (FlxG.keys.justPressed.SPACE) {
			if (FlxG.sound.music != null) {
				if (FlxG.sound.music.playing)
					FlxG.sound.music.pause();
				else
					FlxG.sound.music.play();
			}
		}
	}
}*/

import lime.app.Application;
#if sys
import sys.io.File;
#end
import flixel.FlxObject;
//import Conductor.BPMChangeEvent;
//import Section.SwagSection;
import flixel.group.FlxGroup;
//import flixel.system.FlxSound;
import flixel.ui.FlxButton;
import haxe.Json;
import lime.utils.Assets;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.net.FileReference;
import openfl.utils.ByteArray;

class ChartingState extends BeatState {
	public var deezNuts:Map<Int, Int> = new Map<Int, Int>(); // snap conversion map KE
	public static var instance:ChartingState;
	public static var _song:SwagSong;
	var curSong = 'Tutorial';
	var curDiff = 'normal';

	public static var lengthInSteps = 0.0;
	public static var lengthInBeats = 0.0;
	public static var lastSection = 0;
	public var beatsShown = 1.0; // for the zoom factor
	public var zoomFactor = 0.4;
	public var playClaps = false;
	var subDivisions = 1.0;
	var defaultSnap = true;
	public var snap = 16;
	var amountSteps = 0;
	var daSpacing = 0.3;
	var curSection = 0;
	var GRID_SIZE = 40;
	var tempBpm = 0.0;
	var height = 0;

	public var sectionRenderes:FlxTypedGroup<SectionRender>;
	var curRenderedSustains:FlxTypedGroup<FlxSprite>;
	var curRenderedNotes:FlxTypedGroup<Note>;
	var lines:FlxTypedGroup<FlxSprite>;
	var curSelectedNote:Array<Dynamic>; // WILL BE THE CURRENT / LAST PLACED NOTE
	var writingNotesText:FlxText;
	var gridBlackLine:FlxSprite;
	public var snapText:FlxText;
	var dummyArrow:FlxSprite;
	var bullshitUI:FlxGroup;
	var strumLine:FlxSprite;
	var highlight:FlxSprite;
	var gridBG:FlxSprite;
	var bpmTxt:FlxText;
	var lastNote:Note;
	var claps:Array<Note> = [];

	var player2 = 'dad'; // Character = new Character(0,0, "dad");
	var player1 = 'bf'; // Boyfriend = new Boyfriend(0,0, "bf");
	public static var leftIcon:FlxSprite; // HealthIcon;
	public static var rightIcon:FlxSprite; // HealthIcon;
	var vocals:FlxSound;

	var _file:FileReference;
	var camFollow:FlxObject;

	override function create() {
		curSection = lastSection;
		FlxG.mouse.visible = true;

		instance = this;

		deezNuts.set(4,1);
		deezNuts.set(8,2);
		deezNuts.set(12,3);
		deezNuts.set(16,4);
		deezNuts.set(24,6);
		deezNuts.set(32,8);
		deezNuts.set(64,16);


		sectionRenderes = new FlxTypedGroup<SectionRender>();
		lines = new FlxTypedGroup<FlxSprite>();
		texts = new FlxTypedGroup<FlxText>();

		TimingStruct.clear();
		if (Core.song != null)
			_song = Core.song;
		else {
			_song = {
				chartVersion: '',
				stage: '',
				noteStyle: '',
				song: "tutorial",
				diff: [],
				bpm: 100,
				speed: 1,
				players: ['bf', 'dad', ''],
				validThing: [true, true]
			};
		}
		addGrid(1);

		//if (_song.chartVersion == null)
			//_song.chartVersion = "2";

		snapText = new FlxText(60, 10, 0, "", 14);
		snapText.scrollFactor.set();

		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedSustains = new FlxTypedGroup<FlxSprite>();
		FlxG.mouse.visible = true;

		tempBpm = _song.bpm;
		addSection();

		//loadSong(_song.song);
		//Conductor.newBpm(_song.bpm);
		Conductor.mapBPMChanges(_song);

		//leftIcon = new HealthIcon(_song.player1);
		//rightIcon = new HealthIcon(_song.player2);

		var index = 0;
		//if (_song.eventObjects == null)
			//_song.eventObjects = [new Song.Event("Init BPM", 0, _song.bpm, "BPM Change")];

		//if (_song.eventObjects.length == 0)
			//_song.eventObjects = [new Song.Event("Init BPM", 0, _song.bpm, "BPM Change")];
	
		var currentIndex = 0;
		/*for (i in _song.eventObjects) {
			var name = Reflect.field(i,"name");
			var type = Reflect.field(i,"type");
			var pos = Reflect.field(i,"position");
			var value = Reflect.field(i,"value");
			if (type == "BPM Change") {
                var beat:Float = pos;
                var endBeat:Float = Math.POSITIVE_INFINITY;
                TimingStruct.addTiming(beat, value, endBeat, 0);
                if (currentIndex != 0) {
                    var data = TimingStruct.AllTimings[currentIndex - 1];
                    data.endBeat = beat;
                    data.length = (data.endBeat - data.startBeat) / (data.bpm / 60);
					var step = ((60 / data.bpm) * 1000) / 4;
					TimingStruct.AllTimings[currentIndex].startStep = Math.floor(((data.endBeat / (data.bpm / 60)) * 1000) / step);
					TimingStruct.AllTimings[currentIndex].startTime = data.startTime + data.length;
                }
				currentIndex++;
			}
		}*/

		var lastSeg = TimingStruct.AllTimings[TimingStruct.AllTimings.length - 1];
		for (i in 0...TimingStruct.AllTimings.length) {
			var seg = TimingStruct.AllTimings[i];
			if (i == TimingStruct.AllTimings.length - 1)	
				lastSeg = seg;
		}
		recalculateAllSectionTimes();
		trace("Song length in MS: " + FlxG.sound.music.length);

		for (i in 0...9000000) {
			var seg = TimingStruct.getTimingAtBeat(i);
			var start:Float = (i - seg.startBeat) / (seg.bpm / 60);
			var time = (seg.startTime + start) * 1000;
			if (time > FlxG.sound.music.length)
				break;
			lengthInBeats = i;
		}
		lengthInSteps = lengthInBeats * 4;
		trace('LENGTH IN STEPS ' + lengthInSteps + ' | LENGTH IN BEATS ' + lengthInBeats + ' | SECTIONS: ' + Math.floor(((lengthInSteps + 16)) / 16));

		var sections = Math.floor(((lengthInSteps + 16)) / 16);
		var targetY = getYfromStrum(FlxG.sound.music.length);

		/*for (awfgaw in 0...Math.round(targetY / 640) + 1920) {
			var renderer = new SectionRender(0, 640 * awfgaw,GRID_SIZE);
			if (_song.notes[awfgaw] == null)
				_song.notes.push(newSection(16, true, false, false));
			renderer.section = _song.notes[awfgaw];
			sectionRenderes.add(renderer);

			var down = getYfromStrum(renderer.section.startTime) * zoomFactor;
			var sectionicon = _song.notes[awfgaw].mustHitSection ? new HealthIcon(_song.player1).clone() : new HealthIcon(_song.player2).clone();
			sectionicon.x = -95;
			sectionicon.y = down - 75;
			sectionicon.setGraphicSize(0, 45);
		
			renderer.icon = sectionicon;
			renderer.lastUpdated = _song.notes[awfgaw].mustHitSection;
			add(sectionicon);
			height = Math.floor(renderer.y);
		}*/
		gridBlackLine = new FlxSprite(gridBG.width / 2).makeGraphic(2, height, FlxColor.BLACK);

		leftIcon.setGraphicSize(0, 45);
		rightIcon.setGraphicSize(0, 45);
		add(leftIcon);
		add(rightIcon);

		leftIcon.setPosition(0, -100);
		rightIcon.setPosition(gridBG.width / 2, -100);

		leftIcon.scrollFactor.set();
		rightIcon.scrollFactor.set();

		bpmTxt = new FlxText(1000, 50, 0, "", 16);
		bpmTxt.scrollFactor.set();
		add(bpmTxt);

		strumLine = new FlxSprite(0, 0).makeGraphic(Std.int(GRID_SIZE * 8), 4);
		dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE);
		regenerateLines();
		updateGrid();
		add(sectionRenderes);

		// fuckin stupid ass bitch ass fucking waveform
		/*if (PlayState.isSM)
		{
			waveform = new Waveform(0,0,PlayState.pathToSm + "/" + PlayState.sm.header.MUSIC,height);
		}
		else
		{
			if (_song.needsVoices)
				waveform = new Waveform(0,0,Paths.voices(_song.song),height);
			else
				waveform = new Waveform(0,0,Paths.inst(_song.song),height);
		}

		waveform.drawWaveform();
		add(waveform);
		*/
		add(dummyArrow);
		add(strumLine);
		add(lines);
		add(texts);
		add(gridBlackLine);
		add(curRenderedNotes);
		add(curRenderedSustains);

		selectedBoxes = new FlxTypedGroup();
		add(selectedBoxes);
		add(snapText);

		TimingStruct.clear();
		var currentIndex = 0;
		/*for (i in _song.eventObjects) {
			if (i.type == "BPM Change") {
                var beat:Float = i.position;
                var endBeat:Float = Math.POSITIVE_INFINITY;
                TimingStruct.addTiming(beat, i.value,endBeat, 0)
                if (currentIndex != 0) {
                    var data = TimingStruct.AllTimings[currentIndex - 1];
                    data.endBeat = beat;
                    data.length = (data.endBeat - data.startBeat) / (data.bpm / 60);
					var step = ((60 / data.bpm) * 1000) / 4;
					TimingStruct.AllTimings[currentIndex].startStep = Math.floor(((data.endBeat / (data.bpm / 60)) * 1000) / step);
					TimingStruct.AllTimings[currentIndex].startTime = data.startTime + data.length;
                }
				currentIndex++;
			}
		}*/
		super.create();
	}

	public var texts:FlxTypedGroup<FlxText>;
	function regenerateLines() {
		while (lines.members.length > 0) {
			lines.members[0].destroy();
			lines.members.remove(lines.members[0]);
		}

		while (texts.members.length > 0) {
			texts.members[0].destroy();
			texts.members.remove(texts.members[0]);
		}
		trace("removed lines and texts");

		/*if (_song.eventObjects != null)
			for(i in _song.eventObjects) {
				var seg = TimingStruct.getTimingAtBeat(i.position);
				var posi:Float = 0;
				if (seg != null) {
					var start:Float = (i.position - seg.startBeat) / (seg.bpm / 60);
					posi = seg.startTime + start;
				}

				var pos = getYfromStrum(posi * 1000) * zoomFactor;
				if (pos < 0)
					pos = 0;

				var type = i.type;
				var text = new FlxText(-190, pos, 0, i.name + "\n" + type + "\n" + i.value, 12);
				var line = new FlxSprite(0, pos).makeGraphic(Std.int(GRID_SIZE * 8), 4, FlxColor.BLUE);
				line.alpha = 0.2;
				lines.add(line);
				texts.add(text);
				
				add(line);
				add(text);
			}*/

		for (i in sectionRenderes) {
			var pos = getYfromStrum(i.section.startTime) * zoomFactor;
			i.icon.y = pos - 75;
			var line = new FlxSprite(0, pos).makeGraphic(Std.int(GRID_SIZE * 8), 4, FlxColor.BLACK);
			line.alpha = 0.4;
			lines.add(line);
		}
	}

	function addGrid(?divisions:Float) {
		var h = GRID_SIZE / divisions ?? 1.0;
		if (Math.floor(h) != h)
			h = GRID_SIZE;

		remove(gridBG);
		gridBG = FlxGridOverlay.create(GRID_SIZE, Std.int(h), GRID_SIZE * 8, GRID_SIZE * 16);
		trace(gridBG.height);
		//gridBG.scrollFactor.set();
		//gridBG.x += 358;
		//gridBG.y += 390;
		trace("height of " + (Math.floor(lengthInSteps)));


		/*for(i in 0...Math.floor(lengthInSteps))
		{
			trace("Creating sprite " + i);
			var grid = FlxGridOverlay.create(GRID_SIZE, Std.int(h), GRID_SIZE * 8, GRID_SIZE * 16);
			add(grid);
			if (i > lengthInSteps)
				break;
		}*/

		var totalHeight = 0;

		//add(gridBG);

		
		remove(gridBlackLine);
		gridBlackLine = new FlxSprite(0 + gridBG.width / 2).makeGraphic(2, Std.int(Math.floor(lengthInSteps)), FlxColor.BLACK);
		add(gridBlackLine);
	}

	var currentSelectedEventName:String = "";
	var savedType:String = "";
	var savedValue:String = "";
	var currentEventPosition:Float = 0;

	function goToSection(section:Int) {
		var beat = section * 4;
		var data = TimingStruct.getTimingAtBeat(beat);

		if (data == null)
			return;

		FlxG.sound.music.time = (data.startTime + ((beat - data.startBeat) / (data.bpm / 60))) * 1000;
		//vocals.time = FlxG.sound.music.time;
		curSection = section;
		trace("Going too " + FlxG.sound.music.time + " | " + section + " | Which is at " + beat);

		if (FlxG.sound.music.time < 0)
			FlxG.sound.music.time = 0;
		else if (FlxG.sound.music.time > FlxG.sound.music.length)
			FlxG.sound.music.time = FlxG.sound.music.length;
	}
	

	var currentDiffName = 'normal';
	function pasteNotesFromArray(array:Array<Array<Dynamic>>, fromStrum = true) {
		for (i in array) {
			var strum:Float = i[0];
			if (fromStrum)
				strum += Conductor.songPosition;
			var section = 0;
			for (ii in _song.notes) {
				if (ii.startTime <= strum && ii.endTime > strum) {
					trace("new strum " + strum + " - at section " + section);
					var newData = [strum, i[1], i[2]];
					ii.sectionNotes.push(newData);

					var thing = ii.sectionNotes[ii.sectionNotes.length - 1];
					var note:Note = new Note(strum, Math.floor(i[1] % 4), null, false, true);
					note.rawNoteData = i[1];
					note.sustainLength = i[2];
					note.setGraphicSize(Math.floor(GRID_SIZE), Math.floor(GRID_SIZE));
					note.updateHitbox();
					note.x = Math.floor(i[1] * GRID_SIZE);
					note.charterSelected = true;
					note.y = Math.floor(getYfromStrum(strum) * zoomFactor);

					var box = new ChartingBox(note.x, note.y, note);
					box.connectedNoteData = thing;
					selectedBoxes.add(box);
					curRenderedNotes.add(note);
					pastedNotes.push(note);

					if (note.sustainLength > 0) {
						var sustainVis:FlxSprite = new FlxSprite(note.x + (GRID_SIZE / 2),
						 	note.y + GRID_SIZE).makeGraphic(8, Math.floor((getYfromStrum(note.strumTime + note.sustainLength) * zoomFactor) - note.y));
							note.noteCharterObject = sustainVis;	
							curRenderedSustains.add(sustainVis);
					}
					trace("section new length: " + ii.sectionNotes.length);
					continue;
				}
				section++;
			}
		}
	}

	function loadSong(daSong:String):Void {
		if (FlxG.sound.music != null) {
			FlxG.sound.music.stop();
			// vocals.stop();
		}
		//FlxG.sound.playMusic(Paths.inst(daSong), 0.6);
	//	vocals = new FlxSound().loadEmbedded(Paths.voices(daSong));
		FlxG.sound.list.add(vocals);

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.onComplete = function() {
			vocals.pause();
			FlxG.sound.music.pause();
		};
	}

	var updatedSection:Bool = false;
	

	function stepStartTime(step):Float
		return Conductor.bpm / (step / 4) / 60;

	function sectionStartTime(?customIndex = -1):Float {
		if (customIndex == -1)
			customIndex = curSection;
		var daBPM:Float = Conductor.bpm;
		var daPos:Float = 0;
		for (i in 0...customIndex)
			daPos += 4 * (1000 * 60 / daBPM);
		return daPos;
	}

	var writingNotes:Bool = false;
	var doSnapShit:Bool = false;
	
	public var diff:Float = 0;

	public var changeIndex = 0;

	public var currentBPM:Float = 0;
	public var lastBPM:Float = 0;

	public var updateFrame = 0;
	public var lastUpdatedSection:SwagSection = null;

	public function resizeEverything()
		regenerateLines();

	public var shownNotes:Array<Note> = [];

	public var snapSelection = 3;

	public var selectedBoxes:FlxTypedGroup<ChartingBox>;

	public var waitingForRelease:Bool = false;
	public var selectBox:FlxSprite;

	public var copiedNotes:Array<Array<Dynamic>> = [];
	public var pastedNotes:Array<Note> = [];
	public var deletedNotes:Array<Array<Dynamic>> = [];

	public var selectInitialX:Float = 0;
	public var selectInitialY:Float = 0;

	public var lastAction:String = "";

	override function update(elapsed:Float) {
		updateHeads();
		for (i in sectionRenderes) {
			var diff = i.y - strumLine.y;
			if (diff < 4000 && diff >= -4000) {
				i.active = true;
				i.visible = true;
			} else {
				i.active = false;
				i.visible = false;
			}
		}
		shownNotes = [];

		/*for (note in curRenderedNotes) {
			var diff = note.strumTime - Conductor.songPosition;
			if (diff < 8000 && diff >= -8000) {
				shownNotes.push(note);
				note.y = getYfromStrum(note.strumTime) * zoomFactor;
				if (note.sustainLength > 0) {
					if (note.noteCharterObject != null)
					if (note.noteCharterObject.y != note.y + GRID_SIZE) {
						note.noteCharterObject.y = note.y + GRID_SIZE;
						note.noteCharterObject.makeGraphic(8,Math.floor((getYfromStrum(note.strumTime + note.sustainLength) * zoomFactor) - note.y),FlxColor.WHITE);
					}
				}
				note.active = true;
				note.visible = true;
			} else {
				note.active = false;
				note.visible = false;
			}
		}*/

		for (ii in selectedBoxes.members) {
			ii.x = ii.connectedNote.x;
			ii.y = ii.connectedNote.y;
		}

		var doInput = true;
		if (doInput) {
			if (FlxG.mouse.wheel != 0) {
				FlxG.sound.music.pause();
				vocals.pause();
				claps.splice(0, claps.length);

				if (FlxG.keys.pressed.CONTROL && !waitingForRelease) {
					var amount = FlxG.mouse.wheel;
					if (amount > 0)
						amount = 0;

					var increase:Float = 0;
					if (amount < 0)
						increase = -0.02;
					else
						increase = 0.02;

					zoomFactor += increase;
					if (zoomFactor > 2)
						zoomFactor = 2;

					if (zoomFactor < 0.1)
						zoomFactor = 0.1;

						resizeEverything();
				} else {
					var amount = FlxG.mouse.wheel;
					if (amount > 0 && strumLine.y < 0)
						amount = 0;
	
					if (doSnapShit) {
						var increase:Float = 0;
						var beats:Float = 0;
						if (amount < 0) {
							increase = 1 / deezNuts.get(snap);
							beats = (Math.floor((curDecimalBeat * deezNuts.get(snap)) + 0.001) / deezNuts.get(snap)) + increase;
						} else {
							increase = -1 / deezNuts.get(snap);
							beats = ((Math.ceil(curDecimalBeat * deezNuts.get(snap)) - 0.001) / deezNuts.get(snap)) + increase;
						}
						trace("SNAP - " + snap + " INCREASE - " + increase + " - GO TO BEAT " + beats);
	
						var data = TimingStruct.getTimingAtBeat(beats);
						if (beats <= 0)
							FlxG.sound.music.time = 0;
	
						var bpm = data != null ? data.bpm : _song.bpm;
						if (data != null)
							FlxG.sound.music.time = (data.startTime + ((beats - data.startBeat) / (bpm/60)) ) * 1000;
					} else
						FlxG.sound.music.time -= (FlxG.mouse.wheel * Conductor.stepCrochet * 0.4);

					if (FlxG.sound.music.time > FlxG.sound.music.length)
						FlxG.sound.music.time = FlxG.sound.music.length;
					vocals.time = FlxG.sound.music.time;
				}
			}
			if (FlxG.keys.justPressed.RIGHT && !FlxG.keys.pressed.CONTROL)
				goToSection(curSection + 1);
			else if (FlxG.keys.justPressed.LEFT && !FlxG.keys.pressed.CONTROL)
				goToSection(curSection - 1);

			if (FlxG.mouse.pressed && FlxG.keys.pressed.CONTROL) {
				if (!waitingForRelease) {
					trace("creating select box");
					waitingForRelease = true;
					selectBox = new FlxSprite(FlxG.mouse.x,FlxG.mouse.y);
					selectBox.makeGraphic(0,0,FlxColor.fromRGB(173, 216, 230));
					selectBox.alpha = 0.4;

					selectInitialX = selectBox.x;
					selectInitialY = selectBox.y;

					add(selectBox);
				} else {
					if (waitingForRelease) {
						trace(selectBox.width + " | " + selectBox.height);
						selectBox.x = Math.min(FlxG.mouse.x,selectInitialX);
						selectBox.y = Math.min(FlxG.mouse.y,selectInitialY);
						
						selectBox.makeGraphic(Math.floor(Math.abs(FlxG.mouse.x - selectInitialX)),Math.floor(Math.abs(FlxG.mouse.y - selectInitialY)),FlxColor.fromRGB(173, 216, 230));
					}
				}
			}
			if (FlxG.mouse.justReleased && waitingForRelease) {
				trace("released!");
				waitingForRelease = false;

				while (selectedBoxes.members.length != 0 && selectBox.width > 10 && selectBox.height > 10) {
					selectedBoxes.members[0].connectedNote.charterSelected = false;
					selectedBoxes.members[0].destroy();
					selectedBoxes.members.remove(selectedBoxes.members[0]);
				}

				for (i in curRenderedNotes) {
					if (i.overlaps(selectBox) && !i.charterSelected) {
						trace("seleting " + i.strumTime);
						selectNote(i, false);
					}
				}
				selectBox.destroy();
				remove(selectBox);
			}

			if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.D) {
				lastAction = "delete";
				var notesToBeDeleted = [];
				deletedNotes = [];
				for (i in 0...selectedBoxes.members.length) {
					deletedNotes.push([selectedBoxes.members[i].connectedNote.strumTime,selectedBoxes.members[i].connectedNote.rawNoteData,selectedBoxes.members[i].connectedNote.sustainLength]);
					notesToBeDeleted.push(selectedBoxes.members[i].connectedNote);
				}

				for (i in notesToBeDeleted)
					deleteNote(i);
			}

			if (FlxG.keys.justPressed.DELETE) {
				lastAction = "delete";
				var notesToBeDeleted = [];
				deletedNotes = [];
				for (i in 0...selectedBoxes.members.length) {
					deletedNotes.push([selectedBoxes.members[i].connectedNote.strumTime,selectedBoxes.members[i].connectedNote.rawNoteData,selectedBoxes.members[i].connectedNote.sustainLength]);
					notesToBeDeleted.push(selectedBoxes.members[i].connectedNote);
				}

				for (i in notesToBeDeleted)
					deleteNote(i);
			}
			
			if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.C) {
				if (selectedBoxes.members.length != 0) {
					copiedNotes = [];
					for (i in selectedBoxes.members)
						copiedNotes.push([i.connectedNote.strumTime,i.connectedNote.rawNoteData,i.connectedNote.sustainLength,i.connectedNote.isAlt]);

					var firstNote = copiedNotes[0][0];
					for (i in copiedNotes) { // normalize the notes
						i[0] = i[0] - firstNote;
						trace("Normalized time: " + i[0] + " | " + i[1]);
					}
					trace(copiedNotes.length);
				}
			}
	
			if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.V) {
				if (copiedNotes.length != 0) {
					while (selectedBoxes.members.length != 0) {
						selectedBoxes.members[0].connectedNote.charterSelected = false;
						selectedBoxes.members[0].destroy();
						selectedBoxes.members.remove(selectedBoxes.members[0]);
					}
					trace("Pasting " + copiedNotes.length);
					pasteNotesFromArray(copiedNotes);
					lastAction = "paste";
				}
			}

			if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Z) {
				switch (lastAction) {
					case "paste":
						trace("undo paste");
						if (pastedNotes.length != 0) {
							for(i in pastedNotes) {
								if (curRenderedNotes.members.contains(i))
									deleteNote(i);
							}
							pastedNotes = [];
						}
					case "delete":
						trace("undoing delete");
						if (deletedNotes.length != 0) {
							trace("undoing delete");
							pasteNotesFromArray(deletedNotes,false);
							deletedNotes = [];
						}
				}
			}
		}

		/*if (updateFrame == 4) {
			TimingStruct.clear();
			var currentIndex = 0;
			for (i in _song.eventObjects) {
				if (i.type == "BPM Change") {
					var beat:Float = i.position;
					var endBeat:Float = Math.POSITIVE_INFINITY;
					TimingStruct.addTiming(beat,i.value,endBeat, 0); // offset in this case = start time since we don't have a offset
					if (currentIndex != 0) {
						var data = TimingStruct.AllTimings[currentIndex - 1];
						data.endBeat = beat;
						data.length = (data.endBeat - data.startBeat) / (data.bpm / 60);
						var step = ((60 / data.bpm) * 1000) / 4;
						TimingStruct.AllTimings[currentIndex].startStep = Math.floor(((data.endBeat / (data.bpm / 60)) * 1000) / step);
						TimingStruct.AllTimings[currentIndex].startTime = data.startTime + data.length;
					}
					currentIndex++;
				}
			}
			recalculateAllSectionTimes();
			regenerateLines();
			updateFrame++;
		} else if (updateFrame != 5)
			updateFrame++;*/
		snapText.text = "Snap: 1/" + snap + " (" + (doSnapShit ? "Shift to disable, CTRL Left or Right to increase/decrease" : "Snap Disabled, Shift to renable.") + ")\nAdd Notes: 1-8 (or click)\nZoom: " + zoomFactor;
		if (FlxG.keys.justPressed.RIGHT && FlxG.keys.pressed.CONTROL) {
			snapSelection++;
			var index = 6;
			if (snapSelection > 6)
				snapSelection = 6;
			if (snapSelection < 0)
				snapSelection = 0;
			for (v in deezNuts.keys()) {
				trace(v);
				if (index == snapSelection) {
					trace("found " + v + " at " + index);
					snap = v;
				}
				index--;
			}
			trace("new snap " + snap + " | " + snapSelection);
		}

		if (FlxG.keys.justPressed.LEFT && FlxG.keys.pressed.CONTROL) {
			snapSelection--;
			if (snapSelection > 6)
				snapSelection = 6;
			if (snapSelection < 0)
				snapSelection = 0;
			var index = 6;
			for (v in deezNuts.keys()) {
				trace(v);
				if (index == snapSelection) {
					trace("found " + v + " at " + index);
					snap = v;
				}
				index--;
			 }
			trace("new snap " + snap + " | " + snapSelection);
		}

		if (FlxG.keys.justPressed.SHIFT)
			doSnapShit = !doSnapShit;
		
		doSnapShit = defaultSnap;
		if (FlxG.keys.pressed.SHIFT)
			doSnapShit = !defaultSnap;

		Conductor.songPosition = FlxG.sound.music.time;
		_song.song = '';//typingShit.text;

		
		var timingSeg = TimingStruct.getTimingAtTimestamp(Conductor.songPosition);
		var start = Conductor.songPosition;
		if (timingSeg != null) {
			var timingSegBpm = timingSeg.bpm;
			currentBPM = timingSegBpm;
			if (currentBPM != Conductor.bpm) {
				trace("BPM CHANGE to " + currentBPM);
				Conductor.newBpm(currentBPM, false);
			}
			var pog:Float = (curDecimalBeat - timingSeg.startBeat) / (Conductor.bpm / 60);
			start = (timingSeg.startTime + pog) * 1000;
		}

		
		var weird = getSectionByTime(start, true);
		FlxG.watch.addQuick("Section",weird);

		strumLine.y = getYfromStrum(start) * zoomFactor;
		camFollow.y = strumLine.y;

		bpmTxt.text = Std.string(FlxMath.roundDecimal(Conductor.songPosition / 1000, 2))
		+ " / "
		+ Std.string(FlxMath.roundDecimal(FlxG.sound.music.length / 1000, 2))
		+ "\nCur Section: "
		+ curSection
		+ "\nCurBPM: " 
		+ currentBPM
		+ "\nCurBeat: " 
		/*+ HelperFunctions.truncateFloat(curDecimalBeat,3)*/
		+ "\nCurStep: "
		+ curStep
		+ "\nZoom: "
		/*+ HelperFunctions.truncateFloat(zoomFactor,2)*/;

		var left = FlxG.keys.justPressed.ONE;
		var down = FlxG.keys.justPressed.TWO;
		var up = FlxG.keys.justPressed.THREE;
		var right = FlxG.keys.justPressed.FOUR;
		var leftO = FlxG.keys.justPressed.FIVE;
		var downO = FlxG.keys.justPressed.SIX;
		var upO = FlxG.keys.justPressed.SEVEN;
		var rightO = FlxG.keys.justPressed.EIGHT;

		var pressArray = [left, down, up, right, leftO, downO, upO, rightO];
		var delete = false;
		if (doInput) {
			curRenderedNotes.forEach(function(note:Note) {
				if (strumLine.overlaps(note) && pressArray[Math.floor(Math.abs(note.noteData))]) {
					deleteNote(note);
					delete = true;
					trace('deelte note');
				}
			});
			for (p in 0...pressArray.length) {
				var i = pressArray[p];
				if (i && !delete)
					addNote(new Note(Conductor.songPosition,p));
			}
		}

		if (playClaps) {
			for (note in shownNotes) {
				if (note.strumTime <= Conductor.songPosition && !claps.contains(note) && FlxG.sound.music.playing) {
					claps.push(note);
					FlxG.sound.play(Paths.sound('SNAP'));
				}
			}
		}
		FlxG.watch.addQuick('daBeat', curDecimalBeat);
		if (FlxG.mouse.justPressed && !waitingForRelease) {
			if (FlxG.mouse.overlaps(curRenderedNotes)) {
				curRenderedNotes.forEach(function(note:Note) {
					if (FlxG.mouse.overlaps(note)) {
						if (FlxG.keys.pressed.CONTROL)
							selectNote(note, false);
						else
							deleteNote(note);
					}
				});
			} else {
				if (FlxG.mouse.x > 0 && FlxG.mouse.x < 0 + gridBG.width
					&& FlxG.mouse.y > 0 && FlxG.mouse.y < 0 + height) {
					FlxG.log.add('added note');
					addNote();
				}
			}
		}

		if (FlxG.mouse.x > 0 && FlxG.mouse.x < gridBG.width
			&& FlxG.mouse.y > 0 && FlxG.mouse.y < height) {
			dummyArrow.visible = true;
			dummyArrow.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;
			dummyArrow.y = (Math.floor(FlxG.mouse.y / (GRID_SIZE / deezNuts.get(snap))) * (GRID_SIZE / deezNuts.get(snap)));
		} else
			dummyArrow.visible = false;

		if (doInput) {
			if (FlxG.keys.justPressed.ENTER) {
				lastSection = curSection;

				//PlayState.SONG = _song;
				FlxG.sound.music.stop();
				vocals.stop();
				//changeState(PlayState);
			}
			if (FlxG.keys.justPressed.E)
				changeNoteSustain(((60 / (timingSeg != null ? timingSeg.bpm : _song.bpm)) * 1000) / 4);
			if (FlxG.keys.justPressed.Q)
				changeNoteSustain(-(((60 / (timingSeg != null ? timingSeg.bpm : _song.bpm)) * 1000) / 4));

			/*if (FlxG.keys.justPressed.C && !FlxG.keys.pressed.CONTROL) {
				var sect = _song.notes[curSection];
				sect.mustHitSection = !sect.mustHitSection;
				var i = sectionRenderes.members[curSection];
				var cachedY = i.icon.y;
				remove(i.icon);
				var sectionicon = sect.mustHitSection ? new HealthIcon(_song.player1).clone() : new HealthIcon(_song.player2).clone();
				sectionicon.x = -95;
				sectionicon.y = cachedY;
				sectionicon.setGraphicSize(0, 45);
				i.icon = sectionicon;
				i.lastUpdated = sect.mustHitSection;
				add(sectionicon);
				trace("must hit " + sect.mustHitSection);
			}*/
			if (FlxG.keys.justPressed.V && !FlxG.keys.pressed.CONTROL) {
				trace("swap");
				var secit = _song.notes[curSection];
				if (secit != null) {
					var newSwaps:Array<Array<Dynamic>> = [];
					trace(secit);
					for (i in 0...secit.sectionNotes.length) {
						var note = secit.sectionNotes[i];
						if (note[1] < 4)
							note[1] += 4;
						else
							note[1] -= 4;
						newSwaps.push(note);
					}
					secit.sectionNotes = newSwaps;
					for (i in shownNotes) {
						for (ii in newSwaps)
							if (i.strumTime == ii[0] && i.noteData == ii[1] % 4) {
								i.x = Math.floor(ii[1] * GRID_SIZE);
								i.y = Math.floor(getYfromStrum(ii[0]) * zoomFactor);
								if (i.sustainLength > 0 && i.noteCharterObject != null)
									i.noteCharterObject.x = i.x + (GRID_SIZE / 2);
							}
					}
				}
			}
			if (false/*!typingShit.hasFocus*/) {
				var shiftThing:Int = 1;
				if (FlxG.keys.pressed.SHIFT)
					shiftThing = 4;
				if (FlxG.keys.justPressed.SPACE) {
					if (FlxG.sound.music.playing) {
						FlxG.sound.music.pause();
						vocals.pause();
						claps.splice(0, claps.length);
					} else {
						vocals.play();
						FlxG.sound.music.play();
					}
				}
				if (FlxG.sound.music.time < 0 || curDecimalBeat < 0)
					FlxG.sound.music.time = 0;

				if (!FlxG.keys.pressed.SHIFT) {
					if (FlxG.keys.pressed.W || FlxG.keys.pressed.S) {
						FlxG.sound.music.pause();
						vocals.pause();
						claps.splice(0, claps.length);
						var daTime:Float = 700 * FlxG.elapsed;

						if (FlxG.keys.pressed.W)
							FlxG.sound.music.time -= daTime;
						else
							FlxG.sound.music.time += daTime;
						vocals.time = FlxG.sound.music.time;
					}
				} else {
					if (FlxG.keys.justPressed.W || FlxG.keys.justPressed.S) {
						FlxG.sound.music.pause();
						vocals.pause();
						var daTime:Float = Conductor.stepCrochet * 2;
						if (FlxG.keys.justPressed.W)
							FlxG.sound.music.time -= daTime;
						else
							FlxG.sound.music.time += daTime;
						vocals.time = FlxG.sound.music.time;
					}
				}
			}
		}
		_song.bpm = tempBpm;
		super.update(elapsed);
	}

	function changeNoteSustain(value:Float):Void {
		if (curSelectedNote != null) {
			if (curSelectedNote[2] != null) {
				curSelectedNote[2] += value;
				curSelectedNote[2] = Math.max(curSelectedNote[2], 0);
				if (curSelectedNoteObject.noteCharterObject != null)
					curRenderedSustains.remove(curSelectedNoteObject.noteCharterObject);

				var sustainVis = new FlxSprite(curSelectedNoteObject.x + (GRID_SIZE / 2),
				curSelectedNoteObject.y + GRID_SIZE).makeGraphic(8, Math.floor((getYfromStrum(curSelectedNoteObject.strumTime + curSelectedNote[2]) * zoomFactor) - curSelectedNoteObject.y));
				curSelectedNoteObject.sustainLength = curSelectedNote[2];
				trace("new sustain " + curSelectedNoteObject.sustainLength);
				curSelectedNoteObject.noteCharterObject = sustainVis;
				curRenderedSustains.add(sustainVis);
			}
		}
		updateNoteUI();
	}

	function resetSection(songBeginning = false):Void {
		FlxG.sound.music.pause();
		vocals.pause();
		FlxG.sound.music.time = 0;
		vocals.time = FlxG.sound.music.time;
		updateGrid();
		//if (!songBeginning)
			//updateSectionUI();
	}

	function changeSection(sec = 0, ?updateMusic = true):Void {
		trace('changing section' + sec);
		if (_song.notes[sec] != null) {
			trace('naw im not null');
			curSection = sec;
			updateGrid();
			if (updateMusic) {
				FlxG.sound.music.pause();
				vocals.pause();
				FlxG.sound.music.time = sectionStartTime();
				vocals.time = FlxG.sound.music.time;
				updateCurStep();
			}
			updateGrid();
			//updateSectionUI();
		} else
			trace('bro wtf I AM NULL');
	}

	function copySection(?sectionNum = 1) {
		var daSec = FlxMath.maxInt(curSection, sectionNum);
		var sect = lastUpdatedSection;
		if (sect == null)
			return;

		var song = _song.notes;
		for (note in song[daSec - sectionNum].sectionNotes) {
			var strum = note[0] + Conductor.stepCrochet * (song[daSec].lengthInSteps * sectionNum);
			var copiedNote:Array<Dynamic> = [strum, note[1], note[2],note[3]];
			sect.sectionNotes.push(copiedNote);
		}
		updateGrid();
	}

	function updateHeads():Void {
		/*if (check_mustHitSection.checked) {
			leftIcon.animation.play(_song.player1);
			rightIcon.animation.play(_song.player2);
		} else {
			leftIcon.animation.play(_song.player2);
			rightIcon.animation.play(_song.player1);
		}*/
	}

	function updateNoteUI():Void {
		/*if (curSelectedNote != null)
		{
			stepperSusLength.value = curSelectedNote[2];
			if (curSelectedNote[3] != null)
				check_naltAnim.checked = curSelectedNote[3];
			else
			{
				curSelectedNote[3] = false;
				check_naltAnim.checked = false;
			}
		}*/
	}

	function updateGrid():Void {
		while (curRenderedNotes.members.length > 0)
			curRenderedNotes.remove(curRenderedNotes.members[0], true);

		while (curRenderedSustains.members.length > 0)
			curRenderedSustains.remove(curRenderedSustains.members[0], true);

		var currentSection = 0;
		for (section in _song.notes) {
			for (i in section.sectionNotes) {
				var seg = TimingStruct.getTimingAtTimestamp(i[0]);
				var daNoteInfo = i[1];
				var daStrumTime = i[0];
				var daSus = i[2];

				var note:Note = new Note(daStrumTime, daNoteInfo % 4,null,false,true,i[3]);
				note.rawNoteData = daNoteInfo;
				note.sustainLength = daSus;
				note.setGraphicSize(Math.floor(GRID_SIZE), Math.floor(GRID_SIZE));
				note.updateHitbox();
				note.x = Math.floor(daNoteInfo * GRID_SIZE);
				note.y = Math.floor(getYfromStrum(daStrumTime) * zoomFactor);
				if (curSelectedNote != null)
					if (curSelectedNote[0] == note.strumTime)
						lastNote = note;
				curRenderedNotes.add(note);

				var stepCrochet = (((60 / seg.bpm) * 1000) / 4);
				if (daSus > 0) {
					var sustainVis:FlxSprite = new FlxSprite(note.x + (GRID_SIZE / 2),
						note.y + GRID_SIZE).makeGraphic(8, Math.floor((getYfromStrum(note.strumTime + note.sustainLength) * zoomFactor) - note.y));
					note.noteCharterObject = sustainVis;
					curRenderedSustains.add(sustainVis);
				}
			}
			currentSection++;	
		}
	}

	private function addSection(lengthInSteps = 16):Void {
		var daPos:Float = 0;
		var start:Float = 0;
		var bpm = _song.bpm;
		for (i in 0...curSection) {
			for (ii in TimingStruct.AllTimings) {
				var data = TimingStruct.getTimingAtTimestamp(start);
				if ((data != null ? data.bpm : _song.bpm) != bpm && bpm != ii.bpm)
					bpm = ii.bpm;
			}
			start += (4 * (60 / bpm)) * 1000;
		}

		var sec:SwagSection = {
			sectionNotes: [],
			startTime: daPos,
			endTime: Math.POSITIVE_INFINITY,
			bpm: _song.bpm,
			changeBPM: false,
			typeOfSection: 0,
			lengthInSteps: lengthInSteps,
			mustHitSection: true,
			altAnim: false,
			isP1Alt: false,
			isP2Alt: false
		};
		_song.notes.push(sec);
	}

	function selectNote(note:Note, ?deleteAllBoxes = true):Void {
		var swagNum:Int = 0;
		if (deleteAllBoxes)
			while (selectedBoxes.members.length != 0) {
				selectedBoxes.members[0].connectedNote.charterSelected = false;
				selectedBoxes.members[0].destroy();
				selectedBoxes.members.remove(selectedBoxes.members[0]);
			}
		for (sec in _song.notes) {
			swagNum = 0;
			for (i in sec.sectionNotes) {
				if (i[0] == note.strumTime && i[1] == note.rawNoteData) {
					curSelectedNote = sec.sectionNotes[swagNum];
					if (curSelectedNoteObject != null)
						curSelectedNoteObject.charterSelected = false;
					curSelectedNoteObject = note;
					if (!note.charterSelected) {
						var box = new ChartingBox(note.x,note.y,note);
						box.connectedNoteData = i;
						selectedBoxes.add(box);
						note.charterSelected = true;
						curSelectedNoteObject.charterSelected = true;
					}
				}
				swagNum += 1;
			}
		}
		updateNoteUI();
	}

	function deleteNote(note:Note):Void {
		lastNote = note;
		var section = getSectionByTime(note.strumTime);
		var found = false;
		for (i in section.sectionNotes) {
			if (i[0] == note.strumTime && i[1] == note.rawNoteData) {
				section.sectionNotes.remove(i);
				found = true;
			}
		}

		if (!found) {
			for (i in _song.notes) {
				for (n in i.sectionNotes)
					if (n[0] == note.strumTime && n[1] == note.rawNoteData)
						i.sectionNotes.remove(n);
			}
		}
		curRenderedNotes.remove(note);
		if (note.sustainLength > 0)
			curRenderedSustains.remove(note.noteCharterObject);

		for (i in 0...selectedBoxes.members.length) {
			var box = selectedBoxes.members[i];
			if (box.connectedNote == note) {
				selectedBoxes.members.remove(box);
				box.destroy();
				return;
			}
		}
	}

	function clearSection():Void {
		getSectionByTime(Conductor.songPosition).sectionNotes = [];
		updateGrid();
	}

	function clearSong():Void {
		var song = _song.notes;
		for (daSection in 0...song.length)
			song[daSection].sectionNotes = [];
		updateGrid();
	}

	private function newSection(lengthInSteps:Int = 16, mustHitSection:Bool = false, p1AltAnim:Bool = true, p2AltAnim:Bool = true):SwagSection {
		var daPos:Float = 0;		
		var currentSeg = TimingStruct.AllTimings[TimingStruct.AllTimings.length - 1];
		var currentBeat = 4;
		for (i in _song.notes)
			currentBeat += 4;

		if (currentSeg == null)
			return null;

		var start:Float = (currentBeat - currentSeg.startBeat) / (currentSeg.bpm / 60);
		daPos = (currentSeg.startTime + start) * 1000;
		var sec:SwagSection = {
			sectionNotes: [],
			startTime: daPos,
			endTime: Math.POSITIVE_INFINITY,
			bpm: _song.bpm,
			changeBPM: false,
			typeOfSection: 0,
			lengthInSteps: lengthInSteps,
			mustHitSection: mustHitSection,
			altAnim: false,
			isP1Alt: p1AltAnim,
			isP2Alt: p2AltAnim
		};
		return sec;
	}

	function recalculateAllSectionTimes() {
		trace("RECALCULATING SECTION TIMES");
		var song = _song.notes;
		for (i in 0...song.length) {
			var section = song[i];
			var currentBeat = 4 * i;
			var currentSeg = TimingStruct.getTimingAtBeat(currentBeat);
			if (currentSeg == null)
				return;
			var start:Float = (currentBeat - currentSeg.startBeat) / (currentSeg.bpm / 60);
			section.startTime = (currentSeg.startTime + start) * 1000;
			if (i != 0)
				song[i - 1].endTime = section.startTime;
			section.endTime = Math.POSITIVE_INFINITY;
		}
		once = true;
	}

	var once = false;
	function shiftNotes(measure = 0, step = 0, ms = 0):Void {
		var newSong = [];
		var millisecadd = (((measure * 4) + step / 4) * (60000 / currentBPM)) + ms;
		var totaladdsection = Std.int((millisecadd / (60000 / currentBPM) / 4));
		trace(millisecadd,totaladdsection);
		if (millisecadd > 0) {
			for (i in 0...totaladdsection)
				newSong.unshift(newSection());
		}
		var song = _song.notes;
		for (daSection1 in 0...song.length)
			newSong.push(newSection(16,song[daSection1].mustHitSection, song[daSection1].isP1Alt, song[daSection1].isP2Alt));
	
		for (daSection in 0...(song.length)) {
			var aimtosetsection = daSection+Std.int((totaladdsection));
			if(aimtosetsection < 0) aimtosetsection = 0;
			newSong[aimtosetsection].mustHitSection = song[daSection].mustHitSection;
			newSong[aimtosetsection].isP1Alt = song[daSection].isP1Alt;
			newSong[aimtosetsection].isP2Alt = song[daSection].isP2Alt;
			for (daNote in 0...(song[daSection].sectionNotes.length)) {	
				var newtiming = song[daSection].sectionNotes[daNote][0]+millisecadd;
				if (newtiming < 0)
					newtiming = 0;
					var futureSection = Math.floor(newtiming / 4 / (60000 / currentBPM));
					song[daSection].sectionNotes[daNote][0] = newtiming;
					newSong[futureSection].sectionNotes.push(song[daSection].sectionNotes[daNote]);
				}
	
		}
		song = newSong;
		recalculateAllSectionTimes();
		updateGrid();
		updateNoteUI();
	}

	public function getSectionByTime(ms:Float, ?changeCurSectionIndex = false):SwagSection {
		var index = 0;
		for (i in _song.notes) {
			if (ms >= i.startTime && ms < i.endTime) {
				if (changeCurSectionIndex)
					curSection = index;
				return i;
			}
			index++;
		}
		return null;
	}

	public function getNoteByTime(ms:Float) {
		for (i in _song.notes) {
			for (n in i.sectionNotes)
				if (n[0] == ms)
					return i;
		}
		return null;
	}

	public var curSelectedNoteObject:Note = null;
	private function addNote(?n:Note):Void {
		var strum = getStrumTime(dummyArrow.y) / zoomFactor;
		trace(strum + " from " + dummyArrow.y);
		trace("adding note with " + strum + " from dummyArrow");

		var section = getSectionByTime(strum);
		if (section == null)
			return;

		var noteStrum = strum;
		var noteData = Math.floor(FlxG.mouse.x / GRID_SIZE);
		var noteSus = 0;
		if (n != null)
			section.sectionNotes.push([n.strumTime, n.noteData, n.sustainLength, false]);
		else
			section.sectionNotes.push([noteStrum, noteData, noteSus, false]);

		var thingy = section.sectionNotes[section.sectionNotes.length - 1];
		curSelectedNote = thingy;
		var seg = TimingStruct.getTimingAtTimestamp(noteStrum);
		if (n == null) {
			var note = new Note(noteStrum, noteData % 4,null,false,true);
			note.rawNoteData = noteData;
			note.sustainLength = noteSus;
			note.setGraphicSize(Math.floor(GRID_SIZE), Math.floor(GRID_SIZE));
			note.updateHitbox();
			note.x = Math.floor(noteData * GRID_SIZE);

			if (curSelectedNoteObject != null)
				curSelectedNoteObject.charterSelected = false;
			curSelectedNoteObject = note;
			while (selectedBoxes.members.length != 0) {
				selectedBoxes.members[0].connectedNote.charterSelected = false;
				selectedBoxes.members[0].destroy();
				selectedBoxes.members.remove(selectedBoxes.members[0]);
			}
			curSelectedNoteObject.charterSelected = true;

			note.y = Math.floor(getYfromStrum(noteStrum) * zoomFactor);
			var box = new ChartingBox(note.x,note.y,note);
			box.connectedNoteData = thingy;
			selectedBoxes.add(box);
			curRenderedNotes.add(note);
		} else {
			var note = new Note(n.strumTime, n.noteData % 4,null,false,true, n.isAlt);
			note.rawNoteData = n.noteData;
			note.sustainLength = noteSus;
			note.setGraphicSize(Math.floor(GRID_SIZE), Math.floor(GRID_SIZE));
			note.updateHitbox();
			note.x = Math.floor(n.noteData * GRID_SIZE);

			if (curSelectedNoteObject != null)
				curSelectedNoteObject.charterSelected = false;
			curSelectedNoteObject = note;
			while(selectedBoxes.members.length != 0) {
				selectedBoxes.members[0].connectedNote.charterSelected = false;
				selectedBoxes.members[0].destroy();
				selectedBoxes.members.remove(selectedBoxes.members[0]);
			}

			var box = new ChartingBox(note.x,note.y,note);
			box.connectedNoteData = thingy;
			selectedBoxes.add(box);
			curSelectedNoteObject.charterSelected = true;
			note.y = Math.floor(getYfromStrum(n.strumTime) * zoomFactor);
			curRenderedNotes.add(note);
		}
		updateNoteUI();
		autosaveSong();
	}

	function getStrumTime(yPos:Float):Float
		return FlxMath.remapToRange(yPos, 0, lengthInSteps, 0, lengthInSteps);

	function getYfromStrum(strumTime:Float):Float
		return FlxMath.remapToRange(strumTime, 0, lengthInSteps, 0, lengthInSteps);

	function loadLevel():Void
		trace(_song.notes);

	function getNotes():Array<Dynamic> {
		var noteData:Array<Dynamic> = [];
		for (i in _song.notes)
			noteData.push(i.sectionNotes);
		return noteData;
	}

	function loadJson(song:String):Void {
		/*var difficultyArray:Array<String> = ["-easy", "", "-hard"];
		var format = StringTools.replace(PlayState.SONG.song.toLowerCase(), " ", "-");
		switch (format) {
			case 'Dad-Battle': format = 'Dadbattle';
			case 'Philly-Nice': format = 'Philly';
		}*/
		//PlayState.SONG = Song.loadFromJson(format + difficultyArray[PlayState.storyDifficulty], format);
		//LoadingState.loadAndSwitchState(new ChartingState());
	}

	function loadAutosave():Void {
		//Core.song = Song.parseJSONshit(FlxG.save.data.autosave);
		//LoadingState.loadAndSwitchState(new ChartingState());
	}

	function autosaveSong():Void {
		FlxG.save.data.autosave = Json.stringify({
			"song": _song
		});
		FlxG.save.flush();
	}

	private function saveLevel() {
		var difficultyArray:Array<String> = ["-easy", "", "-hard"];
		var json = {
			"song": _song
		};
		var data:String = Json.stringify(json,null," ");
		if ((data != null) && (data.length > 0)) {
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(''/*data.trim(), _song.song.toLowerCase() + difficultyArray[PlayState.storyDifficulty] + ".json"*/);
		}
	}

	function onSaveComplete(_):Void {
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */	
	function onSaveCancel(_):Void {
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void {
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
	}
}