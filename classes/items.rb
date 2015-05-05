class ItemObject
  #Make these variables accessible outside of class
  attr_reader :x, :y, :type, :vx, :vy, :growth_height
  
  def initialize(window, x=0, y=0, type="coin", healthy=4, direction="right", tinman=false, zorro=false)
  	#RE-ESTABLISH item type based on the character's situation...
  	if window.camera_y!=-2000
  	  if type!="ax" && type!="clock_pickup" && type!="vine_growth"
  	    (type = "clock_pickup" if (window.character.time<660 && window.character.health>0) || (tinman==true && type=="tinman_pickup"))
  	  end
  	  type = "emerald" if window.character.searcher && type=="flashlight_pickup" 
  	end
  	type = "vine_growth" if zorro==true && type=="zorro_pickup"
  	
    #position variables...
    @window, @x, @y, @z, @type, @vx, @vy, dm_x, dm_y, @angle, @size = window, x, y, 0, type, 0, 0, 64, 64, 0, 1
    
    #Default DIRECTORY...
    directory = "artwork/inventory"
    
    #MOVING items...
    if type=="tinman_pickup"
      @vy = -20
      @vx = 5 if direction=="right"
      @vx = -5 if direction=="left"
      dm_x = dm_y = 92
    elsif type=="zorro_pickup"
      @vy = -5
      @vx = 3 if direction=="right"
      @vx = -3 if direction=="left"
      dm_x = dm_y = 64
    elsif type=="ax"
      @vy = -25 - healthy/3
      (@vx = 6+(healthy/2) ; @size = 1) if direction=="right"
      (@vx = -(6+(healthy/2)) ; @size = -1) if direction=="left"
      @vx=1 if @vx==0
      @dir = direction
      @z = 2
      @angle = -90
      dm_x = dm_y = 92
    elsif type=="vine_growth"
      @vx, @vy, @growth_height = 0, 0, 0
      @stems = []
      @speeds = []
      @snd_vine = Sample.new(@window, "audio/vine.wav")
      @z = -1
      dm_x = dm_y = 92
      directory = "artwork/level"
    elsif type=="fire_pickup"
      @glow = Image.new(window, "artwork/background/moon_glow.png", false)
      dm_x, dm_y = 50, 75
    end
    
    #IMAGE
    @type = type = "coin" if type=="" || @type=="" #Prevents no item error!
    @invObj = Image.load_tiles(window, "#{directory}/#{type}.png", dm_x, dm_y, false)
    @invObj.push(@invObj[1]) if type == "tinman_pickup"
    if type == "ruby" || type == "emerald" || type == "sapphire"
    	@invObj.push(@invObj[4])
    	@invObj.push(@invObj[3])
    	@invObj.push(@invObj[2])
    	@invObj.push(@invObj[1])
    	@invObj.push(@invObj[0])
    end
  end
  
  def update(solid_right=nil, solid_left=nil)
    if @type =~ /tinman|zorro/
      if @vx>0
  	    (@vx.abs.to_i).times do
  	      if not solid_right ; @x+=1 ; else ; @vx*=-1 ; end
  	  	end
  	  end
  	  if @vx<0
  	    (@vx.abs.to_i).times do
  	      if not solid_left ; @x-=1 ; else ; @vx*=-1 ; end
  	  	end
  	  end
      if @vy>0
  	    (@vy.abs.to_i).times do
  	      if not @window.level.solid?(@x,@y+28) ; @y += 1 ; else ; @vy = -5 ; @vy = -20 if @type=="tinman_pickup" ; end
  	  	end
  	  end
  	  if @vy<0
  	    (@vy.abs.to_i).times do
  	      if not @window.level.solid?(@x,@y-28,@vy) ; @y -= 1 ; else ; @vy = 0 ; end
  	  	end
  	  end
  	  
  	  if @type=="tinman_pickup"
  	    #GRAVITY...
  	    @vy+=1 if @vy < 30
  	  else
        #GRAVITY...
        @vy+=0.2 if @vy < 4
  	  end
  	elsif @type == "ax"
  	  #REGULAR Accumulators
  	  @x += @vx
  	  @y += @vy
  	  @angle += 10*@size
  	  
  	  #GRAVITY...
  	  @vy+=1 if @vy < 30
  	  
  	  #UNDERWATER...
  	  if @y > @window.level.water_level - 16
  	    @vy /= 1.125
  	    @vx /= 1.025
  	    @angle -= 5*@size
  	  end
  	elsif @type == "vine_growth"
  	  
  	  #GROW bitch, GROW!!! ...until you reach the top of the level, of course!
  	  @growth_height += 4 if (@y-@growth_height)>=-100
  	  @snd_vine.play(0.5) if @growth_height==4
  	  
  	  #INCREMENT for every 92 pixels grown...
  	  if ((@growth_height-4)/92).to_i == ((@growth_height-4)/92.0).to_f
  	    @stems.push(Image.load_tiles(@window,"artwork/level/vine_var#{1+rand(4)}.png",92,92,false))
  	    @speeds.push(250+rand(100))
  	  end
  	else
  	  #NO movement...
  	end
  end
    
  #Draw and animate the image...
  def draw(sx, sy, color=0xffffffff)
    if @type != "vine_growth"
  	  @invObj[milliseconds / 60.0 % @invObj.size].draw_rot(@x - sx, @y - sy, @z, (@angle/30).to_i*30, 0.5, 0.5, @size, 1, color)
  	  @glow.draw_rot(@x - sx, @y - 23 - sy, @z + 0.1, 0, 0.5, 0.5, 1, 1, 0xaaff6600, :additive) if @type=="fire_pickup"
  	else
  	  #APICAL MERISTEM...
  	  @invObj[milliseconds / 200 % @invObj.size].draw_rot(@x - sx, @y - @growth_height - sy, @z+0.1, @angle, 0.5, 0.5, @size, 1, color)
  	  
  	  #ZONE OF ELONGATION
  	  @stems.each do |stem|
  	    stem[milliseconds / @speeds[@stems.index(stem)] % stem.size].draw_rot(@x - sx, @y - (@stems.index(stem)*92) - sy, @z, 0, 0.5, 0.5, 1, 1, color)
      end
  	end
  end
end

class Fireball
  attr_reader :x, :y, :vel_x, :vel_y, :out, :out_duration, :stationary
  attr_writer :x, :y, :stationary
  
  def initialize(window, x, y, stationary=true, level=nil, vx=0, vy=0, out=false)
    @window, @x, @y, @stationary, @level = window, x, y, stationary, level
    @flame = Image.new(window, "artwork/particles/fireball.png", false)
    @glows = Image.new(window, "artwork/background/moon_glow.png", false)
    
    #ADDITIONAL ATTRIBUTES
    @angle            = rand(360)
    @size             = 1.8
    @particles        = []
    @out              = out
    
    #CHECK if fire already "put out"...
    if out == false
      @out_duration   = 360 #4 seconds...
      @color          = 0xffff9955
    else
      @out_duration   = 0   #0 seconds...
      @color          = 0x00000000
    end
    
    @snd_whoosh       = Sample.new(@window, "audio/whoosh.wav")
    @sound_played     = false
    @vel_x, @vel_y    = vx, vy
    
    #EMITTING RATES...
    if stationary == false
      @emit_rate = 2
    else
      @emit_rate = 4
    end
    @emit, @wind_time = @emit_rate, 0
  end
  
  def explode(rate=2)
    if @out == false
      rate.times do
        @particles.push(Particle.new(@window, @x+9-rand(18)-@vel_x, @y-rand(25), -1.5, "flame"))
      end
    end
  end
  
  def update
    if @stationary==true ; v_grav=-1.5 ; @vel_y=0 ; else ; v_grav=0 ; end
    @particles.push(Particle.new(@window, @x+3-rand(6)+@vel_x, @y+6-rand(9)+@vel_y, v_grav, "flame")) if @emit==@emit_rate && @out==false
    @particles.reject! {|particle| particle.x if particle.out == true}
    @emit      -= 1
    @wind_time -= 1 if @wind_time > 0
    
    #PUT IT OUT!!!
    if @out == true
      @out_duration -= 1
      @out_duration -= 11 if @stationary==false
      @vel_x = @vel_y = 0
      
      #ADD SMOKE WHEN "DYING..."
      if @out_duration>0 && @emit < 1 && @stationary==true
        @particles.push(Particle.new(@window, @x+1-rand(2), @y+1-rand(2), -rand(1)/10, "smoke", 200-(@out_duration/2)))
      end
      
      @emit = 7 if @emit < 1
      @color = Color.new((@out_duration/1.41).to_i,255,@out_duration/9,0) if @out_duration>=0
    end
    
    #PHYSICAL attributes of FIRE
    @particles.each do |fire|
      if distance(@window.character.x,@window.character.y,@x,@y)<175 && fire.type!="smoke" && @window.character.fireman!=true
        #RUSHING WIND
        if @window.character.vel_x.abs > 6 || @window.character.vel_y.abs > 6 || @wind_time > 0
          fire.vel_x = (@window.character.vel_x.to_f/6.5)  * distance(@window.character.x,@window.character.y,@x,@y)/175.0
          fire.vel_y = (@window.character.vel_y.to_f/7.5) * distance(@window.character.x,@window.character.y,@x,@y)/175.0
        end
        
        if @window.character.vel_x.abs > 8 || @window.character.vel_y.abs > 8
          @emit = 6 if @emit < 2
          @color = 0x40ff9900
          @wind_time = 10
          fire.size += 0.02
          
          #FIRE sound...
          @snd_whoosh.play((@window.character.vel_x.abs+@window.character.vel_y.abs)/25,0.7) if @sound_played == false
          @sound_played = true
        else
          @emit = @emit_rate if @emit < 1
          @color = 0xffff9955
          @sound_played = false if @wind_time < 1
        end
        
        #PUTTING OUT FIRE
        if (@window.character.vel_x.abs * @window.character.vel_y.abs) > 560 || @window.character.vel_y.abs > 32
          @particles.push(Particle.new(@window, @x+4-rand(8), @y+8-rand(8), 1-rand(3), "smoke")) if @out==false
          
          #About to be put out...
          if @out==false
            4.times { @snd_whoosh.play(2.0,0.7+(rand(4)/10.0)) }
            @window.character.heat_up
          end
          
          #OUT actions
          @sound_played = true
          @out = true
        end
      else
        @emit = @emit_rate if @emit < 1
        @sound_played = false if @wind_time < 1
        @color = 0xffff9955 if @out==false
      end
    end
    
    #GENERAL elimination of fireball...
    def kill
      explode(6) if @out == false
      @out = true
      if @stationary == false
        @emit_rate = 1
      else
        @emit_rate = 3
      end
      @emit, @wind_time = @emit_rate, 0
    end
    
    #GENERAL revival of fireball...
    def light_up
      explode(1)
      @out_duration = 360
      @out          = false
    end
    
    #MOVING FIREBALL
    if @stationary == false
      #PHYSICS
      if @vel_x>0
        (@vel_x.abs.to_i).times do
          if not @level.solid?(@x+12,@y) ; @x+=1 ; else ; explode(6) ; @out = true ; end
        end
      end
      if @vel_x<0
        (@vel_x.abs.to_i).times do
          if not @level.solid?(@x-12,@y) ; @x-=1 ; else ; explode(6) ; @out = true ; end
        end
      end
      if @vel_y>0
        (@vel_y.abs.to_i).times do
          if not @level.solid?(@x,@y+16) ; @y += 1 ; else ; @emit = 7 ; explode(4) if @vel_y>0 ; @vel_y = -9 ; end
        end
      end
      if @vel_y<0
        (@vel_y.abs.to_i).times do
          if not @level.solid?(@x,@y-16,@vel_y) ; @y -= 1 ; else ; @emit = 7 ; (explode(4) ; @vel_y*=-1) if @vel_y<0 ; end
        end
      end
    end
    
    #GRAVITY
    @vel_y += 0.5 if @vel_y < 15
    @vel_y = 15   if @vel_y > 14
    
    #UNDERWATER
    if @level != nil
      if @y > @level.water_level
        @vel_y /= 1.2
        @vel_x /= 1.02
        kill if @vel_x.abs < 1
      end
    end
  end
  
  def draw(sx, sy, z=0.0)
    #FLICKER color effect
    flicker = Color.new(75+rand(25),255,125+rand(50),0)
    flicker = Color.new(50+rand(25),205-(@wind_time*5),125-(@wind_time*7)+rand(50),0) if @emit > @emit_rate || @wind_time > 1
    
    #WHEN the fire is not out...
    if @out == false
      #FIRE SOURCE...
      @flame.draw_rot(@x - sx, @y - sy, z, @angle, 0.5, 0.5, @size, @size, @color, :additive)
      
      #AMBIENCE...
      @glows.draw_rot(@x - sx, @y - 23 - sy, -0.1, 0, 0.5, 0.5, @size/1.5, @size/1.5, flicker, :additive)
      @glows.draw_rot(@x - sx, @y - 10 - sy,    0, @angle, 0.5, 0.5, @size/2.9, @size/2.9, 0x92ff6611, :additive) if @stationary==true
    else
      @glows.draw_rot(@x + 2 - sx, @y + 4 - sy, 0.9, 0, 0.5, 0.5, 0.06, 0.06, @color, :additive)
      @glows.draw_rot(@x + 1 - sx, @y + 5 - sy, 0.9, 0, 0.5, 0.5, 0.09, 0.06, @color, :additive)
    end
    
    #ANIMATIONS
    @angle += 2 if @out == false
    @particles.each { |particle| particle.draw(sx,sy) }
  end
end

#SPECIAL TILES for level class ---------------------------
class SpecialTile
  #Make these variables accessible AND writable outside of class
  attr_reader :x, :y, :destroyed, :item, :timer, :visible
  attr_writer :destroyed, :visible
  
  def initialize(window, x=0, y=0, type="item_block", visible=true)
    #position variables...
    @x, @y, @destroyed, @timer, @hit_y, @visible = x, y, false, 0, 0, visible
    
    #IMAGE
    @block = Image.load_tiles(window, "artwork/level/#{type}.png", 92, 92, false)
    
    #ITEM storage types (duplications for probability purposes)
    items = ["coin", "coin", "heart_pickup", "clock_pickup", "tinman_pickup", "heart_poison", "fast_clock", "flashlight_pickup"]
    items = ["heart_pickup", "clock_pickup", "tinman_pickup", "ruby", "zorro_pickup"] if visible == :special
    items = ["vine_growth"] if visible == :vine
    items = ["fire_pickup"] if visible == :fire
    
    #Re-adjust value for visible. This is in case a different value has been passed in
    #for the purpose of having different behaviors of this tile object.
    @visible = true if visible!=true && visible!=false
    
    items = ["ruby", "emerald", "sapphire", "flashlight_pickup"] if @visible==false
    @item = items[rand(items.size-rand(items.size))]
    
    #REARRANGE animations
    @block = [@block[1],@block[2],@block[3],@block[4],@block[0],@block[0],@block[0],@block[5],@block[6],@block[7]] if type=="item_block"
    @block = [@block[1],@block[2],@block[3],@block[4],@block[0],@block[5],@block[6],@block[7]]                     if type=="fire_block"
  end
  
  #DEADNESS
  def dead
  	@timer>11
  end
    
  #Draw and animate the image...
  def draw(sx, sy, color=nil)
    if @destroyed==true
      @visible = true
      @timer += 1
      @hit_y -= 12 if @timer<=4
      @hit_y += 6 if @timer>4
    end
    
    if @visible==true
  		@block[milliseconds / 50.0 % @block.size].draw_rot(@x - sx, @y - sy, -0.1, 0, 0.5, 0.5, 1, 1, color) if @destroyed==false
  		@block[4].draw_rot(@x - sx, @y - sy + @hit_y, 0, 0, 0.5, 0.5, 1, 1, color) if @timer!=0
  	end
  end
end

#EXPLOSION (not exactly a particle... lol)
class Explosion
  attr_reader :x, :y
  
  def initialize(window, x, y, size=1.0)
    @window, @x, @y = window, x, y
    @explosion = Image.new(@window, "artwork/particles/explosion.png", false)
    
    #ATTRIBUTES
    @size  = size
    @color = Color.new(155+rand(100),200,rand(100),0)
    @angle = rand(360)
    @vel_x, @vel_y = 30-rand(60),30-rand(60)
    @ax, @ay = 0.6, 0.4
    @ox, @oy = @x, @y
  end
  
  def out?
    @color.alpha < 3
  end
  
  def draw(sx,sy)
    @color.alpha -= 2 if @color.alpha>1
    @angle       += rand(5)
    @size        += 0.2 + (@size.to_f/80.0)
    @explosion.draw_rot(@ox-sx,@oy-sy,-1,@angle,0.5,0.5,@size.to_i/1.25,@size.to_i/1.25,Color.new(@color.alpha/10,255,255,255),:additive)
    @explosion.draw_rot(@x-sx,@y-sy,3,@angle,@ax,@ay,@size,@size/1.5,@color,:additive)
    @explosion.draw_rot(@y-sx,@x-sy,4,@angle,@ax,@ay,@size/2.0,@size/3.0,@color,:additive)
    @x+=@vel_x
    @y+=@vel_y
  end
end

#UPGRADE items as seen in Dr. Marcoux's item shop
class PurchaseItem
  attr_reader :x, :y, :type, :cost_coin, :cost_ruby, :cost_emer, :cost_sapp, :bought
  def initialize(window, x=0, y=0, type="tinman_item")
    #ATTRIBUTES
    @window, @x, @y, @type, @name_text, @desc, @bought = window, x, y, type, "<no name>", "", false
    
    #PRICING
    @cost_coin = @cost_ruby = @cost_emer = @cost_sapp = 0
    
    #DIRECTORY...
    directory = "artwork/inventory"
    
    #MONETARY images...
    @money = []
    @color = []
    @font = Font.new(@window, "Monaco", 21)
    @lite = Image.new(@window,"artwork/level/hour_washer.png",false)
    @pur_time = @time = 0
    @pur_text = []
    @inv_c    = Color.new(255,255,255,255)
    
    #TYPES
    if type=="upgrade_jump"
      @name_text   = "Jump +#{1+@window.character.level_jump}"
      @desc        = "Increases Anthony's jump power."
      @cost_emer   = 5 + (@window.character.level_jump * 10)
      @inv_c.red   = 51 * @window.character.level_jump
      @inv_c.green = 255 - (51 * @window.character.level_jump)
    elsif type=="upgrade_speed"
      @name_text   = "Dash +#{1+@window.character.level_speed}"
      @desc        = "This will make Anthony run faster."
      @cost_ruby   = 4 + (@window.character.level_speed * 6)
      @inv_c.red   = 51 * @window.character.level_speed
      @inv_c.blue  = 51 * @window.character.level_speed
    elsif type=="upgrade_ax"
      @name_text   = "Ax +#{1+@window.character.level_axes}"
      @desc        = "Purchasing this will allow you to throw #{3+@window.character.level_axes} axes at once!"
      @cost_ruby   = 3 + (@window.character.level_axes * 5)
      @inv_c.green = 51 * @window.character.level_axes
      @inv_c.blue  = 51 * @window.character.level_axes
    elsif type=="upgrade_fly"
      @name_text  = "Flight +#{1+@window.character.level_cape}"
      @desc       = "Makes flying easier (Zorro Bat - Only effective on next equip)."
      @cost_sapp  = 6 + (@window.character.level_cape * 8)
      @inv_c.red  = 255 - (51 * @window.character.level_cape)
      @inv_c.blue = 255 - (51 * @window.character.level_cape)
    elsif type=="clock_item"
      @name_text = "60 Seconds"
      @desc      = "Adds a minute to your current level's game time."
      @cost_coin = 75
    elsif type=="flashlight_item"
      @name_text = "Stashlight"
      @desc      = "Finds treasure in hidden blocks and more. It also adds light in underground obstacles (usable for one level ONLY)."
      @cost_coin = 150
      @cost_ruby = 1
    elsif type=="zorro_item"
      @name_text = "Zorro Bat"
      @desc      = "Wearing this will give Anthony the ability to fly!"
      @cost_coin = 250
    elsif type=="tinman_item"
      @name_text = "Tin Man"
      @desc      = "Wearing this will allow Anthony the ability to throw axes (WARNING: Heavy Suit)."
      @cost_coin = 100
    elsif type=="health_item"
      @name_text = "Full Health"
      @desc      = "Fills Anthony's health gauge completely!"
      @cost_coin = 25
    elsif type=="heart_double"
      @name_text = "Double Heart"
      @desc      = "Each heart takes two strikes (health capacity increase)."
      @cost_ruby = 75
      @cost_emer = 50
      @cost_sapp = 25
    end
    
    #LOAD required monetary images...
    (@money.push(Image.load_tiles(@window,"#{directory}/coin.png",64,64,false)[0]) ; @color.push(Color.new(255,255,255,100)))   if @cost_coin!=0
    (@money.push(Image.load_tiles(@window,"#{directory}/ruby.png",64,64,false)[0]) ; @color.push(Color.new(255,255,100,100)))   if @cost_ruby!=0
    (@money.push(Image.load_tiles(@window,"#{directory}/emerald.png",64,64,false)[0]) ; @color.push(Color.new(255,100,255,100)))  if @cost_emer!=0
    (@money.push(Image.load_tiles(@window,"#{directory}/sapphire.png",64,64,false)[0]) ; @color.push(Color.new(255,100,150,255))) if @cost_sapp!=0
    
    @invObj = Image.load_tiles(window, "#{directory}/purchase/#{type}.png", 64, 64, false)
    @invObj.push(@invObj[3])
    @invObj.push(@invObj[2])
    @invObj.push(@invObj[1])
    @invObj.push(@invObj[0])
  end
  
  #UPDATE item purchasing action
  def update(character=nil)
    if distance(character.x,character.y,@x,@y+200)<125
      if character.coins>=@cost_coin &&
         character.rubies>=@cost_ruby &&
         character.emeralds>=@cost_emer &&
         character.sapphires>=@cost_sapp
          if @time>5
            character.buy(@type,@cost_coin,@cost_ruby,@cost_emer,@cost_sapp)
            @window.set_monetary(@cost_coin,@cost_ruby,@cost_emer,@cost_sapp)
            @pur_time = 100
            @pur_text = ["THANK YOU!"]
            @name_text = ""
            @bought = true
          end
      else
        if @time>5
          @pur_time = 150
          @pur_text = []
          #VALIDATE text display
          if character.coins<@cost_coin
            if @cost_coin-character.coins==1
              @pur_text.push("#{@cost_coin-character.coins} more COIN")
            else
              @pur_text.push("#{@cost_coin-character.coins} more COINS")
            end
          end
          if character.rubies<@cost_ruby
            if @cost_ruby-character.rubies==1
              @pur_text.push("#{@cost_ruby-character.rubies} more RUBY")
            else
              @pur_text.push("#{@cost_ruby-character.rubies} more RUBIES")
            end
          end
          if character.emeralds<@cost_emer
            if @cost_emer-character.emeralds==1
              @pur_text.push("#{@cost_emer-character.emeralds} more EMERALD")
            else
              @pur_text.push("#{@cost_emer-character.emeralds} more EMERALDS")
            end
          end
          if character.sapphires<@cost_sapp
            if @cost_sapp-character.sapphires==1
              @pur_text.push("#{@cost_sapp-character.sapphires} more SAPPHIRE")
            else
              @pur_text.push("#{@cost_sapp-character.sapphires} more SAPPHIRES")
            end
          end
          if character.fully_healed? && @type=="health_item"
            @pur_text.push("Your health is fine anyway, stupid.")
          end
          if character.tinman==true && @type=="tinman_item"
            @pur_text.push("You're already Tin Man! Sheesh!")
          end
          if character.zorro_bat==true && @type=="zorro_item"
            @pur_text.push("C'mon! You don't really need this.")
          end
        end
      end
    end
  end
  
  def bought?
    @bought==true && @pur_time<1 && @time<1
  end
  
  def draw_price(sx,sy,ssx,ssy)
    #DRAW only when interacted
    if @time > 0
      #SYMBOLS...
      if @bought==false
        for i in 0..@money.size-1
          @money[i].draw_rot(@x - sx + 4, @y - sy + 95 + (i*64), 0, 0, 0.5, 0.5, 0.75, 0.75, Color.new(3*@time,0,0,0)) #SHADOW...
          @money[i].draw_rot(@x - sx, @y - sy + 92 + (i*64), 0, 0, 0.5, 0.5, 0.75, 0.75, Color.new((4.25*@time).to_i,255,255,155))
        end
      
        #TEXTS...
        for c in 0..@color.size-1
          #FADING
          @color[c].alpha = (4.25*@time).to_i
        
          #TEXT by symbol
          if @color[c].red==255 && @color[c].green==255
            text = @cost_coin.to_s
          elsif @color[c].red==255 && @color[c].green==100 && @color[c].blue==100
            text = @cost_ruby.to_s
          elsif @color[c].green==255
            text = @cost_emer.to_s
          elsif @color[c].blue==255
            text = @cost_sapp.to_s
          end
        
          #TEXT
          @font.draw(text, @x-sx+46, @y-sy+82+(c*64), 0, 1, 1, @color[c])
        end
      end
      
      #NAME text
      @font.draw(@name_text, @x-sx-4-(@name_text.length*4), @y-sy-64, 0, 1, 1, Color.new((4.25*@time).to_i,255,255,255)) if @pur_time<1
      @font.draw("You need:", @x-sx-40, @y-sy-72-(@pur_text.size*20), 0) if @pur_time>0 && @bought==false
      if @pur_time>0
        for t in 0..@pur_text.size-1
          s=1 ; s=1.5 if @pur_text[t]=~/THANK/
          @font.draw(@pur_text[t], @x-sx-(@pur_text[t].length*(4*s)), @y-sy-44-(@pur_text.size*20)+(t*20), 0, s, s)
        end
      end
      
      #LIGHTING...
      @lite.draw_as_quad(@x-45,   -sy, Color.new(@time*3,255,255,100),
                         @x+45,   -sy, Color.new(@time*3,255,255,100),
                         @x-45, @y+48, Color.new(@time/2,255,255,100),
                         @x+45, @y+48, Color.new(@time/2,255,255,100), 1, :additive)
    end
    
    #COLLISION detection...
    if (distance(@window.character.x,@window.character.y,@x,@y+200)<125 && @bought==false) || @pur_time>0
      @time += 5 if @time < 60
      #DESCRIPTION
      if not (@pur_time>0 && @bought==false)
        @font.draw(@desc, ssx/2-4-(@desc.length*5), ssy-125, 1, 1.25, 1.25)
        @font.draw(@desc, ssx/2-2-(@desc.length*5), ssy-123, 0, 1.25, 1.25, 0xff000000)
      end
    else
      @time -= 5    if @time > 0 && @pur_time < 1
      @pur_time = 0 if @bought==false && @time<5    
    end
    
    #Attempted to buy
    @pur_time -= 1 if @pur_time > 0
  end
  
  def draw(sx,sy,ssx,ssy)
    @invObj[milliseconds / 60.0 % @invObj.size].draw_rot(@x - sx, @y - sy, 0, 0, 0.5, 0.5, 1, 1, @inv_c) if @bought==false
    draw_price(sx,sy,ssx,ssy)
  end
end