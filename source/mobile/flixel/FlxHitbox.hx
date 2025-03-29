package mobile.flixel;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxDestroyUtil;
import openfl.display.BitmapData;
import openfl.display.Shape;
import mobile.flixel.FlxButton;
import flixel.tweens.FlxTween;

class FlxHitbox extends FlxSpriteGroup
{
	public var buttons:Array<FlxButton> = [];

	public function new()
	{
		super();

		var width = Std.int(FlxG.width / 4);
		var colors = [0xFF00FF, 0x00FFFF, 0x00FF00, 0xFF0000];
		for (i in 0...4)
			add(buttons[i] = createHint(i * width, 0, width, FlxG.height, colors[i]));

		scrollFactor.set();
	}

	override function destroy()
	{
		super.destroy();
		for (button in buttons)
			button = FlxDestroyUtil.destroy(button);
	}

	function createHintGraphic(width:Int, height:Int, color:Int):BitmapData
	{
		var shape = new Shape();
		shape.graphics.beginFill(color);
		shape.graphics.drawRect(0, 0, width, height);
		shape.graphics.endFill();

		var bitmap = new BitmapData(width, height, true, 0);
		bitmap.draw(shape);
		return bitmap;
	}

	function createHint(x:Float, y:Float, width:Int, height:Int, color:Int):FlxButton
	{
		var hintTween:FlxTween = null;
		
		var hint = new FlxButton(x, y);
		hint.loadGraphic(createHintGraphic(width, height, color));
		hint.solid = hint.immovable = false;
		hint.scrollFactor.set();
		hint.alpha = 0.00001;

		hint.onDown.callback = hint.onOver.callback = () -> {
			if (hintTween != null)
				hintTween.cancel();
			hint.alpha = 0.3;
		};

		hint.onUp.callback = hint.onOut.callback = () -> {
			if (hintTween != null)
				hintTween.cancel();
			hintTween = FlxTween.tween(hint, { alpha: 0.00001 }, 0.2);
		};

		#if FLX_DEBUG
		hint.ignoreDrawDebug = true;
		#end

		return hint;
	}
}
