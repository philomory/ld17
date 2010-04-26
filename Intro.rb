module LD17
  class Intro
    def initialize
      @intro_audio = Gosu::Sample.new(MainWindow.instance,"media/intro.ogg")
      @rep_image = Gosu::Image.new(MainWindow.instance,"media/rep.png",false)
      @adm_image = Gosu::Image.new(MainWindow.instance,"media/adm.png",false)
      @playing = false
    end
    
    def update(*args)
      @start_time ||= Time.now
      @clip ||= @intro_audio.play
      done if Time.now - @start_time > 18.0
    end
    
    def done
      @clip.stop
      @clip = nil
      MainWindow.new_game
    end
    
    def draw
      if Time.now - @start_time < 14.5
        @rep_image.draw_rot(320,240,0,0)
      else
        @adm_image.draw_rot(320,240,0,0)
      end
    end
    
    def button_down(id)
      done
    end
    
    def button_up(id)
    end
    
  end
end