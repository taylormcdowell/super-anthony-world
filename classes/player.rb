class Player
	attr_reader :x, :y, :direction, :coins, :vel_x, :vel_y, :strength, :score, :hiscore, :game_over,
				:time_attck, :health, :alive, :tinman, :fireman, :zorro_bat, :pipe_y, :axes, :fireballs, :complete,
				:rubies, :emeralds, :sapphires, :battling, :time, :ducking_rate, :fast_time,
				:level_super, :level_jump, :level_cape, :level_speed, :level_axes, :searcher
	attr_writer :jump_button_reset, :time_attck, :vel_x, :vel_y, :win_y, :direction, :searcher
	
	def initialize(window, level=nil)
		@window, @level = window, level
		
		# X, Y and other positional attributes ...
		@x, @y, @vel_x, @vel_y = @level.start_x, @level.start_y, 0.0, 0.0
		
		#General physical attributes
		@complete = false
		@game_over = false
		@battling  = false
		@scuba     = false
    	@gravity  = 0.9
    	@strength = 13
    	@max_grv  = 33
    	@agility, @grd_agility, @air_agility = 1.3, 1.3, 0.7 #Current agility value, ground agility, aerial agility
    	@friction = 0.92
    	@jump_vel = 28
    	@jump_sen = 8 # Jump velocity sensitivity. Depending on how long the key was held down...
    	@jump_rte = @jump_sen
    	@jump_button_reset = true #WHEN the button is released (button_up id), set this to true...
    	@jump_air   = false
    	@max_speed  = 8.0
    	@max_walk   = 8.0
    	@max_run    = 18.0
    	@attck_time = 120
    	@time_attck = 0
    	
    	#SPECIAL CHARACTERS attributes...
    	@tinman     = false
    	@zorro_bat  = false
    	@float      = 0
    	@fireman    = false
    	@heat       = 0
    	@searcher   = false
    	
    	#INVENTORY
    	@coins     = 0
    	@rubies    = 0
    	@emeralds  = 0
    	@sapphires = 0
    	@health    = 4
    	@score     = 0
    	@time      = 7200
    	@fast_time = 0
    	@hiscore   = 0
    	@combo     = 1
    	@heart     = Image.load_tiles(@window, "artwork/inventory/heart.png", 36, 36, false)
    	
    	#UPDATABLE ATTRIBUTES
    	@level_jump   = 0 #JUMP POWER UPGRADE
    	@level_speed  = 0 #RUN SPEED UPGRADE
    	@level_axes   = 0 #AX THROW UPGRADE (increases ax count limit)
    	@level_cape   = 0 #GLIDING UPGRADE (increases float time)
    	@level_super  = 0 #DOUBLE-HEART UPGRADE (rare)
    	
    	#PARTICLES
    	@floating_numbers = []
    	@fireballs        = []
    	@smoke            = []
    	@axes             = []
    	
		#COLLISION offset
    @image_offset_x, @image_offset_y = -36, -28
		
		# ANIMATION images...
		@animation_idle = Image.load_tiles(@window, "artwork/anthony/idle.png", 112, 210, false)
		@animation_idle.push(@animation_idle[1]) # Adding extra frame to adjust animation
		
		@animation_run  = Image.load_tiles(@window, "artwork/anthony/run.png", 112, 210, false)
		@animation_run.push(@animation_run[1]) # Adding extra frame to adjust animation
		
		@animation_depw, @px, @py = nil, @x, @y
		@animation_jump = Image.load_tiles(@window, "artwork/anthony/jump.png", 112, 210, false)
		@animation_duck = Image.load_tiles(@window, "artwork/anthony/duck.png", 112, 210, false)
		
		@animation_clmb = Image.load_tiles(@window, "artwork/anthony/climb.png", 112, 210, false)
		@animation_clmb.push(@animation_clmb[1]) # Adding extra frame to adjust animation
		
		@animation_swim = Image.load_tiles(@window, "artwork/anthony/swim.png", 112, 210, false)
    @animation_swim.push(@animation_swim[1]) # Adding extra frame to adjust animation
		
		@animation_fly  = Image.load_tiles(@window, "artwork/anthony/fly.png", 112, 210, false) #ZORRO-BAT image ONLY
		@animation_dead = Image.load_tiles(@window, "artwork/anthony/dead.png", 165, 210, true)
		@animation_dieX = Image.load_tiles(@window, "artwork/anthony/dead_horribly.png", 165, 210, true)
		@transform_flsh = Image.new(@window, "artwork/level/hour_washer.png", false)
		@glow           = Image.new(@window, "artwork/background/moon_glow.png", false)
		
		# ANIMATION rates for walking, running, ducking, etc...
		@current_frame = 0
		@animate_freq  = 16
		@animate_timer = 0
		@ducking_rate  = 0
		@throw_time    = 0
		@flsh_timer    = 0
		@respond_delay = 0
		@flsh_color    = Color.new(0xffffffff)
		@dead_y, @dead_vel_y, @dead_timer = 0, 20, 38
		@win_y = 0
		@pipe_y = 0
		@alive = true
		@climbing = false
		@clmb_dir = :idle
		@swimming = false
		@bubble_m = 3
		@bubble_r = rand(300)
		
		#CURRENT image settings
		@character = @animation_idle[@current_frame]
		@flip_x    = 1
		@direction = "right"
		@color     = Color.new(0xffffffff)
		@color_m   = :default #OPTIONS: "default" or "additive"
		@darkness  = 0
		
		#LOAD lighting...
    @flashlight = Image.new(@window, "artwork/anthony/flashlight.png", false)
		
		#SOUND EFFECTS
		@snd_jump  = Sample.new(@window, "audio/jump.wav")
		@snd_coin  = Sample.new(@window, "audio/coin_pickup.wav")
		@snd_purc  = Sample.new(@window, "audio/purchase.wav")
		@snd_hitb  = Sample.new(@window, "audio/ceiling_hit.wav")
		@snd_hitg  = Sample.new(@window, "audio/ground_hit.wav")
		@snd_stomp = Sample.new(@window, "audio/stomp.wav")
		@snd_splsh = Sample.new(@window, "audio/splash.wav")
		@snd_light = Sample.new(@window, "audio/flashlight.wav")
		@snd_heart = Sample.new(@window, "audio/heart_pickup.wav")
		@snd_poisn = Sample.new(@window, "audio/heart_poison.wav")
		@snd_clock = Sample.new(@window, "audio/clock_pickup.wav")
		@snd_beep  = Sample.new(@window, "audio/clock_beep.wav")
		@snd_ring  = Sample.new(@window, "audio/clock_ring.wav")
		@snd_hurt  = Sample.new(@window, "audio/hurt.wav")
		@snd_death = Sample.new(@window, "audio/death.wav")
		@snd_skids = Sample.new(@window, "audio/skid.wav")
		@snd_tinm  = Sample.new(@window, "audio/tinman.wav")
		@snd_ruby  = Sample.new(@window, "audio/ruby.wav")
		@snd_emrd  = Sample.new(@window, "audio/emerald.wav")
		@snd_sphr  = Sample.new(@window, "audio/sapphire.wav")
		@snd_metal = Sample.new(@window, "audio/metal_step.wav")
		@snd_flame = Sample.new(@window, "audio/whoosh.wav")
		@snd_throw = Sample.new(@window, "audio/next_level.wav")
		@snd_pipe  = Sample.new(@window, "audio/pipe.wav")
		@snd_clear = Sample.new(@window, "audio/course_clear.wav")
		@snd_gmovr = Sample.new(@window, "audio/game_over.wav")
		@snd_vctry = Sample.new(@window, "audio/victory.wav")
		@snd_evil  = Sample.new(@window, "audio/evil.wav")
		
		#TESTS
		#transformInto("_tinman")
		#transformInto("_fire")
		#transformInto("_bat")
	end
	
	#PRINT CLOCK INFORMATION HERE!!!
	def clock_display
	  seconds = @time   / 60
	  minutes = seconds / 60
	  
	  #CHANGE VALUES FOR DISPLAY...
	  seconds = seconds - (minutes*60)
	  
	  #FORMAT
	  min, sec = minutes, seconds
	  sec = "0"+seconds.to_s if seconds < 10
	  
	  #DISPLAY
	  return "#{min}:#{sec}" if @complete == false
	  return "--:--"         if @complete == true
	end
	
  def out_of_time? ; @time <= 60 ; end
  
  def time_running_out? ; @time < 1860 ; end
	
	def clock_tick? ; (@time/60)==(@time.to_f/60.0) && @time>1 ; end
	
	#RESET character
	def reset(level=nil,next_level=false)
  		@level      = level
  		@x, @y      = @level.start_x, @level.start_y
  		@vel_x = @vel_y = 0.0
  		@direction  = "right"
  		@alive      = true
  		@dead_y, @dead_vel_y = 0, 20
  		@win_y      = 0
  		@complete   = false
    	@agility, @grd_agility, @air_agility = 1.3, 1.3, 0.7 #Current agility value, ground agility, aerial agility
    	@friction   = 0.92
    	@jump_sen   = 8 # Jump velocity sensitivity. Depending on how long the key was held down...
    	@jump_rte   = @jump_sen
    	@jump_button_reset = true #WHEN the button is released (button_up id), set this to true...
    	@jump_air   = false
    	if next_level == false
      	  transformInto("") if @health < 1
      		@health     = 4
      		@health    += 4 if @level_super>0
    	end
    	@attck_time = 120
    	@time_attck = 0
    	@floating_numbers = []
    	@smoke = []
    	@axes  = []
    	@darkness = 90 if @window.LEVEL_THEME == "underground"
		  @darkness =   0 if @window.LEVEL_THEME != "underground"
		  @animation_depw, @px, @py = nil, @x, @y
		  @battling  = false
		  @time      = 7200
		  @fast_time = 0
		  @searcher  = false
      @scuba     = false
      @climbing  = @swimming = false
  end
	
	#RESET position
	def reposition(level=nil, returning=false)
		@level = level
		@scuba = @swimming = @climbing = false
		(@x, @y = @level.start_x, @level.start_y ; @vel_y = 1 ; @vel_x = 0) if returning == false
		(@x, @y = @level.return_x, @level.return_y ; @vel_y = -14 ; @vel_x = 6 * @flip_x) if returning == true
		@pipe_y, @time_attck = 0, 0
		@darkness = 90 if @window.LEVEL_THEME == "underground"
		@darkness =   0 if @window.LEVEL_THEME != "underground"
	end
	
	#HARD-CODE placement...
	def place(x=0, y=0)
		@x, @y = x, y
		@respond_delay = 30
	end
	
	#BATTLING
	def battle!
	  @battling = true
	end
	
	#STOP BATTLING
  def end_battle!
    @complete = true
    @snd_vctry.play
  end
  
  #BUY ITEMS
  def buy(item="",coins=0,rubies=0,emers=0,sapps=0)
    @coins     -= coins
    @rubies    -= rubies
    @emeralds  -= emers
    @sapphires -= sapps
    
    #Values below 0...
    @coins = 0 if @coins < 0
    @rubies = 0 if @rubies < 0
    @emeralds = 0 if @emeralds < 0
    @sapphires = 0 if @sapphires < 0
    
    #PLAY buy sound
    @snd_purc.play(1.25,0.9) if item != "level_exit"
    @flsh_timer = 15
    
    #CHANGE player state depending on bought item
    transformInto("_tinman")          if item =~ /tinman/
    transformInto("_bat")             if item =~ /zorro/
    @level_jump  += 1                 if item =~ /jump/
    @level_speed += 1                 if item =~ /speed/
    @level_axes  += 1                 if item =~ /ax/
    @level_cape  += 1                 if item =~ /fly/
    (@level_super += 1 ; @health = 8) if item =~ /double/
    replenish("full", nil)            if item =~ /health/
    @time += 3600                     if item =~ /clock/
    @searcher = true                  if item =~ /flashlight/
  end
	
	#WARNING: This is the COLLISION DETECTION of the character itself, not the level objects.
  	def free?(x,y)
  	  #Adjust collision because ducking changes height of character...
  	  duck_collision = @ducking_rate * 1000
  	    
    	#Top Left Corner
    	not @level.solid?(@x+x - @image_offset_x - @character.width/2, @y+y - @image_offset_y - @character.height/2 + duck_collision,@vel_y) and

    	#Top Right Corner
    	not @level.solid?(@x+x + @image_offset_x + @character.width/2, @y+y - @image_offset_y - @character.height/2 + duck_collision,@vel_y) and

    	#Halfway Top Right
    	not @level.solid?(@x+x + @image_offset_x + @character.width/2, @y+y - @image_offset_y - @character.height/4,@vel_y) and

    	#Center Right
    	not @level.solid?(@x+x + @image_offset_x + @character.width/2, @y+y,@vel_y) and
      
    	#Halfway Bottom Right
    	not @level.solid?(@x+x + @image_offset_x + @character.width/2, @y+y + @image_offset_y + @character.height/4,@vel_y) and
    	
    	#Bottom Right Corner
    	not @level.solid?(@x+x + @image_offset_x + @character.width/2, @y+y + @image_offset_y/5 + @character.height/2,@vel_y) and

    	#Bottom Left Corner
    	not @level.solid?(@x+x - @image_offset_x - @character.width/2, @y+y + @image_offset_y/5 + @character.height/2,@vel_y) and

    	#Halfway Bottom Left
    	not @level.solid?(@x+x - @image_offset_x - @character.width/2, @y+y + @image_offset_y + @character.height/4,@vel_y) and

    	#Center Left
    	not @level.solid?(@x+x - @image_offset_x - @character.width/2, @y+y,@vel_y) and
      
    	#Halfway Top Left
    	not @level.solid?(@x+x - @image_offset_x - @character.width/2, @y+y - @image_offset_y - @character.height/4,@vel_y)
  	end
  	
  	#FLAT-LINE collision
  	def free_below?(x,y)
  		if @vel_y.abs < 4
  	    	if @vel_x.abs > 14 ; skim = 25 ; else ; skim = 0 ; end
  	    else
  	    	skim = 0
  	    end
  	    
  		#Bottom Right Corner
    	not @level.solid?(@x+x + @image_offset_x + @character.width/2 + skim, @y+y + @image_offset_y/5 + @character.height/2, @vel_y) and
      
    	#Bottom Middle
    	not @level.solid?(@x+x, @y+y + @image_offset_y/5 + @character.height/2, @vel_y) and

    	#Bottom Left Corner
    	not @level.solid?(@x+x - @image_offset_x - @character.width/2 - skim, @y+y + @image_offset_y/5 + @character.height/2, @vel_y)
  	end

  	#Check if character is on ground
  	def on_ground
      	not free_below?(0,1)
  	end
  	
  	#TRY jump
  	def try_jump(key=nil)
  		if key and @jump_button_reset == true and @health > 0 && @complete == false && @level.auto_enter==false
  			@jump_rte -= 1 if on_ground
  			jump if @jump_rte < 1
  		end
  		
  		#FOR CLIMBING
      if @climbing == true && key
        @y-=4 if free?(0,-4)
        @clmb_dir = :vertical
      end
  	end
  	
  	#TRY run
  	def try_run(key=nil, key_r=nil, key_l=nil)
  		if key && (key_r || key_l) && @ducking_rate == 0.0
  			@max_speed = @max_run + (@level_speed * 2)
  		else
  			@max_speed = @max_walk + @level_speed
  		end
  	end
  	
  	#DUCK
  	def try_duck(key=nil)
  		if key && @level.auto_enter==false
  		  #FOR CLIMBING
        if @climbing == true
          @y+=4 if free?(0,4)
          @clmb_dir = :vertical
        else
  			  if @ducking_rate < 0.1
  				  @ducking_rate += 0.025
  			  else
  				  @ducking_rate = 0.1
  			  end
  			  @jump_rte = @jump_sen
  			end
  		else
  			if @ducking_rate > 0.0
  				@ducking_rate -= 0.025
  			else
  				@ducking_rate = 0.0
  			end
  		end
  		#AVOID head-stuck-in-block glitch...
      @ducking_rate = 0.0 if @vel_y<0
  	end
  	
  	#THROW AX/FIRE (Tinman or Fireman Only)
  	def throw_projectile
  	  if @level.auto_enter!=true
  	    #TINMAN
  	    if (@tinman==true and @axes.size<(2+@level_axes))
  			  @axes.push(ItemObject.new(@window, @x, @y, "ax", @vel_x.abs - @vel_y/2, @direction))
  			  @snd_throw.play(1, 1.5)
  			  @character = @animation_run[2]
  			  @throw_time = 12
  	    #FIREMAN  
  	    elsif (@fireman==true and @fireballs.size<3)
  	      if @direction=="right" ; vx=14 ; else ; vx=-14 ; end
          @fireballs.push(Fireball.new(@window, @x+(vx*2), @y, false, @level, vx, @vel_y/1.5))
          8.times { @smoke.push(Particle.new(@window, @x+(vx*3)+30-rand(60), @y+15-rand(30)+(@vel_y*4), -1.5, "flame")) }
          @snd_flame.play(2, 1.0)
          @character = @animation_run[2]
          @throw_time = 12
        end
      end
  	end
  	
  	#FLOAT (Zorro-Bat ONLY)
  	def float
  	  if @zorro_bat==true && (not on_ground)
  	    (@vel_y = -(@vel_x.abs+@level_cape);
  	    @float = 30;
  	    @snd_jump.play(1.0, 3.0);
  	    6.times { @smoke.push(Particle.new(@window, @x-25+rand(50), @y+rand(100), 0, "fairy_dust")) }) if @vel_y>-4 && @vel_x.abs>15-@level_cape
  	  end
  	end
  	
  	#JUMP
  	def jump
  		#Character can only jump when on the ground
  		if @complete == false && @level.auto_enter==false
  	 	  if (on_ground || @jump_air == false)
  	 		  # Jumping does vary depending on Anthony's speed, button-press longevity, etc...
      	  @vel_y = -@jump_vel + (@jump_rte * 2) + (@ducking_rate * 125) - (@vel_x.abs / 3.5) - (@level_jump * 2) if @jump_button_reset == true
      	  @snd_jump.play((-@vel_y/22) - 0.3) if @jump_button_reset == true && @health > 0 && @pipe_y==0 #Volume varies depending on Anthony's "jumping-ness"...
      	  @jump_rte = @jump_sen #Resets jumping ducking prep-ness...
          @jump_button_reset = false #TO prevent repetitive jumping by holding jump key down...
        end
      end
  	end
  	
  	#SWIM
  	def swim
  	  #Only when in water
      if @swimming==true && (not on_ground)
        #Water surface jump...
        if @y<@level.water_level+@level.tile_size/4 && @vel_y<5
          @vel_y = -24
          @snd_jump.play(0.8, 1.25)
        else
          #Regular swim stroke...
          (@vel_y = -12 ; @snd_jump.play(0.4, 2.2)) if @vel_y>-3 && @health>0
          @bubble_r-=40
        end
      end
  	end
  	
  	#BOUNCE
  	def bounce(key=nil)
  		@vel_y = -12
  		@vel_y = -28 if key #APPLIED ADDITIONAL PRESSURE
  		@snd_hitb.play if @health > 0
  		@snd_stomp.play(1.0, 0.6 + (@combo.to_f/25.0)) if @health > 0
  	end
  	
  	#SCORE
  	def score_add(points=0, enemy=nil)
  		if @combo<17
  			@score += points.to_i*@combo
  			@floating_numbers.push(ScoreJump.new(@window, enemy.x, enemy.y+20, "score", points.to_i*@combo)) if enemy!=nil
  		else
  		  max=4 ; max=8 if @level_super>0
  			if @health < max
  				replenish(1, enemy)
  			else
  				@score += points.to_i*@combo
  				@floating_numbers.push(ScoreJump.new(@window, enemy.x, enemy.y+20, "score", points.to_i*@combo)) if enemy!=nil
  			end
  		end
  	end
  	
  	#ADD COINS or other ITEM objects
  	def coin_add(type, count=1)
  	  if type == "coin"
  			@coins += count
  			@score += 25
  			@snd_coin.play if count==1
  	  elsif type == "clock_pickup"
  		  @time += 900 #ADDS 15 seconds of game time...
  		  @fast_time = 0
 			  @score += 25
 			  @snd_clock.play
 			elsif type == "fast_clock"
        @fast_time += count #Speeds time up!!!
        @snd_clock.play(2.0, 1.5)
        @snd_evil.play(1.25)
 		  elsif type == "heart_pickup"
  		  replenish(count, nil)
  		  @score += 50
  		elsif type == "heart_poison"
  		  vx=1 ; vx=-1 if @direction=="right"
        attacked(1, vx)
        @snd_poisn.play
      elsif type == "flashlight_pickup"
        @searcher = true
        @score += 1000
        @snd_light.play(2.0)
        @floating_numbers.push(ScoreJump.new(@window, @x, @y, "score", 1000))
      elsif type == "tinman_pickup"
     	  transformInto("_tinman")
      	@score += 1000
      	@floating_numbers.push(ScoreJump.new(@window, @x, @y, "score", 1000))
      elsif type == "zorro_pickup"
        transformInto("_bat")
        @score += 1000
        @floating_numbers.push(ScoreJump.new(@window, @x, @y, "score", 1000))
      elsif type == "fire_pickup"
        transformInto("_fire")
        @score += 5000
        @floating_numbers.push(ScoreJump.new(@window, @x, @y, "score", 5000))
 	    elsif type =~ /ruby|emerald|sapphire/
      	(@rubies+=count ; @snd_ruby.play ; value = 1000)    if type=="ruby"
      	(@emeralds+=count ; @snd_emrd.play ; value = 1000)  if type=="emerald"
      	(@sapphires+=count ; @snd_sphr.play ; value = 5000) if type=="sapphire"
      	@score += value
      	@floating_numbers.push(ScoreJump.new(@window, @x, @y, "score", value))
      else
      	#...
  		end
  	end
  	
  	#COMBO
  	def combo_add
  		@combo *= 2 if @combo<64
  	end
  	
  	#ATTACKED
  	def attacked(pain, velocity=2)
  	  #ATTACK FORCE!!!
      if @complete==false && @pipe_y==0
    		if @health > 0
    			@vel_y=-(8+velocity.abs) #Minor jump...
    			@vel_x=(10+velocity.abs/2)*pain
    			6.times { @smoke.push(Particle.new(@window, @x+20-rand(40), @y-32+rand(10), -@vel_x/2, "bubble")) } if @swimming==true
    		end
    		
    		#CHANGE health status...
    		@health -= pain.abs if @health > 0 && @tinman == false && @fireman == false && @zorro_bat == false
    		(@time_attck = @attck_time ; @snd_hurt.play)  if @health > 0
    		transformInto("") if @tinman    != false
    		transformInto("") if @fireman   != false
    		transformInto("") if @zorro_bat != false
      end
  	end
  	
  	#DIE
  	def die
  		@health -= 1
  		@searcher = false
  		if @health==-1
  			@snd_death.play(0.9)
  			@score = (@score/1000).to_i*250 #LOSE a quarter of your nearest thousands of points
  			(@score = 0 ; @game_over = true) if @score <= 0 #GAME OVER when score is less than 0
  		end
  		
  		#GET RID OF ANY KIND OF SUITS...
  		@tinman = false ; @fireman = false
  		
  		#GET RID OF OBJECTS THAT ARE GOING TO FORBIDDEN PLACES
  		@smoke.reject! { |smoke| smoke.out == true || (not @level.on_screen?(smoke.x, smoke.y, @window.camera_x, @window.camera_y, @window.screen_width, @window.screen_height)) }
  	end
  	
  	#DIE in a horrific way....
  	def die_horribly
  	  @attck_time = 0
  	  @searcher   = false
  		@health -= 9999
  		if @health==-9999
  			@score = (@score/1000).to_i*250 #LOSE a quarter of your nearest thousands of points
  			(@score = 0 ; @game_over = true) if @score <= 0 #GAME OVER when score is less than 0
  			@character = @animation_dieX[0]
  		end
  	end
  	
  	#REPLENISH
  	def replenish(gain, enemy)
  	  max=4 ; max=8 if @level_super>0
  	  if @health < max
  			@health += gain if gain != "full"
  			@snd_heart.play
  			@floating_numbers.push(ScoreJump.new(@window, enemy.x, enemy.y+20, "heart")) if enemy!=nil
  		end
  		#FULL HEALTH check
  		@health = max if @health >= max || gain == "full"
  	end
  	
  	#HEAT UP!
  	def heat_up
  	  @heat += 1
  	  transformInto("_fire") if @heat > 4
  	end
  	
  	def transformInto(type)  	    
  		@animation_idle = Image.load_tiles(@window, "artwork/anthony/idle#{type}.png", 112, 210, false)
		  @animation_idle.push(@animation_idle[1]) # Adding extra frame to adjust animation
		  @animation_depw, @px, @py = @animation_run[1], @x, @y
		  @animation_run  = Image.load_tiles(@window, "artwork/anthony/run#{type}.png", 112, 210, false)
		  @animation_run.push(@animation_run[1]) # Adding extra frame to adjust animation
		  @animation_jump = Image.load_tiles(@window, "artwork/anthony/jump#{type}.png", 112, 210, false)
		  @animation_duck = Image.load_tiles(@window, "artwork/anthony/duck#{type}.png", 112, 210, false)
		  @animation_clmb = Image.load_tiles(@window, "artwork/anthony/climb#{type}.png", 112, 210, false)
      @animation_clmb.push(@animation_clmb[1]) # Adding extra frame to adjust animation
      @animation_swim = Image.load_tiles(@window, "artwork/anthony/swim#{type}.png", 112, 210, false)
      @animation_swim.push(@animation_swim[1]) # Adding extra frame to adjust animation
		
		  if type == "_tinman"
		    @flsh_timer = 12
  	    @tinman = true
  	    @fireman = false
  	    @zorro_bat = false
  	    @animation_depw = @animation_run[1]
  	    #SMOKE EFFECT
  	    #------------------------------------------------------------
  	    @smoke.push(Particle.new(@window, @x-20, @y-20, -2, "smoke"))
      	@smoke.push(Particle.new(@window, @x-20, @y, -3, "smoke"))
    	  @smoke.push(Particle.new(@window, @x-20, @y+30, -2, "smoke"))
    	  @smoke.push(Particle.new(@window, @x+20, @y-20, 2, "smoke"))
    	  @smoke.push(Particle.new(@window, @x+20, @y, 3, "smoke"))
    	  @smoke.push(Particle.new(@window, @x+20, @y+30, 2, "smoke"))
    	  @smoke.push(Particle.new(@window, @x-5, @y-5, -1, "smoke"))
    	  @smoke.push(Particle.new(@window, @x-5, @y, -1, "smoke"))
    	  @smoke.push(Particle.new(@window, @x-5, @y+15, -1, "smoke"))
    	  @smoke.push(Particle.new(@window, @x+5, @y-5, 1, "smoke"))
    	  @smoke.push(Particle.new(@window, @x+5, @y, 1, "smoke"))
    	  @smoke.push(Particle.new(@window, @x+5, @y+15, 1, "smoke"))
    	  @smoke.push(Particle.new(@window, @x, @y-5, -1, "smoke"))
    	  @smoke.push(Particle.new(@window, @x, @y, -1, "smoke"))
    	  @smoke.push(Particle.new(@window, @x, @y+5, -1, "smoke"))
    	  @smoke.push(Particle.new(@window, @x, @y-5, 1, "smoke"))
    	  @smoke.push(Particle.new(@window, @x, @y, 1, "smoke"))
    	  @smoke.push(Particle.new(@window, @x, @y+5, 1, "smoke"))
    	  #------------------------------------------------------------
  	    @gravity  = 1.2
  	    @strength = 8
  	    @max_walk = 7.0
  	    @max_run  = 14.0
  	    @jump_vel = 32
  	    @snd_tinm.play
  	    @time_attck = 0
  	  elsif type == "_fire"
        @flsh_timer = 8
        @fireman    = true
        @tinman     = false
        @zorro_bat  = false
        @animation_depw = @animation_run[1]
        #FIRE EFFECT
        #------------------------------------------------------------
        @smoke.push(Particle.new(@window, @x-20, @y-20, -1.5, "flame"))
        @smoke.push(Particle.new(@window, @x-20, @y, -1.5, "flame"))
        @smoke.push(Particle.new(@window, @x-20, @y+30, -1.5, "flame"))
        @smoke.push(Particle.new(@window, @x+20, @y-20, -1.5, "flame"))
        @smoke.push(Particle.new(@window, @x+20, @y, -1.5, "flame"))
        @smoke.push(Particle.new(@window, @x+20, @y+30, -1.5, "flame"))
        @smoke.push(Particle.new(@window, @x-5, @y-5, -1.5, "flame"))
        @smoke.push(Particle.new(@window, @x-5, @y, -1.5, "flame"))
        @smoke.push(Particle.new(@window, @x-5, @y+15, -1.5, "flame"))
        @smoke.push(Particle.new(@window, @x+5, @y-5, -1.5, "flame"))
        @smoke.push(Particle.new(@window, @x+5, @y, -1.5, "flame"))
        @smoke.push(Particle.new(@window, @x+5, @y+15, -1.5, "flame"))
        @smoke.push(Particle.new(@window, @x, @y-5, -1.5, "flame"))
        @smoke.push(Particle.new(@window, @x, @y, -1.5, "flame"))
        @smoke.push(Particle.new(@window, @x, @y+5, -1.5, "flame"))
        @smoke.push(Particle.new(@window, @x, @y-5, -1.5, "flame"))
        @smoke.push(Particle.new(@window, @x, @y, -1.5, "flame"))
        @smoke.push(Particle.new(@window, @x, @y+5, -1.5, "flame"))
        #------------------------------------------------------------
        @gravity    = 0.9
        @strength   = 13
        @max_walk   = 8.0
        @max_run    = 18.0
        @jump_vel   = 28
        @heat       = 0
        2.times { @snd_flame.play(2.0) }
        @time_attck = 0
      elsif type == "_bat"
        @flsh_timer = 12
        @fireman    = false
        @tinman     = false
        @zorro_bat  = true
        @animation_depw = @animation_run[1]
        #SMOKE EFFECT
        #------------------------------------------------------------
        @smoke.push(Particle.new(@window, @x-20, @y-20, -3, "smoke"))
        @smoke.push(Particle.new(@window, @x-20, @y, -4, "fairy_dust"))
        @smoke.push(Particle.new(@window, @x-20, @y+30, -3, "smoke"))
        @smoke.push(Particle.new(@window, @x+20, @y-20, 3, "fairy_dust"))
        @smoke.push(Particle.new(@window, @x+20, @y, 4, "smoke"))
        @smoke.push(Particle.new(@window, @x+20, @y+30, 3, "fairy_dust"))
        @smoke.push(Particle.new(@window, @x-5, @y-5, -2, "smoke"))
        @smoke.push(Particle.new(@window, @x-5, @y, -2, "fairy_dust"))
        @smoke.push(Particle.new(@window, @x-5, @y+15, -2, "smoke"))
        @smoke.push(Particle.new(@window, @x+5, @y-5, 2, "fairy_dust"))
        @smoke.push(Particle.new(@window, @x+5, @y, 2, "smoke"))
        @smoke.push(Particle.new(@window, @x+5, @y+15, 2, "fairy_dust"))
        @smoke.push(Particle.new(@window, @x, @y-5, -2, "smoke"))
        @smoke.push(Particle.new(@window, @x, @y, -2, "fairy_dust"))
        @smoke.push(Particle.new(@window, @x, @y+5, -2, "smoke"))
        @smoke.push(Particle.new(@window, @x, @y-5, 2, "fairy_dust"))
        @smoke.push(Particle.new(@window, @x, @y, 2, "smoke"))
        @smoke.push(Particle.new(@window, @x, @y+5, 2, "fairy_dust"))
        #------------------------------------------------------------
        @gravity    = 0.75 - @level_cape.to_f/20.0
        @strength   = 15
        @max_walk   = 10.0
        @max_run    = 20.0
        @jump_vel   = 27
        @snd_tinm.play(0.4, 1.5)
        3.times { @snd_flame.play(2.0, 0.8) }
        @time_attck = 0
  	  else
  	    @flsh_timer = 7
  	    @tinman     = false
  	    @fireman    = false
  	    @zorro_bat  = false
  	    @gravity    = 0.9
    		@strength   = 13
    		@max_walk   = 8.0
    		@max_run    = 18.0
    		@jump_vel   = 28
    	end
  	end
  	
  	def fully_healed?
  	  if @level_super < 1
  		  @health > 3
  		else
  		  @health > 7
  		end
  	end
  	
  	#Physics code
  	def physics
      	#FRICTION
      	@vel_x *= @friction
      
      	#GRAVITY - (SWIMMING and WALKING)
      	if @vel_y<=@max_grv
      	  if @climbing==false
      	    if @swimming==true
      	      if @vel_y<5 ; @vel_y+=@gravity/3 ; else ; @vel_y/=1.07 ; end
              @vel_x /= 1.125 if @vel_x.abs>(1+@vel_y.abs)
              @vel_y /= 1.03  if @vel_y<-1
              @vel_y += 0.475 if @ducking_rate > 0
      	    else
      	      @vel_y += @gravity
      	    end
      	  end
      	else
      	  @vel_y = @max_grv
      	end
      	
      	#AGILITY
      	if on_ground
          	@agility = @grd_agility - @vel_x.abs/200 #Make agility better on ground...
          	@friction = 0.90 + (@vel_x.abs / 400) + (@ducking_rate.abs.to_f / 2.25)
          	
          	#Sound effect upon landing
          	if @jump_air == true && @level.auto_enter==false
          		@snd_hitg.play(0.3, 0.9) if @ducking_rate==0
          	end
          	
          	@jump_air = false
          	@combo = 1
          	@float = 0
          	
          	#SKIDDING
          	if (((@direction=="right" and @vel_x < -7)      || (@direction=="left" and @vel_x > 7)) ||
          	   (@vel_x.abs > 7       and @ducking_rate!=0) && @level.auto_enter==false) && @swimming==false
      	      #@smoke.push(Particle.new(@window, @x + @vel_x, @y+100, @vel_x/5, "smoke"))
      	      @smoke.push(Particle.new(@window, @x - @vel_x/2, @y+100, @vel_x/4, "smoke")) if @ducking_rate==0
      	      @smoke.push(Particle.new(@window, @x + @vel_x, @y+100, @vel_x/4, "smoke"))
      	      @snd_skids.play(@vel_x.abs/12.0) if (@flip_x.abs == 0.725 || @vel_y.abs > 1 || @ducking_rate == 0.05) and (@time_attck<120 and free?(0,-1))
      	    end
      	    
      	    #FORCE-STOP when movements are too minor...
      		  @vel_x = 0 if @vel_x.abs < 0.75
      	else
            #Harder to change direction mid-air...
            @agility = @air_agility - @vel_x.abs/50
            @friction = 0.999
            @float -= 1
            
            #AUTO-JUMP: Character is trying to jump the very edge of the tile...
            (jump ; @jump_rte = @jump_sen) if @jump_rte < @jump_sen
             #MAKE sure that he doesn't TRY to jump mid-air again...
            @jump_air = true
      	end
      
      	#POSITION/MOVEMENT CHECK
      	if @vel_x > 0
          	(@vel_x.to_i).times do
              	if free?(1,0) #If character is free 1 pixel to the RIGHT
                  	@x+=1
                  	@climbing = false
              	else
                  	@vel_x = 0 #Otherwise, stop moving that F-ING character!!!
              	end
          	end
      	end
      
      	if @vel_x < 0
          	(-@vel_x.to_i).times do
              	if free?(-1,0) #If character is free 1 pixel to the LEFT
                  	@x-=1
                  	@climbing = false
              	else
                  	@vel_x = 0 #Otherwise, stop moving that F-ING character!!!
              	end
          	end    
      	end
      
      	if @vel_y >= 0
          	(@vel_y.to_i).times do
              	if free_below?(0,1) #If character is free 1 pixel DOWN
                  	@y+=1
              	else
                  	@vel_y = 0 #Otherwise, stop FALLING!!!
              	end
          	end
      	end
      	
      	if @vel_y < 0
          	(-@vel_y.to_i).times do
              	if free?(0,-1) #If character is free 1 pixel UP
                  	@y-=1
              	else
              	  if @y+15<@level.height*@level.tile_size
              	    #Possible positions to interact with tile...
              	    #RIGHT...
              	    if @x+20<@level.width*@level.tile_size
              	    	@level.remove_tile(@x+20, @y - @character.height / 2)
              	    	@level.remove_tile(@x+20, @y + 24)
              	    	@level.remove_tile(@x+20, @y + 92)
              	    end
              	    
              	    #LEFT...
              	    if @x>20
              	    	@level.remove_tile(@x-20, @y - @character.height / 2)
              	    	@level.remove_tile(@x-20, @y + 24)
              	    	@level.remove_tile(@x-20, @y + 92)
              	    end
              	    
              	    #ANYWHERE...
              	    @level.remove_tile(@x, @y - @character.height / 2)
              	    @level.remove_tile(@x, @y + 24)
              	    @level.remove_tile(@x, @y + 92)
              	  end
              	  #PLAY sound and SET velocity to zero...
                  @snd_hitb.play(-@vel_y/40)
                  @vel_y = 0
              	end
          	end
      	end
      	
      	#WATER-SWIMMING ATTRIBUTES
      	if @y > (@level.water_level-@level.tile_size)
      	  #SPLASH EFFECT
      	  if @swimming==false
      	    @snd_splsh.play(@vel_y.abs/45.0, 0.6+(rand(30.0)/100.0))
      	    @snd_splsh.play(@vel_y.abs/35.0, 1.1)
      	    @window.switch_song("underwater") if @scuba==false && @level.type=="obstacle" && @level.water_level<(@level.height*@level.tile_size)-500
      	    4.times do
      	      @smoke.push(Particle.new(@window, @x-25-rand(5), @y+46,-5, "water"))
      	      @smoke.push(Particle.new(@window, @x+25+rand(5), @y+46, 5, "water"))
      	    end
      	  end
      	  @smoke.push(Particle.new(@window, @x+5-rand(10), @y-32, @vel_x, "bubble")) if (@vel_y>=7 && @y>@level.water_level && @bubble_m<=0) || @bubble_r<=0
      	  @bubble_m=rand(5) if @bubble_m<=0 && @swimming==true
      	  @bubble_r=rand(250) if @bubble_r<=0
      	  @scuba = true
      	  
      	  #BUBBLE TRAIL
      	  if @vel_y>9 && @bubble_m<=1 
      	    @smoke.push(Particle.new(@window, @x-25-rand(5),  @y+92,-2-rand(3), "bubble"))
      	    @smoke.push(Particle.new(@window, @x+25+rand(5),  @y+92, 2+rand(3), "bubble"))
      	    @smoke.push(Particle.new(@window, @x+10-rand(20), @y+92, 2-rand(4), "bubble"))
      	  end
      	  #UPWARD MOVEMENT
      	  if @vel_y<-12 && @bubble_m<=1 
            @smoke.push(Particle.new(@window, @x-20-rand(5),  @y+80,-2-rand(3), "bubble"))
            @smoke.push(Particle.new(@window, @x+20+rand(5),  @y+80, 2+rand(3), "bubble"))
          end
      	  @swimming = true if @bubble_m<=1
      	  @bubble_m -= 1 ; @bubble_r -= 1
      	else
      	  if @swimming==true
      	    @snd_splsh.play(@vel_y.abs/30, 1.2)
      	    3.times do
              @smoke.push(Particle.new(@window, @x-25-rand(5), @y+92,-1, "water"))
              @smoke.push(Particle.new(@window, @x+25+rand(5), @y+92, 1, "water"))
            end
            @swimming = false
          else
            if on_ground && @scuba==true && @y<(@level.water_level-@level.tile_size*3) &&
              @level.shore?(@x-92,@y+112) && @level.shore?(@x,@y+112) && @level.shore?(@x+92,@y+112)
              @window.switch_song(@window.LEVEL_THEME)
              @scuba = false
            end
      	  end
      	  @bubble_m=1
      	end
      	
      	#ATTACKED DELAY TIME
      	@time_attck -= 1 if @time_attck > 0
      	
      	#ATTACKED from below
      	if @level.block_hit?(@x,@y+150) && on_ground
          attacked(1, 3) if @direction=="left"
          attacked(1,-3) if @direction=="right"
        end
        
        #STUCK repair (inside solid object) - [ "glitch push" ]
        @x -= 2 if (not free?(0,1)) && (not free?(0,-1))
        
      	#WIN LEVEL
      	((@snd_clear.play;@flsh_timer=16) if @complete == false;
      	@complete     = true;
      	@time         = 7200;
      	@ducking_rate = 0.0;
      	@jump_rte     = @jump_sen;
      	@direction    = "left" if @vel_x == 0;
      	@searcher     = false;
      	@win_y       += (@win_y/11)-0.0001 if @flip_x == -1) if (distance(@x-100, @y-100, @level.finish_x, @level.finish_y)<175 && on_ground) || @complete==true || @win_y!=0
  	end
  	
  	def escaped_level?
  		@y + @win_y < -100 if @complete == true
  	end
  	
  	def heart_avail?(c=nil)
  		(not (fully_healed? and c.type=="heart_pickup")) ||
  		c.type!="heart_pickup"
  	end
	
	def update
		#PHYSICS
		physics if @health > 0 && @pipe_y.abs < 3
		
		#TRY entering pipe downwards...
      	if on_ground and (@level.pipe?(@x - 48, @y + @character.height/2)) and @ducking_rate>0
      		@pipe_y += 4
      		@snd_pipe.play if @pipe_y == 4
      		@y += 2
      		@vel_x = @vel_y = 0
      	end
      	
      	#TRY entering pipe upwards...
      	if (@level.pipe?(@x - 48, @y - @character.height/2)) && @vel_y < 0
      		@pipe_y -= 4
      		@snd_pipe.play if @pipe_y == -4
      		@y -= 2
      		@vel_x = 0
      	end
      	
      	@character = @animation_duck[0] if @pipe_y>0
      	@character = @animation_jump[0] if @pipe_y<0
      	try_duck(true)                  if @pipe_y!=0
      	
    #FORCE enter castle...
    if @level.auto_enter==true
      @vel_x = 6
      @jump_rte = @jump_sen
      @direction = "right"
      if @level.entry_opener == 0
        @x = @level.entry_coords[0] + 420
        @y = @level.entry_coords[1] - 200
      end
    else
      if @time>0 && @window.transition.completely_opened? && @complete==false && @health>0 && @level.type!="dr_marcoux"
        (1 + (@fast_time * 2)).times do
          @time -= 1
          if (@time/60)==(@time.to_f/60.0) && @time>1
            @snd_beep.play(0.8)      if @time <= 660
            @snd_ring.play(2.0)      if out_of_time?
            @snd_beep.play(2.0, 2.5) if @fast_time>0
          end
        end
      end
    end
    
    #This is a timer for delaying the user's control of the character (transitions, going thru doors, etc.)...
    @respond_delay -= 1 if @respond_delay > 0
    @time           = 0 if @time          < 1
		
		#COINS, PARTICLES, and other destroyable objects...
		@level.coins.reject! do |c|
			if (distance(c.x,c.y,@x,@y+44)<72 || distance(c.x,c.y,@x,@y-72+(@ducking_rate*1000))<72) && c.type!="vine_growth" && heart_avail?(c)
				coin_add(c.type)
				7.times { @smoke.push(Particle.new(@window, c.x+25-rand(50.0), c.y-25+rand(50.0), 0, "fairy_dust")) }
			end
		end
		
		#VINE-CLIMBING ATTRIBUTES
		if @swimming==false
      @level.coins.each do |vine|
        if vine.type == "vine_growth"
          if (@x > vine.x - 50) && (@x < vine.x + 50) && (@y < vine.y + 50) && (@y > vine.y - vine.growth_height)
            @climbing = true
            @vel_x /= 1.25
            @vel_y /= 1.25
            @clmb_dir = :idle
            @ducking_rate = 0.0
          end
        end
      end
    end
		
		#REJECT objects when not needed...
		@smoke.reject! { |smoke| smoke.out == true ||
		             (not @level.on_screen?(smoke.x, smoke.y, @window.camera_x, @window.camera_y, @window.screen_width, @window.screen_height)) }
		             
	  @axes.reject! { |ax| ax.x < (@window.camera_x-100) || ax.x > (@window.camera_x+@window.screen_width+100) ||
	    					 ax.y > (@window.camera_y+@window.screen_height+92) }
	    					 
	  @fireballs.reject! { |fire| fire.x < (@window.camera_x-320) || fire.x > (@window.camera_x+@window.screen_width+320) ||
                 fire.y > (@window.camera_y+@window.screen_height+320) || fire.out_duration<1 }
                 
	  @floating_numbers.reject! { |number| number.x if number.peak || @health < 1 ||
	                                       number.x < @window.camera_x - 25 || number.x > (@window.camera_x + @window.screen_width + 25) ||
	                                       number.y < @window.camera_y - 25 || number.y > (@window.camera_y + @window.screen_height + 25)}
		
		#WEAPONS...
		@axes.each { |ax| ax.update }
		@fireballs.each { |fire| fire.update ; fire.kill if @level.light_torch(fire.x,fire.y) || fire.y >= (@level.height*@level.tile_size)-46 }
	end
	
	def draw(scr_x, scr_y)
		# CHECK direction and ANIMATE flip!
		if @climbing == true
		  @flip_x =  1 if @direction == "right"
      @flip_x = -1 if @direction == "left"
		else
		  @flip_x +=  0.275 if @direction == "right" && @flip_x <  1
		  @flip_x += -0.275 if @direction == "left"  && @flip_x > -1
		  @flip_x =  1 if @flip_x >  1
      @flip_x = -1 if @flip_x < -1
		end
		
		#CHANGE Z-ORDER when entering a pipe!!!
		z =  1 if @pipe_y.abs < 1
		z = -1 if @pipe_y.abs > 0 || @level.auto_enter==true
		z = 5  if @health < -900
		
		# DRAW the character
		# PARAMETERS: (x, y, z, rotation, origin_x, origin_y, scale_x, scale_y, color, color_mode)
		@character.draw_rot(@x.to_i - scr_x, @y.to_i - scr_y + (@character.height/2) + @dead_y + @win_y.to_i + @pipe_y, z,
							0, 0.5, 1.0, @flip_x - (@flip_x*@pipe_y.abs.to_f/200), 0.5 + (@jump_rte/16.0) - @ducking_rate, @color, @color_m)
		
		#GLOW if fireman					
		@glow.draw_rot(@x.to_i - scr_x, @y.to_i - scr_y - 50 + @win_y.to_i + @pipe_y, z, 0, 0.5, 0.5, 1, 1, 0x40ff8800, :additive) if @fireman==true && @pipe_y==0
							
		#FLASHLIGHTs only exist underground...
		if @window.LEVEL_THEME=="underground" && @searcher==false
		  #DARKNESS/BRIGHTNESS adjustments...
		  brightness = 0
		  
		  #CHECK each torch...
		  for t in 0..@level.torches.size-1
		    if distance(@x,@y,@level.torches[t].x,@level.torches[t].y)<1000 && @level.torches[t].out==false
		      brightness = 8.0 - distance(@x,@y,@level.torches[t].x,@level.torches[t].y).to_f/100.0
		    end
		  end
		  
		  #Re-establish values...
		  brightness = 0.0  if brightness <= 0
		  offset_y   = 0
		  offset_y   = @y.abs if @y <= 0
		  
		  #DRAW the "darkness"...
			@flashlight.draw_rot(@x.to_i - scr_x, @y.to_i - scr_y + offset_y, 5, 0, 0.5, 0.5, 3.5 + brightness, 3.5 + brightness) if @flsh_timer==0
		end
							
		#CHANGE look when attacked!
		if @time_attck != 0
		  @color.red   = 255
			@color.blue  = 255 - ((@time_attck*2))
			@color.green = 255 - ((@time_attck*2))
			@animation_depw=nil if @time_attck < 2
			if @animation_depw!=nil
			    transparency = Color.new((@time_attck*2),255-@darkness,255-@darkness,255-@darkness)
				@animation_depw.draw_rot(@px - scr_x, (@py + (@character.height/2) - @attck_time*3 + @time_attck*3 - scr_y), 2, 0, 0.5, 1.0, 1, 1, transparency, :additive)
			end
		else
			@color.blue  = 255# - @darkness
			@color.green = 255# - @darkness
			@color.red   = 255# - (@darkness/1.25).to_i
		end
							
		#DRAW dem particles!!!
		@floating_numbers.each { |number| number.draw(scr_x, scr_y) }
		@smoke.each { |smoke| smoke.draw(scr_x, scr_y, Color.new(0xffffffff), @level.hour);
					smoke.out==true if @level.on_screen?(smoke.x,smoke.y,scr_x,scr_y,@window.screen_width,@window.screen_height) } if @smoke.size>0
		@axes.each { |ax| ax.draw(scr_x, scr_y, 0xffffffff) } if @axes.size>0
		@fireballs.each { |fire| fire.draw(scr_x, scr_y, z) } if @fireballs.size>0
		
		# IMPLEMENT ANIMATIONS
		# -------------------------------------
		if @vel_y < 0 || @win_y.abs > 0.25 # JUMP or CELEBRATION pose
			@character = @animation_jump[milliseconds / 100 % @animation_jump.size]
      
      #LEVEL ending...
			if not escaped_level?
			  if @fireman==false
				  3.times { @smoke.push(Particle.new(@window, @x+25-rand(50.0), @y+@win_y+rand(50.0)+70, 0, "fairy_dust")) } if @win_y.abs > 3
				  @smoke.push(Particle.new(@window, @x+12.5-rand(25), @y+@win_y+rand(25)+75, 1-rand(2), "smoke")) if @win_y.abs > 4
				else
				  4.times { @smoke.push(Particle.new(@window, @x+12.5-rand(25), @y+@win_y+rand(25)+75, 9, "flame")) } if @win_y.abs > 0
				  (@level.shake(7) ; @win_y += 0.2) if @win_y.abs>4 && @win_y.abs<200
				end
			end
		elsif @vel_x.abs > 0.75 and on_ground # WALK / RUN
			# Rate variation based on player's speed
			@animate_timer += 1 if @animate_timer < (@animate_freq - (@vel_x.abs/1.3))
			(@current_frame += 1; @animate_timer = 0)  if @animate_timer >= (@animate_freq - (@vel_x.abs/1.3))
			@current_frame = 0  if @current_frame >= 4
			# Set Animation
			@character = @animation_run[@current_frame]
			# Implement walking/running sounds and particles
			if (@current_frame==1 || @current_frame==3) and @animate_timer==1
			  #TINMAN
				@snd_metal.play(1, 0.9 + rand(0.25)) if @tinman==true && @swimming==false
			end
		elsif @vel_y >= 0 and (not on_ground) # "FALLING"
			@character = @animation_run[0]
		else # IDLE
			@character = @animation_idle[milliseconds / 100 % @animation_idle.size] if @vel_x==0
		end
		
		#PRIORITIZED ANIMATION...
		if @ducking_rate != 0 || @time_attck > 100 # DUCK or ATTACKED
			@character = @animation_duck[0]
			#No funny actions when message displays...
      @ducking_rate = 0.0 if @level.msg_ACT==true
		end
		
		#CLIMB ANIMATION
		if @climbing == true
		  if @clmb_dir == :vertical
		    @character = @animation_clmb[milliseconds / 100 % @animation_clmb.size]
		  elsif @clmb_dir == :horizontal
		    @character = @animation_clmb[milliseconds / 150 % 2]
		  elsif @clmb_dir == :idle
		    @character = @animation_clmb[1]
		  end
		end
		
		#SWIM ANIMATION
    if @swimming==true && (not on_ground) && @attck_time>10
      @climbing = false
      if @vel_y<13
        if @vel_y>-3
          @character = @animation_swim[milliseconds / 250 % @animation_swim.size]
        elsif @vel_y>-12
          @character = @animation_swim[milliseconds / 70.0 % @animation_swim.size]
        end
      end
    end
		
		#THROW ANIMATION
		if @throw_time > 0
		  if @climbing == true
		    @character = @animation_clmb[0]
		  else
			  @character = @animation_run[(@throw_time/@animation_run.size).to_i - 1]
			end
			@throw_time -= 1
		end
		
		#FLY ANIMATION
		if @float > 0
		  @character = @animation_fly[milliseconds / 70.0 % @animation_fly.size]
		end
		
		#DEAD ANIMATION
		if @health < 1
      @dead_timer -= 1
			@vel_x = @vel_y = 0
			@jump_rte = 8
			@ducking_rate = 0
			@attck_time = 120
    	@time_attck = 0
    	@floating_numbers = []
			@climbing = false
      if @dead_timer<1
  			if @dead_y < 5000
  				@dead_y -= @dead_vel_y.to_i
  				@dead_vel_y -= 1
  			else
  				@alive = false ; @dead_timer = 38
  			end
  			(@alive = false ; @dead_timer = 38) if @dead_y > 3000 && @health < -998
      end
			
			@character = @animation_dead[0] if @health > -999 #Normal death...
			(@character = @animation_dieX[0] ; @dead_vel_y/=1.025) if @health < -998 #Creepy death!!!
		end
		
		#FLASH ANIMATION "Get it?" ;-)
		if @flsh_timer > 0
		  @flsh_color.alpha = (@flsh_timer-6).abs*21
			@transform_flsh.draw(0,0,-1,4,4,@flsh_color,:additive)
			@flsh_timer-=1
		end
		
		#UPDATE best current round score
		@hiscore = @score if @hiscore < @score
	end
	
	#DRAW separately for hearts...
	def draw_hearts(x,y,z=999)
		#EMPTY HEARTS...
		@heart[1].draw(x+00,y,z)
		@heart[1].draw(x+36,y,z)
		@heart[1].draw(x+72,y,z)
		@heart[1].draw(x+108,y,z)
		
		#FULL HEARTS...
		@heart[0].draw(x+00,y,z+1) if @health>0
		@heart[0].draw(x+36,y,z+1) if @health>1
		@heart[0].draw(x+72,y,z+1) if @health>2
		@heart[0].draw(x+108,y,z+1) if @health>3
		
		#DOUBLE HEARTS...
    @heart[2].draw(x+00,y,z+1) if @health>4
    @heart[2].draw(x+36,y,z+1) if @health>5
    @heart[2].draw(x+72,y,z+1) if @health>6
    @heart[2].draw(x+108,y,z+1) if @health>7
	end
	   
  	#Move
  	def move(direction="right")
      	#If the player hits the "Right" key and the velocity is less than the character's maximum speed...
      	@vel_x += 1.0 * @agility if direction=="right" && @vel_x < @max_speed * @agility && @ducking_rate < 0.025
      
      	#If the player hits the "Left" key and the velocity is less than the character's maximum speed...
      	@vel_x -= 1.0 * @agility if direction=="left" && @vel_x > -@max_speed * @agility && @ducking_rate < 0.025
      	
      	@vel_x = @max_speed if @vel_x > @max_speed
      	@vel_x = -@max_speed if @vel_x < -@max_speed
      	
      	#FOR CLIMBING
      	if @climbing == true
      	    @x+=4 if direction=="right" && free?(4,0)
      	    @x-=4 if direction=="left"  && free?(-4,0)
      	    @clmb_dir = :horizontal
      	end
  	end

  	#Movement on key press...
  	def move_direction(direction="right", key=nil)
      	if key && @time_attck<100 && @complete==false && @level.auto_enter==false && @respond_delay<1
          	move(direction) #Assigning the actual keys to each of the character's actions.
          	@direction = direction #Change the visual's direction
      	end
  	end
end



#ADDITIONAL CLASSES---------------------------------------------------------------------------------

#USEFUL for spawning enemies and other objects
class Spawner
	attr_reader :x,:y,:type,:quest
	def initialize(x=0,y=0,type="goomba",quest=false)
		@x,@y,@type,@quest=x,y,type,quest
	end
end

#SCORE POP-UP
class ScoreJump
	attr_reader :x, :y, :score
	def initialize(window,x=0,y=0,type="score",score=100)
		@window,@x,@y,@score,@type,@float_y,@size=window,x,y,score,type,0,1
		@font = Font.new(window, "Arial", 24)
		@heart = Image.load_tiles(window, "artwork/inventory/heart.png", 36, 36, false)[0]
		@color1, @color2 = Color.new(0xffffff00), Color.new(0xff000000)
		
		#COLOR change based on score made...
		if @type=="score"
			@color1.green = 255 if @score == 100
			@color1.green = 150 if @score == 200
			@color1.green = 100 if @score == 400
			@color1.green = 50  if @score == 800
			@color1.green = 0   if @score >= 1600
			(@color1 = Color.new(0xffffff99) ; @size = 1.5) if @score >= 5000 || @score == 1000 || @score == 2000 || @score == 3000
		else
			@color1.red = 200
			@color1.blue = 255
		end
	end
	
	def peak
		@color1.alpha < 4
	end
	
	def eliminate
		@color1.alpha = 3 ; @color2.alpha = 3
	end
	
	def draw(sx,sy)
		@font.draw("#@score", @x-sx, @y-@float_y-sy, 2, @size, @size, @color1)        if @type=="score"
		@font.draw("#@score", @x-sx+1, @y-@float_y-sy+1, 1.9, @size, @size, @color2)  if @type=="score"
		@heart.draw_rot(@x-sx, @y-@float_y-sy, 2, 0, 0.5, 0.5, 1, 1, @color1)         if @type=="heart"
		@float_y+=2
		@color1.alpha -= 2 if @color1.alpha > 2
		@color2.alpha -= 2 if @color2.alpha > 2
	end
end

#ENEMY class
class Enemy
	attr_reader :x, :y, :type, :vel_x, :vel_y,
	            :direction, :original_x, :original_y,
	            :squished, :kicked, :fuck_x, :fuck_y,
	            :timer, :combo, :squash_h, :collision_factor, :health
	
	def initialize(window, x=0, y=0, type="goomba",level=nil,quest=false)
		@window, @level = window, level
		
		# X, Y and other positional attributes ...
		@x, @y, @vel_x, @vel_y, @type = x, y, 0.0, 0.0, type
		
		#SAVE start spot!
		@original_x, @original_y, @quest = @x, @y, quest
		
		#General physical attributes
    	@gravity = 0.9
    	@max_grv = 30
    	@max_speed = 3
    	@walk_spd  = 3
    	@shell_spd = 17
    	@chase_spd = 5
    	@combo = 1
    	@release = true #-THWOMP
    	@health  = 0
    	@std_mpf = 100 #STANDARD Milliseconds per Frame (ordinary animations only)
    	
    	#ATTACKED variables
    	@squished = false
    	@delay = 300
    	@timer = 0
    	@kicked = false #-KOOPA
    	@squash_h = 0.0
    	@dead_x, @dead_y = 0, 0, 0
    	@snd_dsty   = Sample.new(@window, "audio/enemy_destroy.wav")
    	@snd_impt   = Sample.new(@window, "audio/ceiling_hit.wav")
    	@snd_smash  = Sample.new(@window, "audio/break_block.wav")
    	@snd_kick   = Sample.new(@window, "audio/kick.wav")
    	
    	@direction = "right" if window.character.x > @x
    	@direction = "left" if window.character.x < @x
		
		#COLLISION offset
    @image_offset_x, @image_offset_y = -20, -6
    @collision_factor = 0
    
    #SIDE offset
    @offset_top = -50
		
		# ANIMATION images... (default attributes)
		img_size = 92
    @font = Font.new(window, "Monaco", 24)
		
		#KOOPA attributes...
		(img_size = 125 ; @original_y -= 32 ; @y -= 32) if @type=~/koopa|ax_brotha/
		(@original_y -= 48 ; @y -= 48) if @type=~/monster/
		
		#THWOMP attributes...
		if @type=~/thwomp|monster/
		  img_size = 184
		  @release = false if not @type =~ /monster/
		  @gravity, @max_grv = 1.5, 40
		  @image_offset_x, @image_offset_y = -6, 0
		  @offset_top = 0
		  @reset_time = 60
		  @collision_factor = 44
		  @collision_factor = 32 if @type =~ /monster/
		end
		
		#STANDARD animations
		@animation = Image.load_tiles(@window, "artwork/enemies/#{@type}.png", img_size, img_size, false)
		@unleash_the_fucky_ness = false
		@fuck_x, @fuck_y = @window.screen_width/2, 0
		
		#RE-ADJUST animations
		if @type=="goomba"
			@animation.push(@animation[1])
		elsif @type=~/koopa/
		  @animation_kick = [@animation[2],@animation[3]]
			@animation      = [@animation[0],@animation[1]]
			(stomp ; kick(false)) if quest==true
		elsif @type=~/mystery/
			@max_speed  = 0
			@fuck_you   = Image.new(@window, "artwork/enemies/demon_bitch.png", false)
			@snd_scream = Sample.new(@window, "audio/scream.wav")
		elsif @type=~/boo/
		  @gravity = 0
		  @image_offset_x, @image_offset_y = 0, 0
		elsif @type=~/monster/
		  @animation_angry =  @animation[3]
		  @animation_jump  = [@animation[1], @animation[2]]
		  @animation       = [@animation[0], @animation[1], @animation[2], @animation[1]]
		  @image_offset_x  = -36
		  @image_offset_y  = -6
		  @health          = 3
		  @attacked_timer  = 0
		  @battling        = false
		  @max_speed       = 6
		elsif @type=="fish"
		  @animation.push(@animation[1])
		  @release = false
		  @std_mpf = 175
		elsif @type=="ax_brotha"
      @animation_throw = [@animation[2],@animation[3]]
      @animation       = [@animation[0],@animation[1]]
      @timer           = 30
      @image_offset_x  = -50
      @max_speed       = 2
    end
		
		#CURRENT image settings
		@character = @animation[0]
		@flip_x    = 1
		@color     = Color.new(0xffffffff)
		@color_m   = :default #OPTIONS: "default" or "additive"
	end
	
	#WARNING: This is the COLLISION DETECTION of the character itself, not the level objects.
  	def free?(x,y)
    	#Top Left Corner
    	not @level.solid?(@x+x - @image_offset_x - @character.width/2, @y+y - @image_offset_y - @offset_top - @character.height/2, @vel_y) and

    	#Top Right Corner
    	not @level.solid?(@x+x + @image_offset_x + @character.width/2, @y+y - @image_offset_y - @offset_top - @character.height/2, @vel_y) and
      
    	#Bottom Right Corner
    	not @level.solid?(@x+x + @image_offset_x + @character.width/2, @y+y + @image_offset_y + @character.height/2, @vel_y) and

    	#Bottom Left Corner
    	not @level.solid?(@x+x - @image_offset_x - @character.width/2, @y+y + @image_offset_y + @character.height/2, @vel_y)
  	end
  	
  	def free_below?(x,y)
  	    #Bottom Right Corner
    	not @level.solid?(@x+x + @image_offset_x + @character.width/2, @y+y + @image_offset_y + @character.height/2, @vel_y.abs) and
      
    	#Bottom Middle
    	not @level.solid?(@x+x, @y+y + @image_offset_y + @character.height/2, @vel_y.abs) and

    	#Bottom Left Corner
    	not @level.solid?(@x+x - @image_offset_x - @character.width/2, @y+y + @image_offset_y + @character.height/2, @vel_y.abs)
  	end

  	#Check if character is on ground
  	def on_ground
      	not free?(0,1) #If character is 1 pixel or closer/against the ground
  	end
  	
  	def not_group_interactive?
  	  @type!="thwomp" &&
  	  @type!="boo"
  	end
  	
  	#FLIPPING (changing their direction)
  	def flipToDirection(direction="right")
  		@direction = direction if not_group_interactive?
  	end

    #FLIP
    def flipDirection
      return (@direction == "right") ? @direction = "left" : @direction = "right"
    end
  	
  	#JUMP
  	def jump(v=-23)
      (@snd_kick.play(1.0, 3.0) ; @vel_y = v) if on_ground && @dead_x==0 #Character can only jump when on the ground
  	end
  	
  	#CHECK IF THE BOSS IS BATTLING
  	def battling?
  	  if @type =~ /monster/
  	    @battling == true
  	  else
  	    return false
  	  end
  	end
  	
  	#STOMPED
  	def stomp
  		@squished = true
  		@unleash_the_fucky_ness = true
  		      
      #ATTACK HIM LIKE A BOSS!!!
      if @type =~ /monster/ && @attacked_timer<1 && @battling==true
        @health         -= 1 
        @attacked_timer += 75
        @attacked_timer += 45 if @health<1
        @vel_y /= 2
        @vel_x /= 2
      end
  	end
  	
  	#ATTACKED
  	def attack(vx=0,status="")
  	  (@snd_impt.play(2.0, 1.5) ; @snd_dsty.play(1.5)) if @dead_y==0 && status==""
  		@dead_x =  vx*(1.00+rand(0.15)) if @dead_x==0
  		@dead_y = -15-rand(2.5) if @dead_y==0
  	end
  	
  	def knock_back(velocity=0)
  	  @vel_x = velocity
  	end
  	
  	#VALIDATING attack status
  	def not_attacked?
  	  if @type=~/monster/
  	    @attacked_timer < 1
  	  else
  	    return true
  	  end
  	end
  	
  	#DEAD?
  	def dead?
  		@dead_x!=0
  	end
  	
  	#KICKING
  	def kick(sound=true)
  		if @type =~ /koopa/ and @squished == true
  			@squished = true
  			@snd_kick.play if sound==true #PLAY sound...
  			(@direction = "left" ; @vel_x = -@shell_spd) if @window.character.x > @x
    	    (@direction = "right" ; @vel_x = @shell_spd) if @window.character.x < @x
  			(@kicked = true ; @max_speed = @shell_spd)   if @kicked == false
  		end
  	end
  	
  	#STOP the shell movement
  	def stop_shell_bash
  		if @type =~ /koopa/ and @squished == true && (not @type=="blue_koopa")
  			(@kicked = false ; @max_speed = @walk_spd ; @timer = 0) if @kicked == true
  		end
  	end
  	
  	#COMBO
  	def combo_add
  		@combo *= 2 if @combo<64
  	end
  	
  	#FACE towards player
  	def faceAtPlayer
  		@direction = "right" if @window.character.x > @x
    	@direction = "left" if @window.character.x < @x
  	end
  	
  	def facingAway?
  	  (@window.character.x > @x && @direction=="left") ||
  	  (@window.character.x < @x && @direction=="right")
  	end
  	
  	#CHASE the player
  	def chasePlayer
  	  #CHANGE DIRECTION
  	  if (not @window.character.y>@y-10) || free?(0,1)
  			@direction = "right" if @window.character.x > @x + 46 && (@kicked==true || @squished==false) && free?(150,0)
    		@direction = "left" if @window.character.x < @x - 46 && (@kicked==true || @squished==false) && free?(-150,0)
    	end
    	
    	#AI JUMP
    	if @kicked==true || @type=="fortress_monster"
    	  if (((not free?(180,0)) && @direction=="right" && (@window.character.y<@y-45 || (@window.character.x-@x).abs>200))  ||
    	     ((not free?(-180,0)) && @direction=="left" && (@window.character.y<@y-45 || (@window.character.x-@x).abs>200))   ||
    	     ((free?(64,1) || free?(-64,1)) && @window.character.y<@y)) && (not @window.character.y>@y+200)
    		  (@vel_x *= 0.3 if on_ground ; jump ; jump(-27) if @type=="fortress_monster")
    		end
    	end
  	end
  	
  	#RESPAWN position
  	def reset_position
  		@x, @y, @timer = @original_x, @original_y, 0
      if @quest == false
  		  @max_speed = @walk_spd if (not @type =~ /mystery/)
  		  @kicked    = @squished = false
      end
  		@combo = 1
  		faceAtPlayer
  	end
  	
  	#PLACE
  	def place(x,y)
  		@x,@y=x,y
  		@combo = 1
  	end
  	
  	#Physics code
  	def physics
      	#GRAVITY
      	@vel_y += @gravity if @vel_y<@max_grv && @release==true
      	
      	#WATER physics
      	if @y > @level.water_level && (not @type=~/fish/)
      	  @vel_y /= 1.2
      	  @vel_x /= 1.075
      	end
      	
      	#OBSTACLE-related attacks...
        if @level.block_hit?(@x,@y+@level.tile_size) || @level.block_hit?(@x+23,@y+@level.tile_size)
          if @type=~/goomba|mystery/
            if not dead?
              attack(@vel_x.abs) if @window.character.x <= @x
              attack(-@vel_x.abs) if @window.character.x > @x
              @window.character.score_add(100, self)
            end
          else
            (stomp ; @window.character.score_add(200, self)) if @squished==false
            @vel_y = -17
            @vel_x =  8 if @window.character.x<=@x && on_ground
            @vel_x = -8 if @window.character.x>@x && on_ground
          end
        end
      
      	#POSITION/MOVEMENT CHECK
      	if @vel_x > 0
          	(@vel_x.to_i).times do
              	if free?(1,0) || @type=="boo" #If character is free 1 pixel to the RIGHT
                  	@x+=1
              	else
                    vol=0.1 ; vol=0.5 if free?(-32,0)
              	    @snd_impt.play(vol, 1.6)                   if @direction=="right" && @kicked==true
              	    @level.remove_tile(@x+90, @y, @vel_x*4)    if @kicked==true && @x < (@level.width * @level.tile_size) - 90
              	    @level.remove_tile(@x+90, @y+23, @vel_x*4) if @kicked==true && @x < (@level.width * @level.tile_size) - 90
              	    @level.remove_tile(@x+90, @y+69, @vel_x*4) if @kicked==true && @x < (@level.width * @level.tile_size) - 90 && @y < (@level.height * @level.tile_size) - 90
                  	@vel_x = -@vel_x.abs                       #if @direction!="right" #Otherwise, stop moving that F-ING character!!!
                  	@vel_y = -5                                if @kicked==true && @vel_y.abs<3 && on_ground
                  	@direction = "left"
              	end
          	end
      	end
      
      	if @vel_x < 0
          	(-@vel_x.to_i).times do
              	if free?(-1,0) || @type=="boo" #If character is free 1 pixel to the LEFT
                  	@x-=1
              	else
                    vol=0.1 ; vol=0.5 if free?(32,0)
              	    @snd_impt.play(vol, 1.6)                   if @direction=="left" && @kicked==true
              	    @level.remove_tile(@x-90, @y, @vel_x*4)    if @kicked==true
              	    @level.remove_tile(@x-90, @y+23, @vel_x*4) if @kicked==true
              	    @level.remove_tile(@x-90, @y+69, @vel_x*4) if @kicked==true && @y < (@level.height * @level.tile_size) - 90
                  	@vel_x = @vel_x.abs                        #if @direction!="left" #Otherwise, stop moving that F-ING character!!!
                  	@vel_y = -5                                if @kicked==true && @vel_y.abs<3 && on_ground
                  	@direction = "right"
              	end
          	end    
      	end
      
      	if @vel_y > 0
          	(@vel_y.to_i).times do
              	if free_below?(0,1) || @type=="boo" #If character is free 1 pixel DOWN
                  	@y+=1
              	else
              	  if @type == "thwomp"
              	    @reset_time -= 1
              	    if @vel_y.abs > 10
              	      @snd_smash.play(2.0, 1.4)
              	      @level.shake(15)
              	    end
              	  end
              	  
              	  #KOOPA shell bounce... or others!
                  if @squished==false || @vel_y.abs<2
                    @vel_y = 0
                  else
                    @vel_y = -(@vel_y.abs/5) if @vel_y>0
                  end
              	end
          	end
      	end
      	
      	if @vel_y < 0
          	(-@vel_y.to_i).times do
              	if free?(0,-1) || @type=="boo" #If character is free 1 pixel UP
                  	@y-=1
              	else
                  	@vel_y = 0 #Otherwise, stop UPPER-DOOBA-ING!!!
              	end
          	end
      	end
  	end
  	
  	def unknown_type
  		(not @type=~/koopa/) && @type!="goomba" && @type!="thwomp" && @type!="fortress_monster" && @type!="fish" && @type!="ax_brotha"
  	end
  	
  	def artificial_intelligence()
  		#DIRECTION
  		  if @type!="blue_koopa" && (not @type=~/monster/) && @squished==false
  			  if @direction=="right"
      		  @vel_x = @max_speed #MOVE RIGHT
      	  else
      		  @vel_x = -@max_speed #MOVE LEFT
      	  end
        else
      	  if @kicked==true
      		  if @direction=="right"
      			  @vel_x += 0.6 if @vel_x < @max_speed #MOVE RIGHT
      		  else
      			  @vel_x -= 0.6 if @vel_x > -@max_speed #MOVE LEFT
      		  end
      	  else
      	    if @squished==false
      		    if @direction=="right"
      			    @vel_x = @max_speed #MOVE RIGHT
      		    else
      			    @vel_x = -@max_speed #MOVE LEFT
      		    end
      		  end
      	  end
        end
      	
      	#PLATFORM ANALYSIS
      	if @type == "red_koopa"
      		if @kicked == false && @squished == false && on_ground
      			flipToDirection("left") if free?(64,1)
      			flipToDirection("right") if free?(-64,1)
      		end
      	elsif @type == "thwomp" #THWOMPY-LIKE ACTIONS
      	  #STANDARD behaviours...
      	  @vel_x = 0
      	  @direction = "right"
      	  @release = false if @reset_time < 1
      	  
      	  #AWARE of player...
      	  if ((@x - @window.character.x) < 276 && (@window.character.x - @x) < 276) &&
      	      (@window.character.y > @y        &&  @window.character.y < @y + 1000)
      	    if @y <= @original_y
      	      @release = true
      	      @vel_y = 0
      	      @reset_time = 60
      	    end
      	  end
      	  
      	  #RESET...
      	  if @release == false
      	    @vel_y = -4
      	  end
      	elsif @type == "boo" #BOO Actions
      	  #IF player is looking
      	  if (@window.character.x > @x && @window.character.direction == "left") ||
      	     (@window.character.x < @x && @window.character.direction == "right")
      	    @vel_x = @vel_y = 0
      	  else
      	    @vel_x +=  0.1 if @window.character.x > @x && @vel_x <  4
      	    @vel_x += -0.1 if @window.character.x < @x && @vel_x > -4
      	    @vel_y +=  0.2 if @window.character.y > @y && @vel_y <  4
            @vel_y += -0.2 if @window.character.y < @y && @vel_y > -4
      	  end
      	elsif @type == "blue_koopa"
          if @kicked == false
            if distance(@window.character.x,@window.character.y,@x,@y)<800
              chasePlayer if not dead? && @squished == false
              @max_speed = @chase_spd
            else
              flipToDirection("left") if free?(64,1) && on_ground
              flipToDirection("right") if free?(-64,1) && on_ground
              @max_speed = @walk_spd
            end
          else
            chasePlayer if not dead?
          end
        elsif @type == "ax_brotha"
          @dead_x=1 if @squished
          jump(-20) if @timer==(60*rand(3)) - 10
          if @timer <= 0
            flipDirection
            @timer = 60
          end
          if @timer==10 && @dead_x==0
            dir="right" ; dir="left" if @flip_x<0
            @window.add_enemy_projectile(ItemObject.new(@window, @x, @y, "ax", @vel_x.abs + (@vel_y/3), dir)) if not @squished
          end
        end
  	end
	
	def update
		  #PHYSICS
		  physics if not dead?
		
		  #AI
		  artificial_intelligence if @x < (@level.width * @level.tile_size) - 175 || (not @type =~ /koopa/)
      	
      #STOMPED
      if @type != "ax_brotha"
      	if @squished && (@type != "thwomp") && (not @type =~ /monster/)
      		@squash_h += 0.1 if @type == "goomba"
      		@timer    += 1 if @kicked == false
      		@timer    -= 1 if @kicked == true
      		@squished = false if @timer >= @delay
      		@vel_x = 0 if @kicked == false && on_ground
      		faceAtPlayer if @timer == @delay-1
      	else
      		@timer = 0 if not @type =~ /monster/
      	end
      else
        @timer -= 1
      end
      	
      	#ATTACKED
      	if dead?
      		#HOLD original position still...
      		@vel_x = @vel_y = 0
      		
      		#ACCUMULATORS
      		@x += @dead_x
      		@y += @dead_y
      		
      		#GRAVITY
      		@dead_y += 1
      	end
      	
      	#NON-GOOMBA/KOOPA
      	faceAtPlayer if unknown_type
      	
      #ANIMATION (won't occur when player is dead or paused)
      if @type =~ /koopa/
			  if @squished == true && (not dead?)
      		@character = @animation_kick[0] if @kicked == false
      	  @character = @animation_kick[milliseconds / 75.0 % @animation_kick.size] if @kicked == true
        end
      end
      
      #BOSS
      if @type =~ /monster/
        @battling = true if distance(@window.character.x,@window.character.y,@x,@y)<600 && @window.character.on_ground
        @attacked_timer -= 1 if @attacked_timer > 0
        @timer = 180 if @timer < 0 || @attacked_timer > 0
        @timer -= 1
          
        #WHEN involved in battle...
        if @battling == true
          @window.character.battle! if @health>0
          (@window.character.end_battle! ; @battling = false) if @attacked_timer==0 && @health==0
          chasePlayer if (@window.character.x-@x>200 || @window.character.x-@x<-200) && @attacked_timer < 1 && on_ground
          (jump(-35) ; @max_speed*=2) if @timer==0 && @health<3
          @vel_x = 0 if @attacked_timer > 0
          @vel_x = 0 if @timer < 45 && @health<3
          @squished = false if @health>0
          @max_speed = 16-@health*3 if on_ground && @vel_y.abs==0
        else
          #HOLD original position still...
          @vel_x = 0
        end
      end
	end
	
	#DEATH BY SQUISHY-NESS
	def dead
		@squash_h >= 1.0 ||
		(@health<1 && @attacked_timer<1 && @battling==false if @type =~ /monster/)
	end
	
	def boss_dead?
	  @health<1 && @type=~/monster/
	end
	
	def draw(scr_x, scr_y)
		# CHECK direction and ANIMATE flip!
		if @kicked == false
      if @type!="ax_brotha"
  			@flip_x +=  0.25 if @direction == "right" && @flip_x <  1
  			@flip_x += -0.25 if @direction == "left"  && @flip_x > -1
      else
        @flip_x +=  0.20 if @x < @window.character.x && @flip_x <  1
        @flip_x += -0.20 if @x > @window.character.x && @flip_x > -1
      end
		else
			@flip_x =  1 if @direction == "right"
			@flip_x = -1 if @direction == "left"
		end
		@flip_x =  1 if @flip_x >  1
		@flip_x = -1 if @flip_x < -1
		flip_y = -1 if @dead_x!=0
		flip_y =  1 if @dead_x==0
		
		#UPDATE color depending on the time...
    @color = 0xffffffff if @window.background.hour == "day"
    if @window.background.hour == "night"
      #@color = 0xffdddddd
      
      #REALLY, REALLY FREAKY EASTER-EGG!!!
      if @unleash_the_fucky_ness==true && @type=="goomba_mystery"
        @fuck_you.draw_rot(@x+(-@flip_x*@fuck_x)-rand(30)+15-scr_x,@y+@fuck_y-rand(30)+15-scr_y,4,0,0.5,(0.8+(flip_y*0.8))/2,@flip_x*1.5,flip_y*1.5,0xffffffff,:additive)
        @fuck_you.draw_rot(@x+(-@flip_x*@fuck_x)-scr_x,@y+@fuck_y-scr_y,3,0,0.5,(0.8+(flip_y*0.8))/2,@flip_x*1.5,flip_y*1.5,0xffffffff)
        if @fuck_x > 0
          @snd_scream.play(2.0) if @fuck_x==@window.screen_width/2
          @fuck_x -= 100
        else
          @fuck_x = 0
        end
      end
    end
		
		# IMPLEMENT ANIMATION...
	  @character = @animation[milliseconds / @std_mpf % @animation.size] if @squished==false && (not dead?) && @type!="thwomp"
	  @character = @animation[1] if @type=="thwomp" && dead?
	  
	  #BOSS ANIMATIONS...
	  if @type =~ /monster/
	    if @timer > 30
	      if not on_ground
	        @character = @animation_jump[milliseconds / 90.0 % @animation_jump.size]
	      elsif @vel_x.abs<1 && @attacked_timer < 1 #IDLE
	        @character = @animation[0]
	      elsif @attacked_timer > 0
          @character = @animation_angry
        end
      end
      @character = @animation_jump[1] if @timer < 60 && @health<3 && @health!=0
      @color = 0xffffff77 if @health < 3
      @color = 0xffff7700 if @health < 2
      @color = 0xffff0000 if @health < 1
	  end
	  
	  #BOO animations...
	  if @type=="boo"
	    if @vel_x != 0
	      @character = @animation[0]
	      @color = 0xffffffff
	      layerC = 0x50ffffff
	    else
	      @character = @animation[1]
	      @color = 0x25ffffff
	      layerC = 0x10ffffff
	    end
	    @color_m = :additive
	  end

    #AX Brotha actions
    if @type=="ax_brotha"
      @character = @animation_throw[milliseconds / @std_mpf % @animation.size] if @timer>10 && @timer<30
    end
		
		#VIBRATE when koopa is almost up...
		if (@timer > @delay - 60 && (not @type =~ /monster/))
			vx, vy = 2-rand(4), 2-rand(4)
		else
			vx = vy = 0
		end
		
		#BOSS DEFEATED shake...
		vx, vy = 4-rand(8), 4-rand(8) if @type=~/monster/ and @health<1
		
		# DRAW the character
		# PARAMETERS: (x, y, z, rotation, origin_x, origin_y, scale_x, scale_y, color, color_mode)
		@character.draw_rot(@x.to_i - scr_x + vx, @y.to_i - scr_y + (@character.height/2) + vy, 0, 0, 0.5,
		                   (1.0+flip_y)/2, @flip_x, flip_y - @squash_h, @color, @color_m)
		
		#DRAW boo for another effect...
		@character.draw_rot(@x.to_i - scr_x + vx + 4, @y.to_i - scr_y + (@character.height/2) + vy + 4, 0, 0, 0.5,
		                   (1.0+flip_y)/2, @flip_x*(1+(rand(10)/100.0)), (flip_y - @squash_h) * (1+(rand(10)/100.0)), layerC, @color_m) if @type == "boo"
	end
end