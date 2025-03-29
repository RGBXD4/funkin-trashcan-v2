package mobile;

import flixel.FlxG;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxDestroyUtil;
import mobile.flixel.FlxHitbox;

/**
 * @author Mihai Alexandru (M.A. Jigsaw)
 */
class MobileControls extends FlxSpriteGroup
{

	public var hitbox:FlxHitbox;

	public function new()
	{
		super();

				hitbox = new FlxHitbox();
				add(hitbox);
	}

	override public function destroy():Void
	{
		super.destroy();

		if (hitbox != null)
			hitbox = FlxDestroyUtil.destroy(hitbox);
	}
}
