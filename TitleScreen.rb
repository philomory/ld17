module LD17
  class TitleScreen
    def initialize
      @image = Gosu::Image.new(MainWindow.instance,"media/guam.png",false)
      @samples = %w{8000_marines capsize farthest_west_us_territory guam_is_a_small_island
        my_fear part_of_our_nation seven_miles the_environment this_is_a_island uhh1 uhh2
      }.map {|name| Gosu::Sample.new(MainWindow.instance,"media/#{name}.ogg")}
      @timer = Time.now
      @delay = 10
    end
    
    def button_down(id)
      MainWindow.intro
    end
    
    def draw
      @image.draw(0,0,0)
    end
    
    def update(*args)
      if @sample
        if !@sample.playing?
          @sample = nil
          @timer = Time.now
        end
      else
        if Time.now - @timer > @delay
          if rand(3) == 1
            @sample = @samples[rand(@samples.size)].play
            @delay = 3
          end
          @timer = Time.now
        end
      end
    end
    
    def button_up(id)
    end
    
  end
end