#PARTICLES - for pieces of tiles, smoke, etc...
class Particle
  #Make variables accessible
  attr_reader :x, :y, :vel_x, :vel_y, :transparency, :out, :type, :size
  attr_writer :out, :vel_x, :vel_y, :transparency, :size
    
  def initialize(window, x=0, y=0, vx=0, type="brick", transparency=0)
    #Particle's position and current angle
    @window = window
    @x, @y, @type = x, y, type
    
    if type =~ /brick/
      @vel_x, @vel_y = vx+4-rand(8), -rand(5)-20
      @angle = 0
      @size = 1.0
      @transparency = transparency
    elsif type =~ /fairy/
      @vel_x = @vel_y = vx
      @angle = 0
      @size = 1.0
      @transparency = transparency
      random = 25 + rand(230)
      @color = Color.new(255, random, random, random)
    elsif type =~ /flame/
      @vel_y = vx
      @vel_x = (0.2 - rand(1.0)/2.5)
      @angle = rand(360)
      @size = 0.65 + (rand(10).to_f/15.to_f)
      @transparency = transparency
      random = 105+rand(150)
      @color = Color.new(255, 255, random, 40)
      @basic = Color.new(0xff900000)
      if vx == -1.5
        @projectile = false
      else
        @projectile = true
        @size += 0.75
      end
    elsif type =~ /bubble/
      @vel_x, @vel_y = 0.5-(rand(20.0)/10.0) + vx, -1.0 - (rand(15.0)/10.0)
      @angle = 0
      @size = 0.15 + ((rand(50.0)).to_f/100.0)
      @transparency = 0
    elsif type =~ /water/
      @vel_x, @vel_y = vx+5-rand(10), -rand(5)-@window.character.vel_y.abs/1.5
      @angle = 0
      @size = 0.4 + (rand(9.0)/10.0)
      @transparency = transparency
    else
      @vel_x, @vel_y = vx + rand(25)/25.0, -rand(0.2) - 0.1
      @angle = rand(360)
      @size = 0.5
      @transparency = transparency
    end
    
    #Particle image
    @image = Image.new(@window,"artwork/particles/#{type}.png",true)
    @out = false
  end

  #Draw elements
  def draw(scr_x, scr_y, color=Color.new(0xffffffff), hour="day", z=0.8)
    #CHANGE smoke color...
    if @type == "smoke"
      if hour == "night"
        color.red   = 220
        color.green = 220
        color.blue  = 220
      else
        color.red   = 255
        color.green = 255
        color.blue  = 255
      end
    end
    
    #FADE out
    if @type == "smoke"
      if @transparency < 253
        @transparency += 1.5
      else
        @out = true
      end
      color.alpha -= @transparency.to_i
    elsif @type == "fairy_dust"
      if @transparency < 250
        @transparency += 7
      else
        @out = true
      end
      #TWINKLE...
      random = rand(255) - @transparency.to_i
      @color.alpha = random if random >= 0
    elsif @type == "flame"
      if @transparency < 240
        @transparency += 6 + @vel_x.abs
      else
        @out = true
      end
      if @transparency<255
        @color.alpha = 255-@transparency.to_i
        @basic.alpha = 255-@transparency.to_i/5
      else
        @transparency = 255
        @color.alpha = 0
        @basic.alpha = 51
      end
    elsif @type == "bubble"
      if @y < @window.level.water_level + 12
        @out = true
      end
    elsif @type == "water"
      if @y > @window.level.water_level + 24
        @out = true if @vel_y >= 0
      end
    end
    
    @size += 0.0175 if @type == "smoke"
    
    #Another way to put it out...
    if @type =~ /flame/
      @size /= 1.12
      if @projectile==true
        @size /= 1.4
        @out = true if @size < 0.3
      else
        @out = true if @size < 0.15
        z = 0.0
      end
    end
    
    #Draw the particle itself
    if @type!="bubble"
      @image.draw_rot(@x - scr_x, @y - scr_y, z, @angle, 0.5, 0.5, @size, @size, color) if @type!="fairy_dust" && @type!="flame"
      @image.draw_rot(@x - scr_x, @y - scr_y, 0.1, @angle, 0.5, 0.5, @size, @size, @color, :additive) if @type=="fairy_dust"
    
      #FIRE source
      if @type=="flame"
        @image.draw_rot(@x - scr_x, @y - scr_y, z-0.01, @angle, 0.47, 0.53, @size*1.2, @size*1.2, @basic)
        @image.draw_rot(@x - scr_x, @y - scr_y, z, @angle, 0.47, 0.53, @size/1.1, @size, @color, :additive)
      end
    else
      @image.draw_rot(@x - scr_x, @y - scr_y, 6, 0, 0.5, 0.5, @size, @size, 0x75ffffff, :additive) if @y >= @window.level.water_level + 12
    end
    
    if @type=="water"
      4.times do
        @image.draw_rot(@x - scr_x, @y - scr_y, z, @angle, 0.47, 0.53, @size, @size, 0xaaffffff)
        @image.draw_rot(@x - scr_x + 64 - rand(128), @y - scr_y + 64 - rand(128), z, @angle, 0.47, 0.53, @size, @size, 0x88ffffff, :additive)
      end
      @size /= 1.0325
    end
    
    @angle += @vel_x / 1.5 - @vel_x.abs / 4 if not type=~/bubble/ #Make it rotate depending on horizontal motion
    @vel_y += 1          if @type=~/brick|water/ #Gravity
    @vel_x /= 1.05       if @type=~/smoke|bubble/ #Gravity
    @vel_y = -rand(0.25) if @type=~/fairy/ #Gravity
    @vel_y -= 0.1        if @type=~/flame/ #Gravity
    
    #PHYSICAL ACCUMULATORS
    @x += @vel_x
    @y += @vel_y
  end
end

#Assign Objects to index
module Objects
    GrassLeft           = 0
    GrassMid            = 1
    GrassRight          = 2
    GrassSingle         = 3
    GrassSingleFloat    = 4
    DirtLeft            = 5
    DirtBase            = 6
    DirtRight           = 7
    DirtMiddle          = 8
    DirtTop             = 9
    DirtTopLeft         = 10
    DirtTopMiddle       = 11
    DirtTopRight        = 12
    DirtBottom          = 13
    DirtBottomLeft      = 14
    DirtBottomMiddle    = 15
    DirtBottomRight     = 16
    Brick               = 17
    ItemBlock           = 18
    PipeTopLeft         = 19
    PipeTopRight        = 20
    PipeMidLeft         = 21
    PipeMidRight        = 22
    PipeBtmLeft         = 23
    PipeBtmRight        = 24
    PassableFiller      = 25
    PassableLeft        = 26
    PassableRight       = 27
    PassableTop         = 28
    PassableTopLeft     = 29
    PassableTopRight    = 30
    PassableBottom      = 31
    PassableBottomLeft  = 32
    PassableBottomRight = 33
    PassableCaged       = 34
    PassableSupport     = 35
    PassableSingle      = 36
    StoneLeft           = 37
    StoneLeftDamaged    = 38
    StoneRight          = 39
    StoneRightDamaged   = 40
    IndoorBase          = 41
    IndoorTop           = 42
    IndoorTopRight      = 43
    IndoorTopLeft       = 44
    IndoorPedestial     = 45
    IndoorPedestialBase = 46
    PillarCastle        = 47
    TorchHolder         = 48
    HelpBlock           = 49
    HardBlock           = 50
    InvisibleBlock      = 51
    Invisible           = 52
end

class LevelClass
  #Make variables accessible to Main.rb
  attr_reader :tile_size, :width, :height, :type,
              :start_x, :start_y, :return_x, :return_y,
              :finish_x, :finish_y, :coins, :spawners,
              :particles, :hour, :entry_coords, :auto_enter,
              :entry_opener, :earthquake, :msg_ACT, :zoom_size, :zoom_color,
              :water_level, :shopping, :torches
  attr_writer :msg_ACT, :started
  
  def initialize(window,level=1,hour="day",type="obstacle")
      
    #Window and other information...
    @window, @hour = window, hour
    directory = "levels/#{level}/#{type}.lvl"
    directory = "levels/shop.lvl" if type=="dr_marcoux"
    
    #DO THIS only if level should be created based on existing files...
    if File.exist?(directory)
    #Adjust object color tint based on hour...
    @color = Color.new(0xffbbbcff) if hour == "night"
    @color = Color.new(0xffffffff) if hour == "day"
    @inv_color = Color.new(0xffccc0cc) if hour == "night"
    @inv_color = Color.new(0xffffffff) if hour == "day"
      
    #Player's start and end position (AND MOAR...)
    @start_x,  @start_y  = 0, 0
    @return_x, @return_y = 0, 0
    @secret_x, @secret_y = 0, 0
    @finish_x, @finish_y = -999, -999
    @danger_x, @danger_y = -999, -999
    @drmarc_x, @drmarc_y = -999, -999 #SHOP GUY ;)
    @shopping = @off_grd = false
    @dr_i, @dr_r, @dr_t, @dr_d = Image.new(@window, "artwork/misc_characters/marcoux.png", true), 0, 60, 30
    
    #LOAD sign images
    @start  = Image.new(@window, "artwork/signs/start_sign.png", false)
    @end    = Image.new(@window, "artwork/signs/end_sign.png", false)
    @danger = Image.new(@window, "artwork/signs/danger_sign.png", false)
    @search = Image.new(@window, "artwork/inventory/searcher.png", false)
    @fy,@fd = 0,true 
    @type   = type
    
    #WATER/DIRT images and level...
    @water_top   = Image.load_tiles(window,"artwork/level/water.png",184,184,true)[0]
    @water_base  = Image.load_tiles(window,"artwork/level/water.png",184,184,true)[1]
    if type != "castle"
      @dirt_top    = Image.load_tiles(window,"artwork/level/dirt_back.png",184,184,true)[0]
      @dirt_base   = Image.load_tiles(window,"artwork/level/dirt_back.png",184,184,true)[1]
    else
      @dirt_top    = Image.load_tiles(window,"artwork/level/dirt_back_castle.png",184,184,true)[0]
      @dirt_base   = Image.load_tiles(window,"artwork/level/dirt_back_castle.png",184,184,true)[1]
    end
    @water_wave  = @water_tide = @tide = 0 #FOR SCROLLING and RISES...
    @water_level, @dirt_level = 10000, 10000
      
    #Default tile size in both the width and height (tile spacing)...
    @tile_size = 92
    
    #In case the image is a tad larger than the defined @tile_size, set it more towards the center
    @tile_offset = 0 #Both x and y...
    
    #BACKGROUND scraps...
    @castle_entry = [Image.new(window,"artwork/level/hour_fader.png",true)]
    @auto_enter   = false
    @hidden       = true
    @entry_coords = [0, 0]
    @entry_opener = 0
    @earthquake   = 0
      
    #Make array to store (push) all tiles; in other words, a tileset.
    @tileset = []
    @tileset.push(Image.new(window,"artwork/level/grass_left.png",true))
    @tileset.push(Image.new(window,"artwork/level/grass_mid.png",true))
    @tileset.push(Image.new(window,"artwork/level/grass_right.png",true))
    @tileset.push(Image.new(window,"artwork/level/grass_single.png",true))
    @tileset.push(Image.new(window,"artwork/level/grass_single_float.png",true))
    @tileset.push(Image.new(window,"artwork/level/dirt_left.png",true))
    @tileset.push(Image.new(window,"artwork/level/dirt_base.png",true))
    @tileset.push(Image.new(window,"artwork/level/dirt_right.png",true))
    @tileset.push(Image.new(window,"artwork/level/dirt_mid.png",true))
    @tileset.push(Image.new(window,"artwork/level/dirt_top.png",true))
    @tileset.push(Image.new(window,"artwork/level/dirt_top_left.png",true))
    @tileset.push(Image.new(window,"artwork/level/dirt_top_mid.png",true))
    @tileset.push(Image.new(window,"artwork/level/dirt_top_right.png",true))
    @tileset.push(Image.new(window,"artwork/level/dirt_bttm.png",true))
    @tileset.push(Image.new(window,"artwork/level/dirt_bttm_left.png",true))
    @tileset.push(Image.new(window,"artwork/level/dirt_bttm_mid.png",true))
    @tileset.push(Image.new(window,"artwork/level/dirt_bttm_right.png",true))
    #Brick type changes depending on theme...
    if type=="castle"
      @tileset.push(Image.new(window,"artwork/level/brick_castle.png",true))
    else
      @tileset.push(Image.new(window,"artwork/level/brick.png",true))
    end
    @tileset.push(Image.load_tiles(window,"artwork/level/item_block.png",92,92,true)[0])
    @tileset.push(Image.new(window,"artwork/level/pipe_topL.png",true))
    @tileset.push(Image.new(window,"artwork/level/pipe_topR.png",true))
    @tileset.push(Image.new(window,"artwork/level/pipe_midL.png",true))
    @tileset.push(Image.new(window,"artwork/level/pipe_midR.png",true))
    @tileset.push(Image.new(window,"artwork/level/pipe_btmL.png",true))
    @tileset.push(Image.new(window,"artwork/level/pipe_btmR.png",true))
    @tileset.push(Image.new(window,"artwork/level/passable_filler.png",true))
    @tileset.push(Image.new(window,"artwork/level/passable_left.png",true))
    @tileset.push(Image.new(window,"artwork/level/passable_right.png",true))
    @tileset.push(Image.new(window,"artwork/level/passable_top.png",true))
    @tileset.push(Image.new(window,"artwork/level/passable_top_left.png",true))
    @tileset.push(Image.new(window,"artwork/level/passable_top_right.png",true))
    @tileset.push(Image.new(window,"artwork/level/passable_bottom.png",true))
    @tileset.push(Image.new(window,"artwork/level/passable_bottom_left.png",true))
    @tileset.push(Image.new(window,"artwork/level/passable_bottom_right.png",true))
    @tileset.push(Image.new(window,"artwork/level/passable_caged.png",true))
    @tileset.push(Image.new(window,"artwork/level/passable_support.png",true))
    @tileset.push(Image.new(window,"artwork/level/passable_single.png",true))
    @tileset.push(Image.new(window,"artwork/level/stone_left.png",true))
    @tileset.push(Image.new(window,"artwork/level/stone_left_damaged.png",true))
    @tileset.push(Image.new(window,"artwork/level/stone_right.png",true))
    @tileset.push(Image.new(window,"artwork/level/stone_right_damaged.png",true))
    @tileset.push(Image.new(window,"artwork/level/wood_indoor.png",true))
    @tileset.push(Image.new(window,"artwork/level/wood_indoor_top.png",true))
    @tileset.push(Image.new(window,"artwork/level/wood_indoor_top_right.png",true))
    @tileset.push(Image.new(window,"artwork/level/wood_indoor_top_left.png",true))
    @tileset.push(Image.new(window,"artwork/level/wood_indoor_pedestial_top.png",true))
    @tileset.push(Image.new(window,"artwork/level/wood_indoor_pedestial_base.png",true))
    @tileset.push(Image.new(window,"artwork/level/pillar_castle.png",true))
    @tileset.push(Image.new(window,"artwork/level/torch.png",true))
    @tileset.push(Image.new(window,"artwork/level/help_block.png",true))
    @tileset.push(Image.new(window,"artwork/level/hard_block.png",true))
    @tileset.push(Image.new(window,"artwork/level/invisible_block.png",true))
    @tileset.push(Image.new(window,"artwork/zblank.png",true))
    
    #ADDITIONAL level objects
    @coins       = []
    @purchases   = ["flashlight_item", "health_item", "clock_item", "tinman_item"]
    if @window.camera_y!=-2000 #Make these items only avail when unused...
      @purchases.push("heart_double")  if @window.character.level_super == 0
      @purchases.push("zorro_item")    if @window.character.zorro_bat   == false
      @purchases.push("upgrade_jump")  if @window.character.level_jump   < 5
      @purchases.push("upgrade_speed") if @window.character.level_speed  < 5
      @purchases.push("upgrade_fly")   if @window.character.level_cape   < 5
      @purchases.push("upgrade_ax")    if @window.character.level_axes   < 5
    end
    @shop_items  = []
    @item_blocks = []
    @spawners    = []
    @torches     = []
    
    #PARTICLE EFFECTS
    @particles = []
    @particle_rate = 0
    @block_hit = false
    @bh_x = @bh_y = 0
    
    #AUDIO
    @snd_break = Sample.new(@window, "audio/break_block.wav")
    @snd_item  = Sample.new(@window, "audio/item_appear.wav")
    @snd_trspt = Sample.new(@window, "audio/transport.wav")
    @snd_achv  = Sample.new(@window, "audio/achieved.wav")
    @snd_stlev = Sample.new(@window, "audio/intro_level.wav")
    @snd_expls = Sample.new(@window, "audio/explosion.wav")
      
    #Read file's lines to pick up level information
    @lines = File.readlines(directory).map { |line| line.chomp }
    
    #MESSAGE BOX object!
    @message = MessageBox.new(@window,"levels/#{level}/hint.msg") if type!="dr_marcoux"
    @message = MessageBox.new(@window,"levels/shop.msg") if type=="dr_marcoux"
    @msg_ACT = false
    @msg_ACT = true if type=="dr_marcoux"
    
    #PREVIEW of level...
    if type!="dr_marcoux"
      genres = File.readlines("levels/levels.genre").map { |line| line.chomp }
      genre  = genres[@window.LEVEL_NUMBER-1].downcase
      if File.exist?("artwork/menu/level_themes/previews/#{genre}_#{hour}.png")
        @screenshot = Image.new(@window, "artwork/menu/level_themes/previews/#{genre}_#{hour}.png")
      else
        @screenshot = Image.new(@window, "artwork/zblank.png")
      end
    end
    
    #LEVEL selection variables...
    @started    = false
    @zoom_size  = 1.0
    @zoom_color = Color.new(0xffffffff)
    @zoom_angle = 0
    @zoom_blast = Image.new(window,"artwork/level/hour_washer.png",true)
    @zoom_dir   = :smaller
      
    #Store the level's height based on how many lines the file.
    @height = @lines.size
      
    #Store the level's width based on how many characters across the document (top line only)
    @width = @lines[0].size
      
    #Creating a 2D array for both the height and width
    @tiles = Array.new(@width) do |x|
      Array.new(@height) do |y|
        #Case for creating objects with assigned characters...
        case @lines[y][x, 1]
        when 'W'
          @water_level = (y * tile_size) + (tile_size / 2)
          nil
        when 'U'
          @dirt_level = (y * tile_size) + (tile_size / 2)
          nil
        when 'C'
          @castle_entry.push(Image.new(window,"artwork/level/castle.png",true)) # Actual image objects assigned...
          @castle_entry.push(Image.new(window,"artwork/level/castle_door.png",true))
          @castle_entry.push(Image.new(window,"artwork/level/door_frame.png",true)) if type!="obstacle"
          @entry_coords = [x * tile_size, (y * tile_size) + tile_size] # X and Y values pushed...
          nil
        when 'B', 'V'
          Objects::Brick
        when 'H'
          Objects::HardBlock
        when 'b'
          @item_blocks.push(SpecialTile.new(@window, (x * tile_size) + (tile_size / 2), (y * tile_size) + (tile_size / 2), "item_block", :special))
          Objects::Brick
        when 'g'
          @item_blocks.push(SpecialTile.new(@window, (x * tile_size) + (tile_size / 2), (y * tile_size) + (tile_size / 2), "item_block", false))
          Objects::Brick
        when 'v' #VINE!
          @item_blocks.push(SpecialTile.new(@window, (x * tile_size) + (tile_size / 2), (y * tile_size) + (tile_size / 2), "item_block", :vine))
          Objects::Brick
        when 'I' #INFERNO (Fire Anthony)!
          @item_blocks.push(SpecialTile.new(@window, (x * tile_size) + (tile_size / 2), (y * tile_size) + (tile_size / 2), "fire_block", :fire))
          Objects::Invisible
        when '('
          Objects::GrassLeft
        when 'M'
          Objects::GrassMid
        when 'm'
          if @lines[y+1][x,1]=='.'
            Objects::GrassSingleFloat 
          else
            Objects::GrassSingle
          end
        when ')'
          Objects::GrassRight
        when '['
          Objects::DirtLeft
        when 'D'
          Objects::DirtBase
        when 'd'
          Objects::DirtMiddle
        when ']'
          Objects::DirtRight
        when '~'
          Objects::DirtTop
        when '{'
          Objects::DirtTopLeft
        when 'u'
          Objects::DirtTopMiddle
        when '}'
          Objects::DirtTopRight
        when '"'
          Objects::DirtBottom
        when '`'
          Objects::DirtBottomLeft
        when '@'
          Objects::DirtBottomMiddle
        when '\''
          Objects::DirtBottomRight
        when '-'
          Objects::PipeTopLeft
        when '/'
          if type=="dr_marcoux"
            Objects::IndoorTopLeft
          else
            Objects::PipeTopLeft
          end
        when '='
          Objects::PipeTopRight
        when '|'
          Objects::PipeMidLeft
        when ':'
          Objects::PipeMidRight
        when '_', '^'
          Objects::PipeBtmLeft
        when '+'
          Objects::PipeBtmRight
        when ';'
          if type=="dr_marcoux"
            Objects::IndoorPedestialBase
          else
            Objects::PassableFiller
          end
        when 'l'
          Objects::PassableLeft
        when 'i'
          Objects::PassableRight
        when 'P'
          if type=="dr_marcoux"
            Objects::IndoorPedestial
          else
            Objects::PassableTop
          end
        when 'q'
          Objects::PassableTopLeft
        when 'p'
          Objects::PassableTopRight
        when '*'
          Objects::PassableBottom
        when 'L'
          Objects::PassableBottomLeft
        when 'R'
          Objects::PassableBottomRight
        when 'O'
          if @lines[y][x+1,1]=='O' && @lines[y][x-1,1]=='O'
            Objects::PassableCaged
          else
            Objects::PassableSingle
          end
        when 'S'
          Objects::StoneLeft
        when '5'
          Objects::StoneLeftDamaged
        when 's'
          Objects::StoneRight
        when '#'
          Objects::StoneRightDamaged
        when '\\'
          Objects::IndoorTopRight
        when 'o'
          if type=="dr_marcoux"
            Objects::IndoorTop
          elsif type=="castle"
            Objects::PillarCastle
          else
            Objects::PassableSupport
          end
        when 'w'
          Objects::IndoorBase
        when '&'
          Objects::HelpBlock
        when 'T'
          @torches.push(Fireball.new(@window, (x * tile_size) + (tile_size / 2), (y * tile_size) + 5))
          Objects::TorchHolder
        when 't' #Torch with no fire...
          @torches.push(Fireball.new(@window, (x * tile_size) + (tile_size / 2), (y * tile_size) + 5, true, nil, 0, 0, true))
          Objects::TorchHolder
        when '$'
          @coins.push(ItemObject.new(@window, (x * tile_size) + (tile_size / 2), (y * tile_size) + (tile_size / 2), "coin"))
          nil
        when 'h'
          @coins.push(ItemObject.new(@window, (x * tile_size) + (tile_size / 2), (y * tile_size) + (tile_size / 2), "heart_pickup", 0))
          nil
        when 'c'
          @coins.push(ItemObject.new(@window, (x * tile_size) + (tile_size / 2), (y * tile_size) + (tile_size / 2), "clock_pickup", 0))
          nil
        when 'F'
          @coins.push(ItemObject.new(@window, (x * tile_size) + (tile_size / 2), (y * tile_size) + (tile_size / 2), "fast_clock", 0))
          nil
        when 'f'
          @coins.push(ItemObject.new(@window, (x * tile_size) + (tile_size / 2), (y * tile_size) + (tile_size / 2), "flashlight_pickup", 0))
          nil
        when 'r'
          @coins.push(ItemObject.new(@window, (x * tile_size) + (tile_size / 2), (y * tile_size) + (tile_size / 2), "ruby", 0))
          nil
        when 'e'
          @coins.push(ItemObject.new(@window, (x * tile_size) + (tile_size / 2), (y * tile_size) + (tile_size / 2), "emerald", 0))
          nil
        when 'a'
          @coins.push(ItemObject.new(@window, (x * tile_size) + (tile_size / 2), (y * tile_size) + (tile_size / 2), "sapphire", 0))
          nil
        when '%' #SHOP ITEMS!!!
          random = rand(@purchases.size)
          @shop_items.push(PurchaseItem.new(@window, (x * tile_size) + (tile_size / 2), (y * tile_size) + (tile_size / 2), @purchases[random]))
          @purchases.delete_at(random)
          nil
        when '?'
          @item_blocks.push(SpecialTile.new(@window, (x * tile_size) + (tile_size / 2), (y * tile_size) + (tile_size / 2), "item_block"))
          Objects::Invisible
        when ','
          @item_blocks.push(SpecialTile.new(@window, (x * tile_size) + (tile_size / 2), (y * tile_size) + (tile_size / 2), "item_block", false))
          Objects::InvisibleBlock
        when 'x'
          if (y * tile_size) < @water_level
            if @type!="castle"
              @spawners.push(Spawner.new((x * tile_size) + (tile_size / 2), (y * tile_size) + (tile_size / 2), "goomba"))
            else
              @spawners.push(Spawner.new((x * tile_size) + (tile_size / 2), (y * tile_size) + (tile_size / 2), "boo"))
            end
          else
            @spawners.push(Spawner.new((x * tile_size) + (tile_size / 2), (y * tile_size) + (tile_size / 2), "fish"))
          end
          nil
        when 'k'
          @spawners.push(Spawner.new((x * tile_size) + (tile_size / 2), (y * tile_size) + (tile_size / 2), "koopa"))
          nil
        when 'K'
          @spawners.push(Spawner.new((x * tile_size) + (tile_size / 2), (y * tile_size) + (tile_size / 2), "red_koopa"))
          nil
        when 'X'
          @spawners.push(Spawner.new((x * tile_size) + (tile_size / 2), (y * tile_size) + (tile_size / 2), "blue_koopa"))
          nil
        when 'Q'
          @spawners.push(Spawner.new((x * tile_size) + (tile_size / 2), (y * tile_size) + (tile_size / 2), "blue_koopa", true))
          nil
        when 'y'
          if @type=="obstacle"
            @spawners.push(Spawner.new((x * tile_size) + (tile_size / 2), (y * tile_size) + (tile_size / 2), "ax_brotha"))
          else
            @spawners.push(Spawner.new((x * tile_size) + tile_size, (y * tile_size) + tile_size, "thwomp"))
          end
          nil
        when 'z' #MOON-LIGHTERS ONLY
          if @type!="castle"
            @spawners.push(Spawner.new((x * tile_size) + (tile_size / 2), (y * tile_size) + (tile_size / 2), "goomba_mystery")) if @window.late_night?
          else
            @spawners.push(Spawner.new((x * tile_size) + (tile_size / 2), (y * tile_size) + (tile_size / 2), "fortress_monster"))
          end
          nil
        when '>'
          @start_x = (x * tile_size) - 8 # X of GRID and placed in MIDDLE
          @start_y = (y * tile_size) - 8 # Y of GRID and placed in MIDDLE
          @off_grd = true if @lines[y+1][x,1]=='.'
          nil
        when '<'
          @shopping = true
          @drmarc_x = x * tile_size # X of GRID and placed in MIDDLE
          @drmarc_y = (y * tile_size) + @tile_size # Y of GRID and placed in MIDDLE
          nil
        when '1'
          @return_x = (x * tile_size) - 8 # X of GRID and placed in MIDDLE
          @return_y = (y * tile_size) - 10 # Y of GRID and placed in MIDDLE
          nil
        when '2'
          @secret_x = (x * tile_size) - 8 # X of GRID and placed in MIDDLE
          @secret_y = (y * tile_size) - 10 # Y of GRID and placed in MIDDLE
          nil
        when 'E'
          @finish_x = (x * tile_size) - 8 # X of GRID and placed in MIDDLE
          @finish_y = (y * tile_size) - 8 # Y of GRID and placed in MIDDLE
          nil
        when '!'
          @danger_x = (x * tile_size) - 8 # X of GRID and placed in MIDDLE
          @danger_y = (y * tile_size) - 8 # Y of GRID and placed in MIDDLE
          nil
        else
          nil
          #"nil" means empty space; no collision at all!
        end
      end
    end
    end #--- END file-existance
  end

  def update(background=nil, character=nil, sx=0, sy=0, ssx=0, ssy=0)
  	#Adjust object color tint based on hour...
    @color = 0xffbbbcff if background.hour != "day"
    @color = 0xffffffff if background.hour == "day"
    
    #Adjust inventory tint
    @inv_color = 0xffccc0cc if background.hour != "day"
    @inv_color = 0xffffffff if background.hour == "day"
    
    #MAKE things really, really dark when it is an underground course...
    if @type=="underground"
      @color = 0xffaa8888
      @inv_color = 0xffcc9988
    end
    
    #DESTROY particles and interchangeable-blocks
    @particles.reject! { |particle| particle.out==true || (not on_screen?(particle.x,particle.y,sx,sy,ssx,ssy))}
    @item_blocks.reject! { |item| @tiles[item.x / @tile_size][item.y / @tile_size] = Objects::ItemBlock if item.dead }
    
    #UPDATE item blocks/coins
    if @item_blocks.size>0
      @item_blocks.each do |item|
        if item.timer==4
    	    @coins.push(ItemObject.new(@window, item.x, item.y - @tile_size, item.item,
    	                               character.health, character.direction, character.tinman, character.zorro_bat))
    	    @snd_item.play
        end
      end
    end
    
    #UPDATE torches and water...
    @torches.each { |torch| torch.update if on_screen?(torch.x-138,torch.y-138,sx,sy,ssx,ssy,184) || torch.out==true } if @torches.size>0
    @water_wave+=2 ; @water_wave%=@tile_size*2
    @water_tide-=0.25 if @tide==0 ; @water_tide+=0.25 if @tide==1
    @tide = 1 if @water_tide < (-@tile_size/14)
    @tide = 0 if @water_tide > ( @tile_size/14)
    
    #MOVING items...
    @coins.each do |coin|
      if not coin.type=~/coin|heart|clock/
        if coin.y - 32 < @height * @tile_size
          coin.update(solid?(coin.x+28,coin.y),solid?(coin.x-28,coin.y)) if not coin.type=~/ruby|emerald|sapphire|flashlight|fire/
        else
      	  @coins.delete(coin)
        end
        if on_screen?(coin.x,coin.y,sx,sy,ssx,ssy,360)
          @particles.push(Particle.new(@window, coin.x + 25 - rand(50.0), coin.y - 25 + rand(50.0), 0, "fairy_dust")) if coin.type=~/tinman|zorro/
          @particles.push(Particle.new(@window, coin.x + 35 - rand(70.0), coin.y - 30 + rand(70.0), 0, "fairy_dust")) if coin.type=~/ruby|emerald|sapphire|flashlight|fire/ && @particle_rate==0
        end
      
        #DELETE tinman item if off-screen...
        @coins.delete(coin) if coin.type=~/tinman|zorro/ && (not on_screen?(coin.x,coin.y,sx,sy,ssx,ssy,360))
      end
    end
    
    #SHOP items...
    if @shop_items.size>0
      @shop_items.each do |shop|
        @particles.push(Particle.new(@window, shop.x + 35 - rand(70.0), shop.y - 30 + rand(70.0), 0, "fairy_dust")) if @particle_rate<2 && shop.bought==false
        shop.update(character) if character.vel_y<-16 && shop.bought==false
        @shop_items.delete(shop) if shop.bought?
      end
    end
    
    #FOR slower particle-creating rates
    @particle_rate += 1 if @particle_rate<6
    @particle_rate  = 0 if @particle_rate>=6
    @earthquake    -= 1 if @earthquake > 0
    
    #DOOR interaction...
    door_interaction if @entry_coords[1] > 0
    
    #RE-INITIALIZE hit (prevents 2-block hits in one jump)
    @block_hit = false if @earthquake<4
  end
  
  #ADD inventory
  def add_inventory(type="coin",x=0,y=0,dir="right")
    @coins.push(ItemObject.new(@window, x, y, type, 0, dir))
  end
    
  #Destroy or interact with object... such as typical Mario breaking bricks!
  def remove_tile(x,y,pow=0)
    #EXACT position of the tile using character's position info!
  	h = (x / 92).to_i * 92
  	v = (y / 92).to_i * 92
  	volume = -(@window.character.vel_y/20)+0.1
  	volume = 0.6 if pow!=0
  	pitch = 0.8+rand(0.3) #RANDOM pitch
  	
  	#Check if castle theme is enabled...
  	if @type == "castle"
  	  particle_theme = "_castle"
  	else
  	  particle_theme = ""
  	end
  	
    if @tiles[h / @tile_size][v / @tile_size]==Objects::Brick && (@window.character.vel_y < -@window.character.strength || pow.abs>12) && @block_hit==false
    	#If the object is destroyable and character's jump is powerful enough
       	#ANIMATE
       	@particles.push(Particle.new(@window, h+23, v+11, -4, "brick" + particle_theme))
       	@particles.push(Particle.new(@window, h+69, v+11, 5, "brick" + particle_theme))
      
       	@particles.push(Particle.new(@window, h+11, v+34, -5, "brick_small" + particle_theme))
       	@particles.push(Particle.new(@window, h+46, v+34, 3, "brick" + particle_theme))
       	@particles.push(Particle.new(@window, h+81, v+34, 5, "brick_small" + particle_theme))
      
       	@particles.push(Particle.new(@window, h+23, v+57, -5, "brick" + particle_theme))
       	@particles.push(Particle.new(@window, h+69, v+57, 4, "brick" + particle_theme))
     
       	@particles.push(Particle.new(@window, h+11, v+80, -5, "brick_small" + particle_theme))
       	@particles.push(Particle.new(@window, h+46, v+80, -3, "brick" + particle_theme))
        @particles.push(Particle.new(@window, h+81, v+80, 5, "brick_small" + particle_theme))
        shake(12)
        
        if @block_hit == false
          #Set this to nil, so that the space becomes free
          if @lines[v / @tile_size][h / @tile_size,1]=='B'
            #PREVENT multi-block interaction...
            @block_hit = true
            @bh_x, @bh_y = h/@tile_size, v/@tile_size
        	  @tiles[h / @tile_size][v / @tile_size] = nil
          end
          
          #INFINITE BRICK (never gets destroyed [disguise])
          if @lines[v / @tile_size][h / @tile_size,1]=='V'
            @block_hit = true
            @snd_item.play(0.5,0.5)
            pitch = 0.8
          end
        
          #Set this to an Item Block (hidden block in brick)
          if @lines[v / @tile_size][h / @tile_size,1]=~/b|v/
            @block_hit = true
            @bh_x, @bh_y = h/@tile_size, v/@tile_size
        	  @lines[v / @tile_size][h / @tile_size,1]='?'
        	  @tiles[h / @tile_size][v / @tile_size] = Objects::Invisible
          end
        
          #Set this to an Invisible Item Block (hidden inside brick)
          if @lines[v / @tile_size][h / @tile_size,1]=='g'
            @block_hit = true
            @bh_x, @bh_y = h/@tile_size, v/@tile_size
            @lines[v / @tile_size][h / @tile_size,1]='?'
            @tiles[h / @tile_size][v / @tile_size] = Objects::InvisibleBlock
          end
        end
        
        #PLAY sound effect
        @snd_break.play(volume,pitch)
    elsif @lines[v / @tile_size][h / @tile_size,1] == '?' || @tiles[h / @tile_size][v / @tile_size]==Objects::InvisibleBlock || @lines[v / @tile_size][h / @tile_size,1] == 'I'
    	@item_blocks.each { |i| (i.destroyed=true ; shake(9) ; @bh_x, @bh_y = h/@tile_size, v/@tile_size ; @block_hit=true) if distance(i.x,i.y,x,y)<80 && @block_hit==false }
    elsif @tiles[h / @tile_size][v / @tile_size]==Objects::HelpBlock
      if @block_hit == false
        if @msg_ACT == false #FIX THIS BEFORE ANYTHING!!!!
          @msg_ACT = true
          @snd_item.play(0.7,1.75)
          shake(5)
        else
          @msg_ACT = false
        end
        @block_hit = true
        @bh_x, @bh_y = h/@tile_size, v/@tile_size
      end
    end
  end
  
  #ENEMIES jumped by blocks 
  def block_hit?(x,y)
    return destroying?(x,y) if @block_hit==true# && distance(h+(@tile_size/2),v,x,y)<(@tile_size*1.5)
  end
  
  #Interact with pipe tiles...
  def pipe?(x,y)
    h = (x / 92).to_i * 92
  	v = (y / 92).to_i * 92
  	v=0 if v<0 #Prevents checking outside level error...
    if (@lines[v / @tile_size][h / @tile_size,1]=='-') || (@lines[v / @tile_size][h / @tile_size,1]=='^')
    	return true
    else
    	return false
    end
  end
  
  #Interact with torches...
  def light_torch(x,y)
    h = (x / 92).to_i * 92
    v = ((y+20) / 92).to_i * 92
    if @lines[v / @tile_size][h / @tile_size,1]=='T' || @lines[v / @tile_size][h / @tile_size,1]=='t'
      @torches.each { |torch| torch.light_up if torch.x>=x-@tile_size && torch.x<=x+@tile_size && torch.y>=y-20 && torch.y<=y+@tile_size+23 }
      return true
    else
      return false
    end
  end
  
  #Interact with entry triggers...
  def door_interaction
    if @type=="obstacle"
      if @window.character.x > @entry_coords[0] - 400 &&
        @window.character.x < @entry_coords[0] + 570 && @auto_enter == false
        door("open")
      elsif (@window.character.x > @entry_coords[0] + 530 || @window.character.x < @entry_coords[0] - 501) && @auto_enter == true || @window.character.x < @entry_coords[0] - 399
        door("close")
      end
    
      #MAKE player enter...
      if @window.character.x > @entry_coords[0] + 300 && @window.character.x < @entry_coords[0] + 520 &&
        @window.character.y > @entry_coords[1] - 300 && @entry_opener < -400
        @auto_enter = true
      end
    else
      #PLAYER enters door to secret room...
      if @window.character.x > @entry_coords[0] + 35 && @window.character.x < @entry_coords[0] + 127 &&
        @window.character.y > @entry_coords[1] - 64 && @window.character.y < @entry_coords[1] + @tile_size && @hidden == false
        if @alpha >= 255
          @snd_trspt.play(0.6)
          @window.character.direction = "right"
          @window.character.place(@secret_x + 161, @secret_y + 2)
          @window.character.vel_x = 11
          10.times { @particles.push(Particle.new(@window, @secret_x - rand(150.0) + 150, @secret_y + rand(300.0) - 200, 4-rand(8), "fairy_dust")) }
        end
      end
      
      #ON the way back out...
      if @window.character.x > @secret_x + 55 && @window.character.x < @secret_x + 147 &&
        @window.character.y > @secret_y - 64 &&  @window.character.y < @secret_y + @tile_size && @hidden == false
        if @alpha >= 255
          @snd_trspt.play(0.6)
          @window.character.direction = "right"
          @window.character.place(@entry_coords[0] + 161, @entry_coords[1] + 84)
          @window.character.vel_x = 11
          10.times { @particles.push(Particle.new(@window, @entry_coords[0] - rand(150.0) + 150, @entry_coords[1] + rand(300.0) - 100, 4-rand(8), "fairy_dust")) }
        end
      end
    end
  end
  
  def door(action = "open")
    if action == "open"
      if @entry_opener > -488
        @entry_opener -= 6 + @entry_opener.abs/32
      else
        @entry_opener = -488
      end
    elsif action == "close"
      if @entry_opener < 0
        @entry_opener += 48.8
        if @entry_opener > -1
          @snd_break.play(1.0, 0.75)
          shake(18)
        end
      else
        @entry_opener = 0
      end
    end
  end
  
  def shake(n = 10)
    @earthquake = n
  end
  
  #ON-SCREEN algorithm...
  def on_screen?(x,y,sx,sy,ssx,ssy,offset=0)
  	(sx-x)<(@tile_size+offset) && (sx-x)>-ssx-offset && (sy-y)<(@tile_size+offset) && (sy-y)>-ssy-offset
  end
    
  #Draw all of the tiles and other miscellaneous objects...
  def draw(sx, sy, ssx, ssy)
    #SEARCH animation
    @fy += 1    if @fd == true
    @fy -= 1    if @fd == false
    @fd = false if @fy >  10
    @fd = true  if @fy < -10
    
    #STANDARD objects
    for y in sy.to_i / @tile_size..(sy.to_i / @tile_size) + (ssy / @tile_size) + 1
      for x in sx.to_i / @tile_size..(sx.to_i / @tile_size) + (ssx / @tile_size) + 1
        x = @width  - 1 if x >= @width  - 1
        y = @height - 1 if y >= @height - 1
        tile = @tiles[x][y]
        if tile
          
          #DRAW standard tiles...
          if tile != Objects::InvisibleBlock
            @tileset[tile].draw((x * @tile_size) - @tile_offset - sx, (y * @tile_size) - @tile_offset - sy, 0, 1, 1, @color) #Draw the tile plainly...
          else
            @tileset[tile].draw((x * @tile_size) - @tile_offset - sx, (y * @tile_size) - @tile_offset - sy, 0, 1, 1, @color, :additive) #Add effect...
          end
          
          #DRAW searching icons
          if searchable?(x,y) && @window.character.searcher && @window.character.pipe_y==0
            ox=oy=@tile_size/2 ; ay=1
            ox=@tile_size if @lines[y][x,1]=='-' || @lines[y][x,1]=='^'
            ay,oy=-1,-144 if @lines[y][x,1]=='^'
            @search.draw_rot((x * @tile_size) - @tile_offset - sx + ox, (y * @tile_size) - @tile_offset - sy - oy + @fy, 0, 0, 0.5, 0.5, 1, ay)
          end
        end
      end
    end

    #START and END signs
    if @type != "underground" && @off_grd == false
      @start.draw_rot(@start_x - 48 - sx, @start_y + 108 - sy, 2, 0, 0.5, 1.0, 1, 1, @color) if not @type=~/castle|marcoux/
    end
    @end.draw_rot(@finish_x - 48 - sx, @finish_y + 108 - sy, 2, 0, 0.5, 1.0, 1, 1, @color)
    
    #OTHER signs
    @danger.draw_rot(@danger_x - 48 - sx, @danger_y + 108 - sy, -1, 0, 0.5, 1.0, 1, 1, @color)
    
    #WATER/DIRT image loops
    if (sy+ssy) > (@water_level-@tile_size) || (sy+ssy) > (@dirt_level-@tile_size)
      for x in sx.to_i/(@tile_size*2)..(sx.to_i/(@tile_size*2))+((ssx/(@tile_size*2))+2)
        #WATER
        if (sy+ssy) > (@water_level-@tile_size)
          for y in (@water_level/184)..(sy.to_i/(@tile_size*2))+((ssy/(@tile_size*2))+1)
            if y==(@water_level/184)
              @water_level = y * (@tile_size*2)
              @water_top.draw((x * (@tile_size*2)) - @tile_offset - @water_wave.to_i - sx, (y * (@tile_size*2)) - @tile_offset + @water_tide.to_i + 6 - sy, 2, 1, 1, 0x99ffffff)
              @water_top.draw((x * (@tile_size*2)) - @tile_offset - (@tile_size*2) + @water_wave.to_i - sx, (y * (@tile_size*2)) - @tile_offset - @water_tide.to_i - sy, -2, 1, 1, 0xc0ffffff)
            else
              @water_base.draw((x * (@tile_size*2)) - @tile_offset - @water_wave.to_i - sx, (y * (@tile_size*2)) - @tile_offset + @water_tide.to_i + 6 - sy, 2, 1, 1, 0x99ffffff)
              @water_base.draw((x * (@tile_size*2)) - @tile_offset - (@tile_size*2) + @water_wave.to_i - sx, (y * (@tile_size*2)) - @tile_offset - @water_tide.to_i - sy, -2, 1, 1, 0xc0ffffff)
            end
          end
        end
        #DIRT
        if (sy+ssy) > (@dirt_level-@tile_size)
          for y in (@dirt_level/184)..(sy.to_i/(@tile_size*2))+((ssy/(@tile_size*2))+1)
            if y==(@dirt_level/184)
              @dirt_level = y * (@tile_size*2)
              @dirt_top.draw((x * (@tile_size*2)) - @tile_offset - (@tile_size*2) - sx, (y * (@tile_size*2)) - @tile_offset - sy, -2, 1, 1, @color)
            else
              @dirt_base.draw((x * (@tile_size*2)) - @tile_offset - (@tile_size*2) - sx, (y * (@tile_size*2)) - @tile_offset - sy, -2, 1, 1, @color)
            end
          end
        end
      end
    end
    
    #INVENTORY OBJECTS
    @coins.each       { |coin| coin.draw(sx,sy,@inv_color) if on_screen?(coin.x-46,coin.y-46,sx,sy,ssx,ssy) || coin.type=~/vine/ }
    @item_blocks.each { |item| item.draw(sx,sy,@color) if on_screen?(item.x-46,item.y-46,sx,sy,ssx,ssy) }
    @shop_items.each  { |shop| shop.draw(sx,sy,ssx,ssy) }
    
    #DRAW castle entry background objects...
    if @entry_coords[1] > 0
      if @type=="obstacle"
        @castle_entry[2].draw(@entry_coords[0] + 275 - sx, @entry_coords[1] - 490 + @entry_opener - sy, -1)
        @castle_entry[1].draw_rot(@entry_coords[0] - sx, @entry_coords[1] - sy, -1, 0, 0.5, 1.0, 1, 1, @color)
        @castle_entry[0].draw(@entry_coords[0] + 275 - sx, @entry_coords[1] - 490 - sy, -2, 0.35, 1.1)
      else
        #VALIDATE secret activation...
        door_x, door_y = @entry_coords[0] + 12, @entry_coords[1] - 120
        
        #DON'T declare variables if torches are already lit...
        if @hidden==true
          lit_l  = false
          lit_r  = false
          @alpha = 0
          
          #CHECK each torch to see if they are lit...
          if on_screen?(door_x-46,door_y-46,sx,sy,ssx,ssy)
            @torches.each do |fire|
              lit_l=true if distance(door_x,door_y,fire.x,fire.y)<150 && (not fire.out)
              lit_r=true if distance(door_x+100,door_y,fire.x,fire.y)<150 && (not fire.out)
            end
          end
        end
        
        #ACTIVATE if both torches are lit!
        (@hidden = false ; @snd_achv.play) if lit_l==true && lit_r==true
        
        #SLOWLY fade the door in!!!
        if @hidden==false
          
          if @alpha < 255
            @alpha += 1.5
            @particles.push(Particle.new(@window, door_x - rand(150.0) + 150, door_y + rand(300.0), 4-rand(8), "fairy_dust"))
            @particles.push(Particle.new(@window, @secret_x - rand(150.0) + 150, @secret_y + rand(300.0) - 200, 4-rand(8), "fairy_dust"))
          end
          
          @alpha  = 255 if @alpha > 255
        end
        
        #DRAW if both torches are lit
        if @hidden==false
          @castle_entry[0].draw(door_x - sx, door_y - sy, -2, 0.2, 0.68, Color.new(@alpha.to_i,255,255,255))
          @castle_entry[0].draw(@secret_x + 20 - sx, @secret_y - 204 - sy, -2, 0.2, 0.68, Color.new(@alpha.to_i,255,255,255))
          #DOOR FRAMEs
          @castle_entry[3].draw(door_x - sx, door_y - sy, -1.9, 1, 1, Color.new(@alpha.to_i,255,255,255))
          @castle_entry[3].draw(@secret_x + 20 - sx, @secret_y - 204 - sy, -1.9, 1, 1, Color.new(@alpha.to_i,255,255,255))
        end
      end
    end
    
    #DRAW the particles
    @particles.each { |particle| particle.draw(sx, sy, @color) if on_screen?(particle.x,particle.y,sx,sy,ssx,ssy)}
    
    #DRAW torches...
    @torches.each {|torch| torch.draw(sx, sy) if on_screen?(torch.x-138,torch.y-138,sx,sy,ssx,ssy,184) || torch.out==true}
    
    #DRAW the message only when requested...
    @message.draw(ssx/2,ssy/2) if @msg_ACT == true
    
    #DRAW the doctor when shopping...
    if @shopping == true
      (@msg_ACT=true;@dr_t=100) if distance(@window.character.x,@window.character.y,@drmarc_x,@drmarc_y)<400 && @dr_t==1 && @window.character.vel_x>0
      @dr_t-=1 if @msg_ACT==false
      (@dr_t=30+rand(60) ; @dr_d=@dr_t/2) if @dr_t<1
      @dr_r  = Math.sin(milliseconds / 90.0)*((@dr_d-@dr_t).abs.to_f/20.0)
      @dr_i.draw_rot(@drmarc_x, @drmarc_y, 0, @dr_r, 0.5, 1.0)
    end
  end
  
  #DRAW the screenshot preview
  def preview(x=0,y=0)
    #ZOOM when LEVEL SELECTED to play...
    @zoom_dir=:smaller if @zoom_size>=1.0 ; @zoom_dir=:larger if @zoom_size<=0.9
    
    if @started == true
      #DRAW flash
      @zoom_blast.draw(0, 0, 99999999999, 4, 4, Color.new(@zoom_color.green/2,255,255,255), :additive)                      
      @zoom_size  *= 1.0375
      @zoom_angle -= @zoom_size.to_f/5.0
      #FADE OUT
      if @zoom_color.red > 0
        @snd_expls.play(0.4, 1.5) if @zoom_color.red == 254
        @snd_stlev.play(0.4, 1.7) if @zoom_color.red == 175
        @zoom_color.red-=1 ; @zoom_color.green-=1 ; @zoom_color.blue-=2 if @zoom_color.blue>1
      end
      #DRAW preview
      @screenshot.draw_rot(x, y, 10000000000, @zoom_angle, 0.5, 0.5, @zoom_size, @zoom_size, @zoom_color)
    else
      #RESET
      @zoom_size -= 0.005 - (((@zoom_size-0.95).abs)/12.0) if @zoom_dir == :smaller
      @zoom_size += 0.005 - (((@zoom_size-0.95).abs)/12.0) if @zoom_dir == :larger
      @zoom_color.red = 255 ; @zoom_color.green = 255 ; @zoom_color.blue = 255
      @zoom_angle     = 0
      @zoom_size      = 1.0 if @zoom_size > 1.0
      
      #DRAW preview
      @screenshot.draw_rot(x, y + ((@zoom_size-0.95)*300), 1000000, 0)
      
      #DRAW reflection
      @screenshot.draw_as_quad(x - 320, y + 700 - ((@zoom_size-0.95)*300), 0x00000000, x + 320, y + 700 - ((@zoom_size-0.95)*300), 0x00000000,
                               x - 320, y + 290 - ((@zoom_size-0.95)*300), Color.new((150+(@zoom_size-0.9)*700).to_i,240,240,255),
                               x + 320, y + 290 - ((@zoom_size-0.95)*300), Color.new((150+(@zoom_size-0.9)*700).to_i,240,240,255), 100001, :additive)
      @screenshot.draw_as_quad(x - 320, y + 700 - ((@zoom_size-0.95)*300), 0x00000000, x + 320, y + 700 - ((@zoom_size-0.95)*300), 0x00000000,
                               x - 320, y + 290 - ((@zoom_size-0.95)*300), Color.new((175+(@zoom_size-0.9)*700).to_i,100,100,100),
                               x + 320, y + 290 - ((@zoom_size-0.95)*300), Color.new((175+(@zoom_size-0.9)*700).to_i,100,100,100), 100001)
    end
  end
  
  #RETURN bouncing y value to lock movement with other objects...
  def bounce_y
    if @started == false
      return ((@zoom_size-0.95)*300)
    else
      return 0
    end
  end
  
  #CHECK for destroying blocks
  def destroying?(x,y)
    x/@tile_size==@bh_x && y/@tile_size==@bh_y
  end
  
  #CHECK for interactivable objects
  def interactive?(x,y)
    if y < @height * @tile_size
      @lines[y / @tile_size][x / @tile_size,1]=='B' ||
      @lines[y / @tile_size][x / @tile_size,1]=='?' ||
      @lines[y / @tile_size][x / @tile_size,1]==',' ||
      @lines[y / @tile_size][x / @tile_size,1]=='b' ||
      @lines[y / @tile_size][x / @tile_size,1]=='g'
    end
  end
  
  #FOR item shopping
  def pedestial?(x,y)
    @tiles[x / @tile_size][y / @tile_size]==Objects::IndoorPedestialBase
  end
  
  #LAND themed objects?
  def shore?(x,y)
    @lines[y / @tile_size][x / @tile_size,1]=='M' ||
    @lines[y / @tile_size][x / @tile_size,1]=='~'
  end
  
  #CHECK for passable objects
  def passable?(x,y)
  	@tiles[x / @tile_size][y / @tile_size]==Objects::PassableTop ||
  	@tiles[x / @tile_size][y / @tile_size]==Objects::PassableTopLeft ||
  	@tiles[x / @tile_size][y / @tile_size]==Objects::PassableTopRight ||
    @tiles[x / @tile_size][y / @tile_size]==Objects::PassableCaged ||
    @tiles[x / @tile_size][y / @tile_size]==Objects::PassableSingle ||
  	@tiles[x / @tile_size][y / @tile_size]==Objects::IndoorPedestial
  end
  
  #CHECK for objects that have no collision
  def noncollidable?(x,y)
  	@tiles[x / @tile_size][y / @tile_size]==Objects::PassableFiller ||
  	@tiles[x / @tile_size][y / @tile_size]==Objects::PassableLeft ||
  	@tiles[x / @tile_size][y / @tile_size]==Objects::PassableRight ||
  	@tiles[x / @tile_size][y / @tile_size]==Objects::PassableBottom ||
  	@tiles[x / @tile_size][y / @tile_size]==Objects::PassableBottomLeft ||
    @tiles[x / @tile_size][y / @tile_size]==Objects::PassableBottomRight ||
    @tiles[x / @tile_size][y / @tile_size]==Objects::PassableSupport ||
  	@tiles[x / @tile_size][y / @tile_size]==Objects::IndoorPedestialBase ||
    @tiles[x / @tile_size][y / @tile_size]==Objects::PillarCastle ||
  	@tiles[x / @tile_size][y / @tile_size]==Objects::TorchHolder
  end
  
  #CHECK for objects to be searched
  def searchable?(x,y)
    @tiles[x][y]==Objects::InvisibleBlock ||
    @lines[y][x,1]=="-" ||
    @lines[y][x,1]=="^" ||
    (@tiles[x][y]==Objects::Brick && @lines[y][x,1]=~/b|v/)
  end

  def solid?(x=0, y=0, vy=0)
    #Check for level boundary edges
    return true if x < 0 || x > (@width * @tile_size) - 1
    
    #Makes the ceiling height unlimited (with the exception of castle level)...
    return false if y < 0 && x < (@width * @tile_size) && x > -1 && @type!="castle"
    
    #Castle ceiling
    return true if @type == "castle" && y < -184
    
    #Check for noncollidables
    return false if noncollidable?(x,y)
    
    #Check for passability
    if vy < 0 || y > ((y/@tile_size)*@tile_size) || passable?(x,y-1)
    	return false if passable?(x,y)
    end
    
    #Check for invisible blocks
    return false if @tiles[x / @tile_size][y / @tile_size]==Objects::InvisibleBlock && vy>=-8
    
    #Collision detection; checks by looking into the 2D array that stores the objects
    return true if @tiles[x / @tile_size][y / @tile_size]
  end
end