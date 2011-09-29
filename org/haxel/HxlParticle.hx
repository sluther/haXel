package org.haxel;
	
	/**
	 * This is a simple particle class that extends the default behavior
	 * of <code>HxlSprite</code> to have slightly more specialized behavior
	 * common to many game scenarios.  You can override and extend this class
	 * just like you would <code>HxlSprite</code>. While <code>HxlEmitter</code>
	 * used to work with just any old sprite, it now requires a
	 * <code>HxlParticle</code> based class.
	 * 
	 * @author Adam Atomic
	 */
	class HxlParticle extends HxlSprite
	{
		/**
		 * How long this particle lives before it disappears.
		 * NOTE: this is a maximum, not a minimum; the object
		 * could get recycled before its lifespan is up.
		 */
		public var lifespan:Float;
		
		/**
		 * Determines how quickly the particles come to rest on the ground.
		 * Only used if the particle has gravity-like acceleration applied.
		 * @default 500
		 */
		public var friction:Float;
		
		/**
		 * Instantiate a new particle.  Like <code>HxlSprite</code>, all meaningful creation
		 * happens during <code>loadGraphic()</code> or <code>makeGraphic()</code> or whatever.
		 */
		public function new()
		{
			super();
			lifespan = 0;
			friction = 500;
		}
		
		/**
		 * The particle's main update logic.  Basically it checks to see if it should
		 * be dead yet, and then has some special bounce behavior if there is some gravity on it.
		 */
		override public function update():Void
		{
			//lifespan behavior
			if(lifespan <= 0)
				return;
			lifespan -= HxlG.elapsed;
			if(lifespan <= 0)
				kill();
			
			//simpler bounce/spin behavior for now
			if(touching)
			{
				if(angularVelocity != 0)
					angularVelocity = -angularVelocity;
			}
			if(acceleration.y > 0) //special behavior for particles with gravity
			{
				if(touching & FLOOR)
				{
					drag.x = friction;
					
					if(!(wasTouching & FLOOR))
					{
						if(velocity.y < -elasticity*10)
						{
							if(angularVelocity != 0)
								angularVelocity *= -elasticity;
						}
						else
						{
							velocity.y = 0;
							angularVelocity = 0;
						}
					}
				}
				else
					drag.x = 0;
			}
		}
		
		/**
		 * Triggered whenever this object is launched by a <code>HxlEmitter</code>.
		 * You can override this to add custom behavior like a sound or AI or something.
		 */
		public function onEmit():Void
		{
		}
	}
