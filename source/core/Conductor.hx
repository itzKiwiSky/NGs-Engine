package core;

import core.Song.SwagSong;

// Represents a BPM change event during playback
typedef BPMChangeEvent = {
	var stepTime:Int;     // Step index when the BPM change occurs
	var songTime:Float;  // Time in ms when the BPM change occurs
	var bpm:Float;       // BPM value at this step
}

class Conductor {
	public static var safeFrames:Int = 10;
	public static var safeZoneOffset:Float = Math.floor((safeFrames / 60) * 1000);
	public static var timeScale:Float = safeZoneOffset / 166;

	public static var bpmChangeMap:Array<BPMChangeEvent> = [];
	public static var bpm:Float = 100;
	public static var crochet:Float = (60 / bpm) * 1000;
	public static var stepCrochet:Float = crochet / 4;

	public static var songPosition:Float = 0;
	public static var lastSongPos:Float = 0;
	public static var offset:Float = 0;

	/**
	 * Recalculate timing values based on safe frames.
	 */
	public static function recalculateTimings() {
		if (FlxG.save != null && FlxG.save.data != null && FlxG.save.data.frames != null)
			safeFrames = FlxG.save.data.frames;

		safeZoneOffset = Math.floor((safeFrames / 60) * 1000);
		timeScale = safeZoneOffset / 166;
	}

	public static function mapBPMChanges(song:SwagSong) {
		bpmChangeMap = [];
		var curBPM:Float = song.bpm;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;
		for (i in 0...song.notes.length) {
			if (song.notes[i].changeBPM && song.notes[i].bpm != curBPM) {
				curBPM = song.notes[i].bpm;
				var event:BPMChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM
				};
				bpmChangeMap.push(event);
			}

			var deltaSteps:Int = song.notes[i].lengthInSteps;
			totalSteps += deltaSteps;
			totalPos += ((60 / curBPM) * 1000 / 4) * deltaSteps;
		}
		trace("new BPM map BUDDY " + bpmChangeMap);
	}

	/**
	 * Changes the global BPM and recalculates beat durations.
	 */
	public static function newBpm(newBpm:Float, ?recalcLength = true) {
		bpm = newBpm;
		crochet = (60 / bpm) * 1000;
		stepCrochet = crochet / 4;
	}
}