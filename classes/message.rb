class MessageBox
  
  def initialize(window, filename="/directory/text_file.msg", font="Monaco")
    @window = window
    @frame  = Image.new(@window, "artwork/menu/message.png", false)
    @offset_x, @offset_y = @frame.width/2, @frame.height/2
    
    #CHECK if file exist...
    if File.exist?(filename)
      @text_lines = File.readlines(filename).map { |line| line.chomp }
    else
      @text_lines = ["<no messages>"]
    end
    
    #SET font
    @font_size = 32-(@text_lines.size/1.5).to_i
    @font      = Font.new(@window, font, @font_size.to_i)
  end
  
  def draw(x,y,ox=48,oy=48)
    #DRAW each line of text
    for i in 0..(@text_lines.size-1)
      @font.draw(@text_lines[i], x + ox - @offset_x, y + (@font_size*i) + oy - @offset_y, 1000)
    end
    
    #DRAW the TEXTBOX
    @frame.draw(x-@offset_x, y-@offset_y, 999)
  end
  
end