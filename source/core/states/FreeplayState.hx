package core.states;

class FreeplayState extends BeatState {
	static var curSelected = 0;
	var selectedIt = false; 
    override function create() {
		persistentUpdate = true;
        DiscordClient.changePresence('In Freeplay');

		var mainBG = new FlxSprite().loadGraphic(Paths.textures('freeplay/desat'));
		mainBG.antialiasing = Settings.data.antialiasing;
		add(mainBG);
		mainBG.screenCenter();

        super.create();
    }

    override function update(elapsed:Float) {
        if (!selectedIt) {
			if (controls.UI_UP_P)
				changeSong(-1);
			else if (controls.UI_DOWN_P)
				changeSong(1);

			if (controls.BACK) {
				selectedIt = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				changeState(MenuState);
			}

			if (controls.ACCEPT) {
				selectedIt = true;
				FlxG.sound.play(Paths.sound('confirmMenu'));
            }
        }
        super.update(elapsed);
    }

	function changeSong(change = 0) {
		curSelected = FlxMath.wrap(curSelected + change, 0, 0);
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}
}