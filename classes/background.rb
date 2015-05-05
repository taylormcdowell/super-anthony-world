class Background
  #Make these variables accessible outside of class
  attr_reader :hour, :hour_transition, :color, :current_hour
  
  def initialize(window, theme="overworld")
    #Window information...
    @window, @theme = window, theme
    
    #Check the current hour (now)
    @current_hour = DateTime.now.hour
    
    #In case the date cannot be calculated, declare a hour variable with its default value.
    @hour = "day"
    
    #Check date to determine if it's day or night; also, the general color will be determined.
    if @current_hour >= 7 and @current_hour < 19
    	@hour = "day"
    	@color = Color.new(0xffffffff)
    	@wind_rate = 0.5 # CLOUD speed
    else
    	@hour = "night"
    	@color = Color.new(0xff444455)
    	@wind_rate = 0.25 # CLOUD speed
    end
    
    #LOAD the images with the determined hour...
    if theme =~ /overworld|castle|marcoux/
      @background = Image.new(@window, "artwork/background/sky_#{@hour}.png", false)
      @cloud_move = Image.new(@window, "artwork/background/clouds_#{@hour}.png", false)
      @scroll_bck = Image.new(@window, "artwork/background/background_#{theme}.png", false)
      @scroll_frt = Image.new(@window, "artwork/background/foreground_#{theme}.png", false) if theme == "castle"
    else
      @background = Image.new(@window, "artwork/background/sky_underground.png", false)
    end
    
    #TRANSITION MAKERS!!!
    @fader  = Image.new(@window, "artwork/level/hour_fader.png", true)
    @washer = Image.new(@window, "artwork/level/hour_washer.png", false)
    @msgDay = Image.new(@window, "artwork/level/daytime.png", false)
    @msgNgt = Image.new(@window, "artwork/level/nighttime.png", false)
    @hr_alp = Color.new(0x00ffffff)
    
    #LEVEL theme display
    genres = File.readlines("levels/levels.genre").map { |line| line.chomp}
    @type  = genres[@window.LEVEL_NUMBER-1].downcase
    @lev_b = Image.new(@window, "artwork/menu/level_background_#{@hour}.png", true)
    @lev_w = Image.new(@window, "artwork/menu/level_water_overlay_#{@hour}.png", true)
    @waterflow = 0
    if File.exist?("artwork/menu/level_themes/#{@type}.png")
      @genre = Image.new(@window, "artwork/menu/level_themes/#{@type}.png")
    else
      @genre = Image.new(@window, "artwork/zblank.png")
    end
    
    #LOAD scrollable deep backdrops...
    @scrll_dbck = Image.new(@window, "artwork/background/deep_background_#{theme}.png", false)
    
    #LOAD moon-glow image...
    @moon_glow = Image.new(@window, "artwork/background/moon_glow.png", false)
      
    #Cloud position
    @cloud_x = 0
    
    #HOUR transition...
    @hour_transition = 0
  end
  
  #PREVIEW
  def preview(x,y,z)
    y -= 45 if @type == "castle"
    
    #WATER Movement...
    @waterflow += 1
    @waterflow %= @window.screen_width*2
    
    #BACKGROUND
    @lev_b.draw(0, 0, 100000)
    
    #WATER
    if @hour == "night"
      @lev_w.draw(-@waterflow, 395.5, 100001, 2, 1, 0x33ffffff, :additive)
      @lev_w.draw(-@waterflow - 1 + @lev_w.width*2, 395.5, 100001, 2, 1, 0x33ffffff, :additive)
      @lev_w.draw(@waterflow, 395.5, 100000, 2, 1, 0x33ffffff, :additive)
      @lev_w.draw(@waterflow + 1 - @lev_w.width*2, 395.5, 100000, 2, 1, 0x33ffffff, :additive)
    else
      @lev_w.draw(-@waterflow, 395.5, 100001, 2, 1, 0xff888888, :additive)
      @lev_w.draw(-@waterflow - 1 + @lev_w.width*2, 395.5, 100001, 2, 1, 0xff888888, :additive)
      @lev_w.draw(@waterflow, 395.5, 100000, 2, 1, 0xcc888888, :additive)
      @lev_w.draw(@waterflow + 1 - @lev_w.width*2, 395.5, 100000, 2, 1, 0xcc888888, :additive)
    end
    
    #OBJECT
    color_back = 0xffffffff ; color_back = 0xff222244 if @hour == "night"
    @genre.draw(x, y, z, 1, 1, color_back)
    
    #REFLECTION
    color_refl = 0xbb888888 ; color_refl = 0xaa112244 if @hour == "night"
    @genre.draw_as_quad(x,                y + @genre.height*1.9, 0x00000000,
                        x + @genre.width, y + @genre.height*1.9, 0x00000000,
                        x,                y + @genre.height,     color_refl,
                        x + @genre.width, y + @genre.height,     color_refl, 100000)
  end
    
  #Draw all of the images...
  def draw(sx, sy, ssx, ssy)
    #BACKGROUND (THE SKY)
    #EXPAND background image if screen width is greater than 1600
    if ssx > 1600
    	size = 1.2
    else
    	size = 1.0
    end
    #COLOR change when level complete
    @completion = 0xffffffff if @window.character.complete == false
    @background.draw(0, 0, -4, size, size, @completion)
    
    #CHECK if hour needs to be changed...
    if @theme == "overworld"
      if DateTime.now.hour >= 7 and DateTime.now.hour < 19
    	  if @hour!="day"
    		  @hour = "day"
    		  @hour_transition = 127
        end
      else
    	  if @hour!="night"
    		  @hour = "night"
    		  @hour_transition = 127
        end
      end
    
      #MAKE time-passing-like transition
      if @hour_transition > 0
    	  if @hour=="day"
    		  @washer.draw(0,0,999,2*size,2*size,@hr_alp,:additive)
    		  if @hour_transition == 64
    		  	  @color = Color.new(0xffffffff)
    			  @wind_rate = 0.75 # CLOUD speed
    			  @background = Image.new(@window, "artwork/background/sky_#{@hour}.png", false)
        		  @cloud_move = Image.new(@window, "artwork/background/clouds_#{@hour}.png", false)
    		  end
    		
    		  #SEND a time message for DAY
    		  if @hour_transition < 90
    			  @msgDay.draw_rot(ssx/2, ssy/2, 1000, 0)
    		  end
    	  else
    		  @fader.draw(0,0,999,2*size,2*size,@hr_alp)
    		  if @hour_transition == 64
    		  	@color = Color.new(0xff444455)
    			  @wind_rate = 0.25 # CLOUD speed
    			  @background = Image.new(@window, "artwork/background/sky_#{@hour}.png", false)
        		@cloud_move = Image.new(@window, "artwork/background/clouds_#{@hour}.png", false)
    		  end
    		
    		  #SEND a time message for NIGHT
    		  if @hour_transition < 90
    			@msgNgt.draw_rot(ssx/2, ssy/2, 1000, 0)
    		  end
    	  end
    	
    	  #ACCUMULATE hour_transition variable and change alpha for the washers (white-out) and faders (black-out)!
    	  @hour_transition -= 1
    	  @hr_alp.alpha += 4 if @hour_transition > 64 && @hr_alp.alpha < 251
    	  @hr_alp.alpha -= 4 if @hour_transition < 65 && @hr_alp.alpha > 4
      end
    else
      @color = Color.new(0xffffffff)
    end
       
    #obstacle change when completed
    (@completion=0xff5555aa ; @color=Color.new(0xff202090)) if @window.character.complete==true && @theme!="castle"
        
    if @theme == "overworld"
      #CLOUD CODE (tiled):
      if @window.character.complete == false
        @cloud_move.draw(@cloud_x, 0, -3)
        @cloud_move.draw(@cloud_x + @cloud_move.width, 0, -3)
        @cloud_move.draw(@cloud_x + (@cloud_move.width*2), 0, -3)
        @cloud_x = 0 if @cloud_x < -@cloud_move.width
        @cloud_x -= @wind_rate
      end
    
      #SCROLLABLE BACKGROUND
      @scroll_bck.draw(-sx/4, -sy/7, -2.5, 1, 1, @color)
      @scroll_bck.draw(-sx/4 + @scroll_bck.width, -sy/7, -2.5, 1, 1, @color)
      @scroll_bck.draw(-sx/4 + (@scroll_bck.width*2), -sy/7, -2.5, 1, 1, @color)
      
      #DEEP SCROLLABLE BACKGROUND
      @scrll_dbck.draw(-sx/12, -sy/22 + 350, -3.5, 1, 1, @color)
      @scrll_dbck.draw(-sx/12 + @scrll_dbck.width, -sy/22 + 350, -3.5, 1, 1, @color)
    
      #MOON-GLOW (night only)
      @moon_glow.draw_rot(340 * size, 175 * size, -2.75, 0, 0.5, 0.5, 0.7, 0.7, 0x90ffffff, :additive) if @hour == "night"
    
      #SUN-GLARE (day only)
      @moon_glow.draw_rot(200, 150, -2.75, 0, 0.5, 0.5, 0.4, 0.4, 0x72ffffff, :additive) if @hour == "day"
    elsif @theme == "castle"
      #CLOUD CODE (tiled):
      if @window.character.complete == false
        @cloud_move.draw(@cloud_x, 0, -3)
        @cloud_move.draw(@cloud_x + @cloud_move.width, 0, -3)
        @cloud_move.draw(@cloud_x + (@cloud_move.width*2), 0, -3)
        @cloud_x = 0 if @cloud_x < -@cloud_move.width
        @cloud_x -= @wind_rate
      end
    
      #SCROLLABLE BACKGROUND
      @scroll_bck.draw(-(sx/1.0).to_i - 10, -sy.to_i, -2.5, 1, 1, @color)
      @scroll_bck.draw(-(sx/1.0).to_i - 10 + @scroll_bck.width, -sy.to_i, -2.5, 1, 1, @color)
      @scroll_bck.draw(-(sx/1.0).to_i - 10 + (@scroll_bck.width*2), -sy.to_i, -2.5, 1, 1, @color)
      @scroll_bck.draw(-(sx/1.0).to_i - 10 + (@scroll_bck.width*3), -sy.to_i, -2.5, 1, 1, @color)
      
      #REPEAT VERTICALLY
      @scroll_bck.draw(-(sx/1.0).to_i - 10, -sy.to_i + @scroll_bck.height, -2.5, 1, 1, @color)
      @scroll_bck.draw(-(sx/1.0).to_i - 10 + @scroll_bck.width, -sy.to_i + @scroll_bck.height, -2.5, 1, 1, @color)
      @scroll_bck.draw(-(sx/1.0).to_i - 10 + (@scroll_bck.width*2), -sy.to_i + @scroll_bck.height, -2.5, 1, 1, @color)
      @scroll_bck.draw(-(sx/1.0).to_i - 10 + (@scroll_bck.width*3), -sy.to_i + @scroll_bck.height, -2.5, 1, 1, @color)
      
      #SCROLLABLE FOREGROUND
      @scroll_frt.draw(-(sx*1.25).to_i + 500, -(sy*1.25).to_i, 5, 1, 1.25, @color)
      @scroll_frt.draw(-(sx*1.25).to_i + 500 + @scroll_frt.width*1.2, -(sy*1.25).to_i, 5, 1, 1.25, @color)
      @scroll_frt.draw(-(sx*1.25).to_i + 500 + (@scroll_frt.width*2.4), -(sy*1.25).to_i, 5, 1, 1.25, @color)
    
      #MOON-GLOW (night only)
      @moon_glow.draw_rot(340 * size, 175 * size, -2.75, 0, 0.5, 0.5, 0.9, 0.9, 0x90ffffff, :additive) if @hour == "night"
    
      #SUN-GLARE (day only)
      @moon_glow.draw_rot(200, 150, -2.75, 0, 0.5, 0.5, 0.4, 0.4, 0x72ffffff, :additive) if @hour == "day"
    elsif @theme == "dr_marcoux"
      @cloud_x = 0 if @cloud_x < -@scrll_dbck.width
      @cloud_x -= @wind_rate
      @scroll_bck.draw(0,0,-2.5)
      @scrll_dbck.draw(@cloud_x,0,-3)
      @scrll_dbck.draw(@cloud_x+@scrll_dbck.width,0,-3)
      @scrll_dbck.draw(@cloud_x+(@scrll_dbck.width*2),0,-3)
    else
      #DEEP SCROLLABLE BACKGROUND
      @scrll_dbck.draw(-sx/12, -sy/24, -2.1, 1, 1, @color)
      @scrll_dbck.draw(-sx/12 + @scrll_dbck.width, -sy/24, -2.1, 1, 1, @color)
    end
  end
end



#FOREGROUND, CLOSING-BUBBLES, ETC...
class TransitionBubble
  #Make these variables accessible and writable outside of class
  attr_reader :size, :fast, :transition
  attr_writer :transition, :fast, :size
  
  def initialize(window, trans="open")
    #Window information...
    @window, @transition = window, trans
    
    #Starting size...
    @size = 0.0 ; @fast = 0.0

    #TRANSITION MAKERS!!!
    @blacks  = Image.new(@window, "artwork/level/hour_fader.png", false)
    @bubble  = Image.new(@window, "artwork/trans_bubble.png", false)
  end
  
  #UPDATE re-sizing...
  def update
    @size += @size/75 + 0.025 + @fast if @transition == "open" and @size < 7
    @size -= @size/75 + 0.025 + @fast if @transition != "open" and @size > -0.25
    @fast = 0.0 if @transition != "open"
  end
  
  def completely_closed?
  	@size < -0.25
  end
  
  def completely_opened?
    @size >= 6
  end
    
  #Draw all of the images...
  def draw(sx, sy, character)
    x, y = character.x-sx, character.y-sy-60
    offset_x = (@bubble.width*@size)/2
    offset_y = (@bubble.height*@size)/2
    #DRAW the bubble directly over the character...
    @bubble.draw_rot(x, y, 9999, 0, 0.5, 0.5, @size, @size)
    
    #DRAW black bars to avoid showing our cheesy attempt trying-to-hide-shit-that-we-don't-want-gamers-to-see...
    @blacks.draw_rot(x - offset_x + 5, y, 10000, 0, 1.0, 0.5, 5, 5) #RIGHT
    @blacks.draw_rot(x + offset_x - 5, y, 10000, 0, 0.0, 0.5, 5, 5) #LEFT
    @blacks.draw_rot(x, y + offset_y - 5, 10000, 0, 0.5, 0.0, 5, 5) #TOP
    @blacks.draw_rot(x, y - offset_y + 5, 10000, 0, 0.5, 1.0, 5, 5) #BOTTOM
  end
end