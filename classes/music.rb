class Music
  attr_reader :music, :theme
  def initialize(window, theme)
    @w, @theme = window, theme
    @music = Song.new(@w,"audio/music/#@theme.ogg")
  end

  def update
    if @music.playing?
    else
      @music.play
    end
  end

  def stop
    @music.stop
  end
end