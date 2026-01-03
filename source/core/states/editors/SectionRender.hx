package core.states.editors;

import flixel.addons.display.FlxGridOverlay;

class SectionRender extends FlxSprite {
	public var section:core.Section.SwagSection;
    public var icon:FlxSprite;
    public var lastUpdated:Bool;

    public function new(x:Float, y:Float, GRID_SIZE:Int, ?Height = 16) {
        super(x,y);
        makeGraphic(GRID_SIZE * 8, GRID_SIZE * Height,0xffe7e6e6);

		if (FlxG.save.data.editorBG == null)
			FlxG.save.data.editorBG = true;

		var h = GRID_SIZE;
		if (Math.floor(h) != h)
			h = GRID_SIZE;

        if (FlxG.save.data.editorBG)
            FlxGridOverlay.overlay(this, GRID_SIZE, Std.int(h), GRID_SIZE * 8,GRID_SIZE * Height);
    }
    override function update(elapsed) {}
}