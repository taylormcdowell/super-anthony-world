# --- CODE ---
#!/usr/bin/env ruby

#Begin load error checking
begin
	#In case you have rubygems
	require 'rubygems'
	require 'gosu'
rescue LoadError
	#In case you don't
	require 'gosu'
end
  
#LOAD ALL CLASSES
load "classes/player.rb"
load "classes/level.rb"
load "classes/background.rb"
load "classes/items.rb"
load "classes/music.rb"
load "classes/message.rb"

require "date"

include Gosu

class Game < Window
  attr_reader :character, :level, :enemies, :background, :camera_x, :camera_y, :screen_width, :screen_height, :LEVEL_THEME, :transition, :LEVEL_NUMBER
  def initialize
  	#Screen Defaults
	  @screen_width, @screen_height, @full_screen = 1920, 1080, true
    super(@screen_width, @screen_height, @full_screen, 16.666666)
    self.caption = "Super Anthony World"
      
    #VITAL variables
    @GAME_MODE    = "Menu"
    @TOTAL_LEVELS = Dir["levels/*/"].size
    @LEVEL_NUMBER = @LEVEL_ACCESS = 1 #@TOTAL_LEVELS
    @LEVEL_NUMBER = @LEVEL_ACCESS = @TOTAL_LEVELS if @LEVEL_ACCESS > @TOTAL_LEVELS #Validate level number...
    @LEVEL_COLOR  = Color.new(0x00ffffff)
    @color_change = "more"
    @LEVEL_THEME  = "overworld"
    @TILE_IMAGES  = []
    
    #CAMERA position variables
    @camera_x = 0
    @camera_y = -2000
    
    #LOAD game objects
    @background  = Background.new(self)
    @obstacle    = LevelClass.new(self, @LEVEL_NUMBER, @background.hour)
    @underground = LevelClass.new(self, @LEVEL_NUMBER, @background.hour, "underground")
    @castle      = LevelClass.new(self, @LEVEL_NUMBER, @background.hour, "castle")
    @shop        = LevelClass.new(self, 0, @background.hour, "dr_marcoux")
    @level       = @obstacle
    @character   = Player.new(self, @level)
    @transition  = TransitionBubble.new(self, "close")
    @loading     = Image.new(self, "artwork/level/loading.png", false)
    @loadX, @load_level = 0, "neutral"
    
    #SPAWN all enemies and then delete the spawners themselves...
    @enemies = []
    @enemy_projectile = []
    @level.spawners.each { |spawner| @enemies.push(Enemy.new(self,spawner.x,spawner.y,spawner.type,@level,spawner.quest)) }
    
    #INVENTORY OBJECTS
    @inv_box   = Image.new(self, "artwork/inventory/box.png",false)
    @inv_coins = Image.load_tiles(self, "artwork/inventory/coin_count.png",54,33,false)
    @inv_coins.push(@inv_coins[0]).push(@inv_coins[0]) #ADD a couple more frames of the first image...
    @inv_ruby  = Image.load_tiles(self, "artwork/inventory/ruby_count.png",54,33,false)
    @inv_ruby.push(@inv_ruby[0]).push(@inv_ruby[0]).push(@inv_ruby[0]).push(@inv_ruby[0]) #ADD 4 more frames...
    @inv_emrd  = Image.load_tiles(self, "artwork/inventory/emerald_count.png",54,33,false)
    @inv_emrd.push(@inv_emrd[0]).push(@inv_emrd[0]).push(@inv_emrd[0]).push(@inv_emrd[0]) #ADD 4 more frames...
    @inv_sapp  = Image.load_tiles(self, "artwork/inventory/sapphire_count.png",54,33,false)
    @inv_sapp.push(@inv_sapp[0]).push(@inv_sapp[0]).push(@inv_sapp[0]).push(@inv_sapp[0]) #ADD 4 more frames...
    @inv_clock = Image.new(self, "artwork/inventory/clock_count.png",false)
    
    #FONT
    @font = Font.new(self, "Monaco", 36)
    
    #MUSIC/AUDIO
    @music     = Music.new(self, @LEVEL_THEME)
    @boss_song = Music.new(self, "fortress_boss")
    @snd_NEXT  = Sample.new(self, "audio/next_level.wav")
    @snd_PREV  = Sample.new(self, "audio/prev_level.wav")
    @snd_INTRO = Sample.new(self, "audio/intro.wav")
    @snd_GMOVR = Sample.new(self, "audio/game_over.wav")
    @snd_EXPLS = Sample.new(self, "audio/explosion.wav")
    @snd_PURCH = Sample.new(self, "audio/purchase_paying.wav")
    
    #Containers
    @eX, @eY    = [-7, 6, -9, 8,-7, 2, 8], [-8, 9, -10, 9, -8, 0, 9].reverse
    @enemy_ex   = []
    @monetary   = [0, 0, 0, 0]
    @boost_imgs = [Image.new(self, "artwork/inventory/boost_jump.png",false),
                   Image.new(self, "artwork/inventory/boost_speed.png",false),
                   Image.new(self, "artwork/inventory/boost_fly.png",false),
                   Image.new(self, "artwork/inventory/boost_ax.png",false)]
        
    #MENU objects
    @TITLE      = Image.new(self, "artwork/menu/title.png", true)
    @GAME_OVER  = Image.new(self, "artwork/menu/game_over.png", true)
    @PAUSE_MENU = Image.new(self, "artwork/menu/pause.png", true)
    @TIMES_UP   = Image.new(self, "artwork/menu/times_up.png", true)
    @PRESS_JUMP = Image.new(self, "artwork/menu/press_jump.png", true)
    @ACTIVE_SRH = Image.new(self, "artwork/inventory/actv_search.png", true)
    @TITLE_size = 500.0
    @MENU_TIME, @MENU_X, @MENU_Y, @PAUSED, @pause_x, @pause_select = 0, 10, 5, false, -@PAUSE_MENU.width, 0
    @pause_buttons = [Image.new(self, "artwork/menu/button_resume.png", true),
                      Image.new(self, "artwork/menu/button_exitlevel.png", true),
                      Image.new(self, "artwork/menu/button_exitapp.png", true)]
    @pause_desc    = ["Resume playing the game",
                      "Leave level and lose 25 coins (or 1 Ruby if you have none)",
                      "Exit the entire program"]
  end
  
  def late_night? # - IT'S MOONLIGHT TIME!!!
  	not (@background.current_hour>1 and @background.current_hour<24)
  end
  
  def switch_song(theme="underwater")
    #Only assign new MUSIC class object if current theme does not equal to new theme...
    if theme=="underground" && late_night?
      @music = Music.new(self, "eerie") if @music.theme!=theme
    else
      @music = Music.new(self, theme) if @music.theme!=theme
    end
  end

  def add_enemy_projectile(obj=nil)
    @enemy_projectile.push(obj)
  end
  
  def reset_game
    #VITAL variables
    @GAME_MODE    = "Menu"
    @LEVEL_NUMBER = @LEVEL_ACCESS = 1
    @TOTAL_LEVELS = Dir["levels/*"].size
    @LEVEL_COLOR  = Color.new(0x00ffffff)
    @color_change = "more"
    @LEVEL_THEME  = "overworld"
    
    #LOAD game objects
    @background  = Background.new(self)
    @obstacle    = LevelClass.new(self, @LEVEL_NUMBER, @background.hour)
    @underground = LevelClass.new(self, @LEVEL_NUMBER, @background.hour, "underground")
    @castle      = LevelClass.new(self, @LEVEL_NUMBER, @background.hour, "castle")
    @shop        = LevelClass.new(self, 0, @background.hour, "dr_marcoux")
    @level       = @obstacle
    @character   = Player.new(self, @level)
    @transition  = TransitionBubble.new(self, "close")
    @loadX, @load_level = 0, "neutral"
    
    #RE-SPAWN all enemies and then delete the spawners themselves...
    @enemies = []
    @enemy_projectile = []
    @level.spawners.each { |spawner| @enemies.push(Enemy.new(self,spawner.x,spawner.y,spawner.type,@level,spawner.quest)) }
    
    #CAMERA position variables
    @camera_x = 0
    @camera_y = -2000
    
    #MENU objects
    @TITLE_size = 500.0
    @MENU_TIME, @MENU_X, @MENU_Y, @PAUSED, @pause_select = 0, 10, 5, false, 0
  end
  
  def start_level(next_number=0)
    next_number    = 0 if @LEVEL_NUMBER >= @LEVEL_ACCESS && next_number > 0
    @LEVEL_NUMBER += next_number
    @LEVEL_THEME   = "overworld"
    @background    = Background.new(self)
    @obstacle      = LevelClass.new(self, @LEVEL_NUMBER, @background.hour)
    @underground   = LevelClass.new(self, @LEVEL_NUMBER, @background.hour, "underground")
    @castle        = LevelClass.new(self, @LEVEL_NUMBER, @background.hour, "castle")
    @shop          = LevelClass.new(self, 0, @background.hour, "dr_marcoux")
    @level         = @obstacle
    @music         = Music.new(self, @LEVEL_THEME)
    @character.reset(@level,false) if (next_number==0 && @LEVEL_NUMBER != @TOTAL_LEVELS) || @character.health<1
    @character.reset(@level,true)  if next_number!=0 || @LEVEL_NUMBER >= @LEVEL_ACCESS
    @enemies = []
    @enemy_projectile = []
    @level.spawners.each { |spawner| @enemies.push(Enemy.new(self,spawner.x,spawner.y,spawner.type,@level,spawner.quest)) }
    @LEVEL_COLOR  = Color.new(0x00ffffff)
  	@load_level = "neutral"
  end
  
  def change_arena(theme="underground")
    if @LEVEL_THEME == "overworld"
      @LEVEL_THEME = theme ; returning = false
    elsif @LEVEL_THEME == "castle"
      @LEVEL_THEME = "dr_marcoux" ; returning = false
    elsif @LEVEL_THEME == "dr_marcoux"
      @LEVEL_THEME = "castle" ; returning = true
    else
      @LEVEL_THEME = "overworld" ; returning = true
    end
    
    @background = Background.new(self, @LEVEL_THEME)
  	@level = @obstacle    if @LEVEL_THEME == "overworld"
  	@level = @underground if @LEVEL_THEME == "underground"
  	@level = @castle      if @LEVEL_THEME == "castle"
  	@level = @shop        if @LEVEL_THEME == "dr_marcoux"

  	if late_night? && @LEVEL_THEME == "underground"
  		@music = Music.new(self, "eerie") #Be prepared for some scary shit!!!
  	else
  		@music = Music.new(self, @LEVEL_THEME)
  	end
  	
  	@enemies = []
  	@level.spawners.each { |spawner| @enemies.push(Enemy.new(self,spawner.x,spawner.y,spawner.type,@level,spawner.quest)) } if @LEVEL_THEME!="dr_marcoux"
  	@transition.transition = "open"
  	@transition.fast = 0.1
  	@character.reposition(@level, returning)
  end
  
  def scroll_level(number=1)
    if @LEVEL_NUMBER < @LEVEL_ACCESS
  		@load_level = "next" if number == 1
    else
    	start_level if number > -1
    end
  	@load_level = "prev" if number == -1
  end
  
  def set_monetary(c,r,e,s)
    @monetary[0] += c*3
    @monetary[1] += r*3
    @monetary[2] += e*3
    @monetary[3] += s*3
  end

  def draw()
     #GAME MODES
     if @GAME_MODE == "Menu"
     	#DELAY THE TIME EVENTS OF THE MENU!!!
     	if @MENU_TIME < 250
     		@MENU_TIME += 5
     	else
     		if @MENU_TIME < 501
     			@TITLE_size /= 1.1 if @TITLE_size != 0
     			@TITLE_size = 0     if @TITLE_size < 0.001
     			@PRESS_JUMP.draw_rot(@screen_width/2,@screen_height/2+225+@TITLE_size*400,0,0,0.5,0.5,1.0+(@TITLE_size*20)+(rand(0.1)/20),1.0+(@TITLE_size*20)+(rand(0.1)/20),0xffffffff,:additive)
     			@PRESS_JUMP.draw_rot(@screen_width/2,@screen_height/2+225+@TITLE_size*400,0,0,0.5,0.5,1.0+(@TITLE_size*20)+(rand(0.1)/20),1.0+(@TITLE_size*20)+(rand(0.1)/20),0xffffffff,:additive)
     		end
     	end
     	
     	#WHEN jump button is pressed
     	if @MENU_TIME > 500
     	  @snd_INTRO.play if @MENU_TIME == 510 && @TITLE_size <= 0.0005
     	  @snd_PREV.play(1.5,0.08) if @MENU_TIME == 501 && @TITLE_size <= 0.0001
     		@TITLE_size *= 1.05 + @TITLE_size/35
     		@MENU_Y     += 0.5
     		@MENU_TIME  += 1
     		@TITLE_size  = 0.0001   if @TITLE_size == 0
     		@GAME_MODE   = "Game"   if @TITLE_size > 300
     	end
     	
     	#DRAW all the title-titty shit!
     	@TITLE.draw_rot(@screen_width/2 + @TITLE_size*2, @screen_height/2 - 50 - @TITLE_size*15, -3+@TITLE_size*5, 0, 0.5, 0.5, 1.0+@TITLE_size, 1.0+@TITLE_size)
     	@background.draw(@camera_x.to_i, @camera_y.to_i, @screen_width, @screen_height)
     	
     	#IMPLEMENT BACKGROUND MOTION
     	@camera_x += @MENU_X
     	@camera_y -= @MENU_Y - @MENU_X/1.5
     	
     	#SCROLLING SLOWS DOWN
     	@MENU_X /= 1.005 if @camera_x > 10000
     	@MENU_Y /= 1.01  if @camera_y < -2000
     elsif @GAME_MODE == "Game Over"
       @camera_x = 0 ; @camera_y = -2000
       @background.draw(@camera_x.to_i, @camera_y.to_i, @screen_width, @screen_height)
       @GAME_OVER.draw_rot((@screen_width/2).to_i,(@screen_height/2).to_i - 50, 0, 0)
       @PRESS_JUMP.draw_rot(@screen_width/2,@screen_height/2+320,0,0,0.5,0.5,1.0+(rand(0.1)/20),1.0,0xffffffff,:additive)
     else
      if not @transition.completely_closed?
        #PAUSE MENU
        if @PAUSED == true
          #MOVE menu onto screen...
          @pause_x /= 1.5 if @pause_x.abs > 0
          @pause_x  = 0   if @pause_x.abs < 2
          @PAUSE_MENU.draw(@pause_x.to_i,0,99,1,1,0xffffffff)
          @pause_select %= 3
          #buttons...
          for i in 0..@pause_buttons.size-1
            size, color, style = 0.75, 0x99ffffff, :default
            size, color, style = 1.00, 0xffffff99, :additive if i == @pause_select
            @pause_buttons[i].draw_rot(@screen_width/2 - (150 * (@pause_buttons.size-1)) + (300 * i) - @pause_x, @screen_height/2, 100, 0, 0.5, 0.5, size, size, color, style)
          end
          #description
          @font.draw(@pause_desc[@pause_select], @screen_width / 2 - 12 - (@pause_desc[@pause_select].length * 7), @screen_height - 225, 101, 1.0, 1.0, Color.new(255-(@pause_x.abs/8).to_i,255,255,255))
          @font.draw(@pause_desc[@pause_select], @screen_width / 2 - 10 - (@pause_desc[@pause_select].length * 7), @screen_height - 223, 100, 1.0, 1.0, Color.new(255-(@pause_x.abs/8).to_i,0,0,0))
        elsif @pause_x > -@PAUSE_MENU.width
          #MOVE away from screen...
          @pause_x -= 60
          @pause_x  = -@PAUSE_MENU.width if @pause_x.abs > 1920
          @PAUSE_MENU.draw(@pause_x.to_i,0,99,1,1,0xffffffff)
          #buttons...
          for i in 0..@pause_buttons.size-1
            size, color, style = 0.75, 0x99ffffff, :default
            size, color, style = 1.00, 0xffffff99, :additive if i == @pause_select
            @pause_buttons[i].draw_rot(@screen_width/2 - (150 * (@pause_buttons.size-1)) + (300 * i) + @pause_x, @screen_height/2, 100, 0, 0.5, 0.5, size, size, color, style)
          end
          #description
          @font.draw(@pause_desc[@pause_select], @screen_width / 2 - 12 - (@pause_desc[@pause_select].length * 7), @screen_height - 225, 101, 1.0, 1.0, Color.new(255-(@pause_x.abs/8).to_i,255,255,255))
          @font.draw(@pause_desc[@pause_select], @screen_width / 2 - 10 - (@pause_desc[@pause_select].length * 7), @screen_height - 223, 100, 1.0, 1.0, Color.new(255-(@pause_x.abs/8).to_i,0,0,0))
        else
          @pause_select = 0
        end
      end 
    	#CAMERA for scrolling effect
    	#UPDATE earthquake (if there is one)
    	if @level.earthquake > 0
        shake_x, shake_y = @eX[milliseconds/45.0%@eX.size], @eY[milliseconds/35.0%@eY.size]
      else
        shake_x, shake_y = 0, 0
      end
      
      #AMPLIFY shaking when larger value is given.
      #This creates a more dynamic screen shake effect...
      shake_x *= 0.15 * @level.earthquake
      shake_y *= 0.15 * @level.earthquake
      
      #SCREEN SCROLL when battling does not occur...
      if @character.battling == false
        #CAM lock-on
        @lock_x = @camera_x.to_i
        @lock_y = @camera_y.to_i
        
    	  #X-CAM...
    	  if (@level.width * @level.tile_size) > @screen_width+80
    	    @camera_x = [[@character.x - @screen_width / 2, 0].max, @level.width * @level.tile_size - @screen_width].min.to_i + shake_x
    	  else
    	    @camera_x = shake_x
    	  end
    	  #Y-CAM...
    	  if (@level.height * @level.tile_size) > @screen_height+40
    	    @camera_y = [[@character.y - @screen_height / 2 - 50, 0].max, @level.height * @level.tile_size - @screen_height].min.to_i + shake_y
    	  else
          @camera_y = shake_y
    	  end
    	else
    	  #SCREEN LOCK if battling is true...
    	  @camera_x = @lock_x+shake_x
    	  @camera_y = @lock_y+shake_y
    	  
    	  #RE-ADJUST LOCKED position
    	  @lock_x -= @character.vel_x.abs if @character.x < (@lock_x + (@level.tile_size/2))
    	  @lock_x += @character.vel_x.abs if @character.x > (@lock_x + @screen_width - (@level.tile_size/2))
    	  @lock_y -= @character.vel_y.abs if @character.y < @lock_y
        @lock_y += @character.vel_y.abs if @character.y > (@lock_y + @screen_height - (@level.tile_size*3))
    	end
    	
    	#IF CAM IS OUT of bounds, RESET!
      @camera_x = 0 if @camera_x < 0
      @camera_x = (@level.width*@level.tile_size-@screen_width) if @camera_x>@level.width*@level.tile_size-@screen_width
      @camera_y = 0 if @camera_y<0
      @camera_y = (@level.height*@level.tile_size-@screen_height) if @camera_y>@level.height*@level.tile_size-@screen_height
    
    	#DRAW the objects on screen
    	@transition.draw(@camera_x,@camera_y,@character) if @transition.size<6
  		@character.draw(@camera_x, @camera_y)
  		@level.draw(@camera_x, @camera_y, @screen_width, @screen_height)
  		@background.draw(@camera_x, @camera_y, @screen_width, @screen_height)
  	
  		#DRAW all of the enemies
  		@enemies.each { |enemy| enemy.draw(@camera_x, @camera_y) }

      #DRAW all of the enemies' projectiles
      @enemy_projectile.each { |projectile| projectile.draw(@camera_x, @camera_y, 0xffffffff) } if @enemy_projectile.size>0
  		
  		#DRAW boss explosions...
  		@enemy_ex.each { |explosion| explosion.draw(@camera_x, @camera_y) }
  	
  		#PROGRESS INFO
  		#-----------------------------------------------------------------------
  		#BOX
  		box_position = @screen_height - @inv_box.height + 4 - (@pause_x.abs/25 - @PAUSE_MENU.width/25)
  		@inv_box.draw(0, box_position, 1000, 1, 1, 0xdfffffff, :additive)
  	
  		#HEALTH STATUS
  		@character.draw_hearts(28, box_position + 24)
  		
  		#SCALING
  		s_coin = 1 + (@monetary[0].to_f/100.0).abs
  		s_ruby = 1 + (@monetary[1].to_f/100.0).abs
  		s_emrd = 1 + (@monetary[2].to_f/100.0).abs
  		s_sapp = 1 + (@monetary[3].to_f/100.0).abs
  	
  		#COIN COUNT
  		@inv_coins[milliseconds / 90.0 % @inv_coins.size].draw(200 - ((s_coin-1)*50), box_position + 24 - ((s_coin-1)*25), 1001, s_coin, s_coin)
  		@font.draw("#{@character.coins+(@monetary[0]/3)}", 205 + @inv_coins[0].width, box_position + 22, 1001, 1, 1, 0xff000000)
  		@font.draw("#{@character.coins+(@monetary[0]/3)}", 207 + @inv_coins[0].width, box_position + 23, 1000, 1, 1, 0x95000000)
  	
  		#RUBY COUNT
  		@inv_ruby[milliseconds / 85.0 % @inv_ruby.size].draw(350 - ((s_ruby-1)*50), box_position + 24 - ((s_ruby-1)*25), 1001, s_ruby, s_ruby)
  		@font.draw("#{@character.rubies+(@monetary[1]/3)}", 355 + @inv_coins[0].width, box_position + 22, 1001, 1, 1, 0xff000000)
  		@font.draw("#{@character.rubies+(@monetary[1]/3)}", 357 + @inv_coins[0].width, box_position + 23, 1000, 1, 1, 0x95000000)
  	
  		#EMERALD COUNT
  		@inv_emrd[milliseconds / 80.0 % @inv_emrd.size].draw(470 - ((s_emrd-1)*50), box_position + 24 - ((s_emrd-1)*25), 1001, s_emrd, s_emrd)
  		@font.draw("#{@character.emeralds+(@monetary[2]/3)}", 475 + @inv_coins[0].width, box_position + 22, 1001, 1, 1, 0xff000000)
  		@font.draw("#{@character.emeralds+(@monetary[2]/3)}", 477 + @inv_coins[0].width, box_position + 23, 1000, 1, 1, 0x95000000)
  	
  		#SAPPHIRE COUNT
  		@inv_sapp[milliseconds / 90.0 % @inv_sapp.size].draw(590 - ((s_sapp-1)*50), box_position + 24 - ((s_sapp-1)*25), 1001, s_sapp, s_sapp)
  		@font.draw("#{@character.sapphires+(@monetary[3]/3)}", 595 + @inv_coins[0].width, box_position + 22, 1001, 1, 1, 0xff000000)
  		@font.draw("#{@character.sapphires+(@monetary[3]/3)}", 597 + @inv_coins[0].width, box_position + 23, 1000, 1, 1, 0x95000000)
  		
  		#INVENTORY status change effect
      if @monetary!=[0,0,0,0] && @load_level=="neutral"
        for i in 0..3
          @monetary[i] -= 1        if @monetary[i]>0
          @monetary[i] -= 9        if @monetary[i]>150
          @monetary[i] += 1        if @monetary[i]<0
          @monetary[i] += 9        if @monetary[i]<-150
          @snd_PURCH.play(2.0,2.5) if (@monetary[i].abs % 3) == 2
        end
      end
  	
  		#SCORE COUNT
  		@font.draw("SCORE: #{@character.score}", 900, box_position + 15, 1001, 1, 1, 0xff000000)
  		@font.draw("SCORE: #{@character.score}", 902, box_position + 16, 1000, 1, 1, 0x95000000)
  		@font.draw("BEST: #{@character.hiscore}", 930, box_position + 42, 1001, 0.75, 0.75, 0xff000000)
      @font.draw("BEST: #{@character.hiscore}", 932, box_position + 43, 1000, 0.75, 0.75, 0x95000000)
      
      #DISPLAY boosts if they exist...
      if @character.level_axes > 0
        @boost_imgs[3].draw(@screen_width-90, box_position + 5, 1000)
        @font.draw("#{@character.level_axes}", @screen_width-74, box_position + 14, 1001, 0.5, 0.5, 0x99ffffff, :additive)
      else
        @boost_imgs[3].draw(@screen_width-90, box_position + 5, 1000, 1, 1, 0x66000000)
      end
      
      if @character.level_cape > 0
        @boost_imgs[2].draw(@screen_width-160, box_position + 5, 1000)
        @font.draw("#{@character.level_cape}", @screen_width-144, box_position + 14, 1001, 0.5, 0.5, 0x99ffffff, :additive)
      else
        @boost_imgs[2].draw(@screen_width-160, box_position + 5, 1000, 1, 1, 0x66000000)
      end
      
      if @character.level_speed > 0
        @boost_imgs[1].draw(@screen_width-230, box_position + 5, 1000)
        @font.draw("#{@character.level_speed}", @screen_width-214, box_position + 14, 1001, 0.5, 0.5, 0x99ffffff, :additive)
      else
        @boost_imgs[1].draw(@screen_width-230, box_position + 5, 1000, 1, 1, 0x66000000)
      end
      
      if @character.level_jump > 0
        @boost_imgs[0].draw(@screen_width-300, box_position + 5, 1000)
        @font.draw("#{@character.level_jump}", @screen_width-284, box_position + 14, 1001, 0.5, 0.5, 0x99ffffff, :additive)
      else
        @boost_imgs[0].draw(@screen_width-300, box_position + 5, 1000, 1, 1, 0x66000000)
      end
      
      #DISPLAY flashlight retrieval status
      if @character.searcher
        @ACTIVE_SRH.draw(@screen_width-370, box_position + 5, 1000)
      else
        @ACTIVE_SRH.draw(@screen_width-370, box_position + 5, 1000, 1, 1, 0x66000000)
      end
      
      #CLOCK COUNT
      clock_color, shk_x, shk_y = 0xff000000, 0, 0
      @fs = 1.0 if (not @character.time_running_out?) || @character.clock_tick? #---FOR WARNING FLASHES!!!
      (clock_color = 0xffff0000 ; shk_x, shk_y = 2-rand(4), 2-rand(4) if @character.time<=660 ; @fs*=1.05 if @character.time>59) if @character.time_running_out?
      @inv_clock.draw(735 + shk_x, box_position + 22 + shk_y, 1001, 1, 1)
      @font.draw(@character.clock_display, 775 + shk_x, box_position + 26 + shk_y, 1001, 1.1, 0.9, clock_color)
      @font.draw(@character.clock_display, 775 + (@fs*shk_x) - ((@fs*25)-25), box_position + 26 + (@fs*shk_y) - ((@fs*22)-22), 1002,
                 1.1*@fs, 0.9*@fs, Color.new((255-(14*@fs).to_i).abs,255,0,0), :additive) if @character.time_running_out? &&
                                                                                             @character.complete==false &&
                                                                                             @transition.completely_opened? &&
                                                                                             @level.auto_enter==false && @fs<19
      if @character.time<59
        @TIMES_UP.draw_rot(@screen_width/2,@screen_height/2,5,0)
        @TIMES_UP.draw_rot(shk_x+@screen_width/2,shk_y+@screen_height/2,5,0,0.5,0.5,1,1,0xffffffff,:additive)
      end
  	
  		#LEVEL DISPLAY
  		if @transition.completely_closed? && @transition.fast != 0.1
  	    @color_change = "more" if @LEVEL_COLOR.alpha <= 10
  	    @color_change = "less" if @LEVEL_COLOR.alpha >= 245
  			@LEVEL_COLOR.alpha -= 10 if @color_change == "less"
  			@LEVEL_COLOR.alpha += 10 if @color_change == "more"
  		
  			#INVENTORY PREVIEW
  			@font.draw("SCORE: #{@character.score}", @screen_width/2 - 310, @screen_height/2 + 150 + @level.bounce_y.to_i + @loadX.abs/2, 999999999, 1, 1, 0xffffffff)
  			@font.draw("SCORE: #{@character.score}", @screen_width/2 - 308, @screen_height/2 + 152 + @level.bounce_y.to_i + @loadX.abs/2, 999999998, 1, 1, 0xff000000)
  			@inv_coins[milliseconds / 90.0 % @inv_coins.size].draw(@screen_width/2 - 60, @screen_height/2 - 278 + @level.bounce_y.to_i - @loadX.abs/3, 999999999)
  			@font.draw("x #{@character.coins+(@monetary[0]/3)}", @screen_width/2 - 80 + @inv_coins[0].width, @screen_height/2 - 282 + @level.bounce_y.to_i - @loadX.abs/3, 999999999, 1, 1, 0xffffffff)
  			@font.draw("x #{@character.coins+(@monetary[0]/3)}", @screen_width/2 - 78 + @inv_coins[0].width, @screen_height/2 - 280 + @level.bounce_y.to_i - @loadX.abs/3, 999999998, 1, 1, 0xff000000)
  			@inv_ruby[milliseconds / 85.0 % @inv_ruby.size].draw(@screen_width/2 - 57, @screen_height/2 + 150 + @level.bounce_y.to_i + @loadX.abs/2, 999999999)
  			@font.draw("x #{@character.rubies}", @screen_width/2 - 77 + @inv_coins[0].width, @screen_height/2 + 146 + @level.bounce_y.to_i + @loadX.abs/2, 999999999, 1, 1, 0xffffffff)
  			@font.draw("x #{@character.rubies}", @screen_width/2 - 75 + @inv_coins[0].width, @screen_height/2 + 148 + @level.bounce_y.to_i + @loadX.abs/2, 999999998, 1, 1, 0xff000000)
  			@inv_emrd[milliseconds / 80.0 % @inv_emrd.size].draw(@screen_width/2 + 63, @screen_height/2 + 150 + @level.bounce_y.to_i + @loadX.abs/2, 999999999)
  			@font.draw("x #{@character.emeralds}", @screen_width/2 + 43 + @inv_coins[0].width, @screen_height/2 + 146 + @level.bounce_y.to_i + @loadX.abs/2, 999999999, 1, 1, 0xffffffff)
  			@font.draw("x #{@character.emeralds}", @screen_width/2 + 45 + @inv_coins[0].width, @screen_height/2 + 148 + @level.bounce_y.to_i + @loadX.abs/2, 999999998, 1, 1, 0xff000000)
  			@inv_sapp[milliseconds / 90.0 % @inv_sapp.size].draw(@screen_width/2 + 183, @screen_height/2 + 150 + @level.bounce_y.to_i + @loadX.abs/2, 999999999)
  			@font.draw("x #{@character.sapphires}", @screen_width/2 + 163 + @inv_coins[0].width, @screen_height/2 + 146 + @level.bounce_y.to_i + @loadX.abs/2, 999999999, 1, 1, 0xffffffff)
  			@font.draw("x #{@character.sapphires}", @screen_width/2 + 165 + @inv_coins[0].width, @screen_height/2 + 148 + @level.bounce_y.to_i + @loadX.abs/2, 999999998, 1, 1, 0xff000000)
  	    @character.draw_hearts(@screen_width/2 - 310, @screen_height/2 - 280 + @level.bounce_y.to_i - @loadX.abs/3, 999999999)
  	    
  	    #LEVEL PREVIEW
  			@level.preview(@screen_width/2 - @loadX, @screen_height/2 - 50)
  			@loading.draw_rot(@screen_width/2, @screen_height/2 + 240, 10000000001, 0) if @loadX!=0 ; offtext = "#@LEVEL_NUMBER".length-1
  			@font.draw_rot("LEVEL: #{@LEVEL_NUMBER}", @screen_width/2 - 100 - (offtext*15), @screen_height/2 - 130 - @loadX.abs/1.5 + @level.bounce_y, 999999999, 0, 2, 2)
  			@font.draw_rot("LEVEL: #{@LEVEL_NUMBER}", @screen_width/2 -  97 - (offtext*15), @screen_height/2 - 127 - @loadX.abs/1.5 + @level.bounce_y, 999999998, 0, 2, 2, 0xaa000000)
  			@font.draw_rot("Press Jump to Begin!", @screen_width/2 - 200, @screen_height/2 - 60 + @loadX.abs/1.5 + @level.bounce_y, 999999999, 0, 1.5, 1.5, @LEVEL_COLOR)
  			
  			#ARROWS
  			if @loadX.abs<480
  			  (draw_triangle(360 + @screen_width/2 + @level.bounce_y*2 - @loadX, @screen_height/2 - 100, 0xccffffff,
  			                 360 + @screen_width/2 + @level.bounce_y*2 - @loadX, @screen_height/2, 0xccffffff,
  			                 360 + @screen_width/2 + @level.bounce_y*2 + 100 - @loadX, @screen_height/2 - 50, 0x50ffffff, 999999999, :additive);
  			  draw_triangle(360 + @screen_width/2 + @level.bounce_y*2 - @loadX, @screen_height/2 - 100 + 500, 0x30ffffff,
                        360 + @screen_width/2 + @level.bounce_y*2 - @loadX, @screen_height/2 + 500, 0x00ffffff,
                        360 + @screen_width/2 + @level.bounce_y*2 + 100 - @loadX, @screen_height/2 - 50 + 500, 0x20ffffff, 100000.1)) if @LEVEL_NUMBER < @LEVEL_ACCESS
  			  (draw_triangle(-360 + @screen_width/2 - @level.bounce_y*2 - @loadX, @screen_height/2 - 100, 0xccffffff,
                         -360 + @screen_width/2 - @level.bounce_y*2 - @loadX, @screen_height/2, 0xccffffff,
                         -360 + @screen_width/2 - @level.bounce_y*2 - 100 - @loadX, @screen_height/2 - 50, 0x50ffffff, 999999999, :additive);
          draw_triangle(-360 + @screen_width/2 - @level.bounce_y*2 - @loadX, @screen_height/2 - 100 + 500, 0x30ffffff,
                        -360 + @screen_width/2 - @level.bounce_y*2 - @loadX, @screen_height/2 + 500, 0x00ffffff,
                        -360 + @screen_width/2 - @level.bounce_y*2 - 100 - @loadX, @screen_height/2 - 50 + 500, 0x20ffffff, 100000.1)) if @LEVEL_NUMBER > 1
        end
  			
  			#BACKGROUND
  			@background.preview(@screen_width/5.5 - @loadX*4, 50, 100001)
  			
  			#RESET menu time
  			@MENU_TIME = 0
  		end	
  	 end
  end

  def update()
     if @GAME_MODE == "Menu"
     	#...
     else
    	#UPDATE all the objects in the game
    	@transition.update
    
    	#UPDATE only if transition is opening...
    	if @transition.size > 0 && @level.msg_ACT == false && @PAUSED == false
    		#SET level selection to neutral position
    		@loadX = 0
    		@level.started = false
    		@level.zoom_color.red = 255
    		
    		#KILL main character if offscreen below...
    		if not (@character.y > ((@level.height * @level.tile_size) + @character.vel_y.abs + 10))
    			@character.update
    		else
    			@character.die
    		end
    		
    		#KILL character when time runs out or health runs to empty...
    		@character.die if @character.out_of_time? || @character.health<1

        #Enemies' shooting object
        @enemy_projectile.each do |projectile|
          dir =  1 if projectile.vx >= 0 ; dir = -1 if projectile.vx < 0
          @character.attacked(dir, projectile.vx) if distance(@character.x,@character.y,projectile.x,projectile.y)<55 && @character.time_attck==0
          projectile.update if @character.health>0
        end
        @enemy_projectile.reject! { |ax| ax.x < (@camera_x-100) || ax.x > (@camera_x+@screen_width+100) || ax.y > (@camera_y+@screen_height+92) }
    		
  			@enemies.each do |enemy|
  		    #For easter egg...
  				if enemy.fuck_x==0 ; f=5 ; elsif enemy.type=="thwomp" ; f=1.25 ; else ; f=1 ; end
  			
  				#For differing heights...
  				if enemy.type=~/koopa/ ; h=-36 ; elsif enemy.type=~/monster/ ; h = 24 ; else ; h=0 ; end
  			
  				#RESET enemy's position if character moves them off-screen far enough
  				if (not (@camera_x-enemy.x<+480 && @camera_x-enemy.x>-@screen_width-480))
  					if not enemy.dead?
  					  enemy.reset_position if (not (@camera_x-enemy.original_x<+360 && @camera_x-enemy.original_x>-@screen_width-360))
  					else
  					  @enemies.delete(enemy) if enemy.dead?
  					end
  				else
  					if @character.health > 0
  						if enemy.y < (@level.height * @level.tile_size) + @level.tile_size - 130 - enemy.vel_y.abs && ((enemy.y - @character.y) < 1600 || (not enemy.type=~/koopa/)) || enemy.kicked==false
  							enemy.update
  						else
  							enemy.place(-9999,9999) #So that the player can't reach to this enemy...
  						end
  					end
  				end
  		
  				#STOMP test
  				if enemy.type!="thwomp" && enemy.type!="boo" && enemy.type!="fish"
  				  if distance(@character.x,@character.y+75+h,enemy.x,enemy.y)<73 && @character.vel_y>1 && (not enemy.dead?)	&& enemy.not_attacked?
  					  if enemy.squished==false
  					    @character.score_add(4000-(enemy.health*1000), enemy) if enemy.type =~ /monster/ && enemy.battling? #IF DIZ IZ A BOZZ!!!
  					    #FORCE player to move over if boss ain't battling...
  					    @character.vel_x = -12 if enemy.type =~ /monster/ && (not enemy.battling?)
  						  enemy.stomp
  						  @character.score_add(100, enemy) if not enemy.type =~ /monster/
  				      @character.combo_add
  					  else
  						  enemy.stop_shell_bash
  						  enemy.kick if enemy.timer>3
  					  end
  				
  					  #BOUNCE
  					  @character.bounce((button_down?Button::KbUp)) if enemy.squash_h==0.0 && enemy.fuck_x!=0
  				  end
  				end
  			
  				#WEAPON test
  				@character.axes.each do |ax|
  					if distance(ax.x,ax.y,enemy.x,enemy.y)<82*f
  				    if (not enemy.dead?) && enemy.type!="boo" && enemy.type!="fortress_monster"
  				    	@character.score_add(100*f, enemy)
  							enemy.attack(ax.vx/1.5)
  							if enemy.type=="blue_koopa" || enemy.type=="goomba_mystery"
  							  @level.add_inventory("emerald",enemy.x+35,enemy.y)
  							  @level.add_inventory("sapphire",enemy.x,enemy.y-20)
  							  @level.add_inventory("ruby",enemy.x-35,enemy.y)
  							end
  						end
  					end
  				end
  				
  				@character.fireballs.each do |fire|
            if distance(fire.x,fire.y,enemy.x,enemy.y)<70*f && fire.out==false
              fire.kill if not enemy.dead?
              if (not enemy.dead?) && enemy.type!="thwomp" && enemy.type!="fortress_monster"
                @character.score_add(100*f, enemy)
                enemy.attack(fire.vel_x/2.5)
                @level.add_inventory("vine_growth",enemy.x,enemy.y+12) if enemy.type=="blue_koopa" && enemy.on_ground
                @level.add_inventory("clock_pickup",enemy.x,enemy.y+12) if enemy.type=="blue_koopa" && (not enemy.on_ground)
                if enemy.type=="goomba_mystery"
                  @level.add_inventory("emerald",enemy.x+35,enemy.y)
                  @level.add_inventory("sapphire",enemy.x,enemy.y-20)
                  @level.add_inventory("ruby",enemy.x-35,enemy.y)
                  dir = ["right", "left"]
                  @level.add_inventory("zorro_pickup",enemy.x,enemy.y-100,dir[rand(dir.size)])
                end
              end
            end
          end
          
          #Destroy all enemies upon completion...
          enemy.attack(-enemy.vel_x/2,"complete") if @character.complete==true && (not enemy.dead?)
  		
  				#ATTACK character or KICK enemy
  				if (distance(@character.x,@character.y+64+h,enemy.x,enemy.y)<enemy.collision_factor+74*f ||
  				   distance(@character.x,@character.y-32+(1000*@character.ducking_rate),enemy.x,enemy.y)<enemy.collision_factor+74*f ||
  				   distance(@character.x,@character.y+(1000*@character.ducking_rate),enemy.x,enemy.y)<enemy.collision_factor+74*f)	
  					if (@character.time_attck==0 && @character.alive==true && (not enemy.dead?) &&
  					  @character.y>enemy.y-92) && (enemy.kicked==true || enemy.squished==false) && enemy.not_attacked?
  						if enemy.type=~/goomba/
  							@character.attacked(1*f,enemy.vel_x)      if @character.x >= enemy.x
  							@character.attacked(-1*f,enemy.vel_x)     if @character.x < enemy.x
  						elsif enemy.type=~/koopa/
  							if enemy.kicked==true
  					      @character.attacked(1*f,enemy.vel_x)  if @character.x>=enemy.x && enemy.vel_x>0
  								@character.attacked(-1*f,enemy.vel_x) if @character.x<enemy.x && enemy.vel_x<0
  							else
  								@character.attacked(1*f,enemy.vel_x)  if @character.x >= enemy.x
  								@character.attacked(-1*f,enemy.vel_x) if @character.x < enemy.x
  							end
  						else
  						  @character.attacked(1,2)  if @character.x >= enemy.x
                @character.attacked(-1,2) if @character.x  < enemy.x
  						end
  						@character.die if @character.health<1 && enemy.fuck_x!=0
  					end
  					
  					#THE GREAT EASTER EGG OF DEATH!!!
  					@character.die_horribly if enemy.fuck_x==0
  					
  					if enemy.kicked==false && @character.time_attck==0
  						(@character.vel_x /= 3 ; enemy.kick) if enemy.timer>3 && (not enemy.type =~ /monster/)
  					end
  				end
  				
  				#EXPLODING BOSSES
  				if enemy.type=~/monster/
  				  (8.times { @enemy_ex.push(Explosion.new(self,enemy.x,enemy.y,rand(100.0)/10000.0)) } ; @level.shake(45) ; @snd_EXPLS.play(2)) if enemy.dead
  				end
  			end
  			
  			#DEATH
  			@enemies.reject! { |enemy| enemy.dead }
  			
  			#EXPLOSIONS
  			@enemy_ex.reject! { |explosion| explosion.out? }
  	
  			#CHECK enemy collision with each other...
  			for i in 0...@enemies.length
  				for j in i+1...@enemies.length
  					if distance(@enemies[i].x,@enemies[i].y,@enemies[j].x,@enemies[j].y)<84
  				  		#SHELL COLLISION!!!
  						if @enemies[i].x > -400
  							(@enemies[j].attack(@enemies[i].vel_x/1.5);
  							@character.score_add(100*@enemies[i].combo, @enemies[j]);
  							@enemies[i].combo_add) if @enemies[i].kicked==true && (not @enemies[j].dead?)
  							(@enemies[i].attack(@enemies[j].vel_x/1.5);
  							@character.score_add(100*@enemies[j].combo, @enemies[i]);
  							@enemies[j].combo_add) if @enemies[j].kicked==true && (not @enemies[i].dead?)
  						end
  					
  						#GET IN THE WAY!!!
  						if @enemies[i].kicked==false && @enemies[j].kicked==false && (not @enemies[j].dead?) && (not @enemies[i].dead?)
  							if ((@enemies[i].direction=="right" || @enemies[i].vel_x==0) && @enemies[j].x>@enemies[i].x)
  								if @enemies[i].type!="blue_koopa" && @enemies[j].type!="blue_koopa"
  									@enemies[i].flipToDirection("left")
  									@enemies[j].flipToDirection("right")
  								end
  							elsif ((@enemies[i].direction=="left" || @enemies[i].vel_x==0) && @enemies[j].x<@enemies[i].x)
  								if @enemies[i].type!="blue_koopa" && @enemies[j].type!="blue_koopa"
  									@enemies[j].flipToDirection("left")
  									@enemies[i].flipToDirection("right")
  								end
  							end
  						end
  					end
  				end
  			end
    
    		#ASSIGN controls
    		@character.move_direction("right", (button_down?Button::KbRight))
    		@character.move_direction("left", (button_down?Button::KbLeft))
    		@character.try_jump((button_down?Button::KbUp))
    		@character.try_duck((button_down?Button::KbDown)) if @character.complete == false
    
    		#RUN "Shift"
    		#Pass in both right and left button ids to prevent the user from running/walking using only the shift key.
    		@character.try_run((button_down?Button::KbLeftShift), (button_down?Button::KbRight), (button_down?Button::KbLeft))
    	end
    	
    	#UPDATE the tinted tiles when time changes
      @level.update(@background, @character, @camera_x, @camera_y, @screen_width, @screen_height) if @transition.size > 0 && @PAUSED == false
    
    	#UPDATE song
   		if @character.health > 0
    		(@music.update ; @boss_song.stop) if @transition.size > 0 && @character.pipe_y == 0 && @character.battling == false
    		@music.stop if @character.pipe_y != 0 || @character.complete != false || (@level.auto_enter==true && @level.entry_opener==0) || @character.battling == true
    		
    		#BOSS music
    		@boss_song.update if @character.battling == true
    		@boss_song.stop   if @character.complete == true
    	else
    		@music.stop
    		@boss_song.stop
    	end
    
    	#TRANSITION, CHANGE or RESTART level if character dead or alive...
    	if @character.alive == false || @character.pipe_y.abs > 6 || @character.escaped_level? ||
    	   (@level.auto_enter==true && @level.entry_opener==0)
    	  @transition.fast = -0.01 if @level.auto_enter==true
    		@transition.transition = "close"
    		if @transition.completely_closed?
    	  		start_level(0) if @character.pipe_y==0 && (not @character.escaped_level?) && @level.auto_enter==false
    	  		change_arena           if @character.pipe_y!=0
    	  		change_arena("castle") if @level.auto_enter==true
    	  		if @character.escaped_level?
    	  		  @character.win_y = 0
    	  		  if @LEVEL_ACCESS < @TOTAL_LEVELS && @LEVEL_NUMBER == @LEVEL_ACCESS
    	  		    #CASTLE CLEAR BONUS (first-time ONLY)...
                if @level.type=="castle"
                  value = @LEVEL_NUMBER / 10
                  @character.coin_add("coin", 50 * value)
                  set_monetary(-50 * value, 0, 0, 0)
                end
    	  		    @LEVEL_ACCESS += 1
    	  		  end
    	  		  scroll_level(1)
    	  		end
    	  		(@GAME_MODE = "Game Over" ; @snd_GMOVR.play) if @character.game_over==true
    		end
    	end
    
    	#SCROLL LEVEL selection
    	if @transition.completely_closed? && @character.pipe_y==0
      	if @loadX.abs < 80
        	@snd_NEXT.play(0.5) if @load_level == "next"
  	    	@snd_PREV.play(0.5) if @load_level == "prev"
  	  	end
      	if @load_level == "next"
    		  @loadX += 160
    		  (@loadX = -@screen_width - 320 ; start_level(1)) if @loadX > @screen_width/2 + 480
      	end
      	if @load_level == "prev"
        	@loadX -= 160
    		  (@loadX = @screen_width + 320 ; start_level(-1)) if @loadX < -@screen_width/2 - 480
      	end
      	if @load_level == "neutral"
      		if @loadX.abs > 1
      	  		@loadX /= 1.2
      		else
      	  		@loadX = 0
      		end
      	end
      	#EXECUTE OPENING transition when zoom fades out completely...
        @transition.transition="open" if @level.zoom_color.red<=1
      end
    end
  end
  
  def button_up(id)
    #MAKES the character jump and RESETS the button hold...
    if id==Button::KbUp
      	if @transition.size > 0 && @PAUSED == false
      		@character.jump
      		@character.jump_button_reset = true
      	end	
      #EXECUTE OPENING transition when "up button" is pressed and released...
      if @transition.completely_closed?
        @level.started = true
      end
      @MENU_TIME = 501 if @GAME_MODE == "Menu"
      (@level.started=false ; reset_game) if @GAME_MODE == "Game Over"
    end
  end
  
  def button_down(id)
    #PAUSE
    if id==Button::KbEscape
        if @transition.completely_opened? && @level.auto_enter==false &&
           @character.health>0            && @character.vel_y<1       &&
           @character.complete==false     && @character.pipe_y==0
            if @PAUSED == false
                @PAUSED = true
            else
                @PAUSED = false
            end
        end
    end
    
    #CHARACTER float/swim action! (ONLY when using zorro-bat suit)
    (@character.float ; @character.swim) if id==Button::KbUp && @transition.size>0 && @level.msg_ACT==false
    
    #PAUSE navigation
    if @PAUSED == true
      (@pause_select+=1 ; @snd_NEXT.play(0.5, 2.0)) if id==Button::KbRight
      (@pause_select-=1 ; @snd_PREV.play(0.5, 2.0)) if id==Button::KbLeft
      #PAUSE ITEM selected
      if id==Button::KbUp
        @snd_EXPLS.play(0.7, 4.0)
        case @pause_select
        when 0
          @PAUSED = false #RESUME playing the game...
        when 1
          #PAY to exit level...
          if @character.coins>-1
            value1, value2 = 25, 0
            value1 = @character.coins if @character.coins < 25
            value2 = 1 if @character.coins < 1
            @character.buy("level_exit",value1,value2)
            set_monetary(value1,value2,0,0)
          end
          @music.stop
          @boss_song.stop
          @character.searcher = false
          @transition.transition = "close"
          @transition.size = 0.0 #EXIT the current level...
          start_level(0)
          @PAUSED = false
          @pause_x = -@PAUSE_MENU.width
        when 2
          @music.stop
          @boss_song.stop
          self.close() #EXIT the entire program...
        else
        end
      end
    end
    
    #NAVIGATE level selection
    if @GAME_MODE != "Game Over"
      #LEVEL selection menu...
      if @transition.completely_closed? && @level.zoom_size <= 1.0
    	  scroll_level(1)  if id==Button::KbRight && @LEVEL_NUMBER<@LEVEL_ACCESS && @LEVEL_NUMBER<@TOTAL_LEVELS
    	  scroll_level(-1) if id==Button::KbLeft  && @LEVEL_NUMBER>1
    	  exit_game=false
    	  #EXIT game app...
        (exit_game=true ; @snd_EXPLS.play(0.7, 4.5)) if id==Button::KbEscape && @level.auto_enter==false && @loadX==0
        self.close() if exit_game
      else
    	  @character.throw_projectile if id == Button::KbLeftShift && @character.complete==false && @character.pipe_y==0 && @level.msg_ACT==false && (not @transition.completely_closed?)
    	  @level.msg_ACT = false if @level.msg_ACT == true && id==Button::KbUp && @PAUSED == false
      end
    end
  end
end

#TRY
begin
  
  Game.new.show
  
#ERROR!!!  
rescue => e
  
  #MAKE text read-able...
  lines = e.backtrace.to_s.split(":")
  error_result = "DATE: #{DateTime.now.strftime("%F")}\nTIME: #{DateTime.now.strftime("%I:%M%p")}\n\n#{e.message}\n"
  
  #FORMAT text
  for i in 0..(lines.size-1)
    #if counter is even
    if i % 2 == 0
      method    = lines[i].split(/`|'/)
      path      = lines[i].split("/")
      filename  = path[path.size-1]
      if method[1].to_s.length>1
        error_result += "Method: #{method[1]}\nFile: #{filename}\nLine: "
      else
        error_result += "File: #{filename}\nLine: "
      end
    #else, counter is odd
    else
      error_result += "#{lines[i]}\n\n"
    end
  end
  
  #SHOW ERROR RESULT (check OS first)
  if RUBY_PLATFORM =~ /mswin|msys|mingw|cygwin|bccwin|wince|emc/
    system %{cmd /c "start data\\error.log"}
    os = "OS: WINDOWS\n"
  elsif RUBY_PLATFORM =~ /darwin|mac os/
    system %{open "data/error.log"}
    os = "OS: MAC\n"
  elsif RUBY_PLATFORM =~ /linux/
    os = "OS: LINUX (../data/error.log file has been updated)\n"
  elsif RUBY_PLATFORM =~ /solaris|bsd/
    os = "OS: UNIX (../data/error.log file has been updated)\n"
  else
    os = "OS: UNKNOWN (../data/error.log  file has been updated)\n"
  end
  
  #OUTPUT error message to log file...
  file = File.new("data/error.log",'w')
  file.puts(os+error_result)
  file.close
end