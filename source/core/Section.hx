package core;

typedef SwagSection = {
	var sectionNotes:Array<Array<Dynamic>>;
	var startTime:Float;
	var endTime:Float;
	var bpm:Float;
	var changeBPM:Bool;
	var typeOfSection:Int;
	var lengthInSteps:Int;
	var mustHitSection:Bool;
	var altAnim:Bool;
	var isP1Alt:Bool;
	var isP2Alt:Bool;
}

class Section {
	public var sectionNotes:Array<Array<Dynamic>> = [];
	public var startTime = 0.0;
	public var endTime = 0.0;
	public var bpm = 0.0;
	public var changeBPM = false;
	public var typeOfSection = 0;
	public var lengthInSteps = 16;
	public var mustHitSection = false;

	public static var COPYCAT = 0;
	public function new(lengthInSteps = 16)
		this.lengthInSteps = lengthInSteps;
}