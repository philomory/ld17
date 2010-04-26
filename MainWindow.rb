require 'gosu'

#require 'Constants'
#require 'Screen'
require 'Intro'
require 'Game'
require 'TitleScreen'

require 'FPSCounter'

module LD17
  class MainWindow < Gosu::Window

    attr_accessor :current_screen
    attr_reader :main_menu


    # I'm implimenting Singleton here myself rather than using the Singleton
    # module in the Ruby Standard Library, because the Ruby Standard Library
    # version doesn't behave quite the way I need it to. For one of the things
    # it does 'wrong', see http://www.ruby-forum.com/topic/179676
    private_class_method :new
    def self.instance
      unless @__instance__
        new
      end
      @__instance__
    end

    attr_reader :available_layers
    def initialize
      # More Singleton stuff.
      self.class.instance_variable_set(:@__instance__,self)
       
      super(640,480,false,16.666666666*4)
      self.caption = "Capsize - feat. Rep. Johnson and DJ Admiral"
      self.title
      @fps = FPSCounter.new
      @steps = 1
      setup_layers
    end
    
    def intro
      @current_screen = Intro.new
    end
    
    def restart
      title
    end
    
    def title
      @current_screen = TitleScreen.new
    end
    
    def update
      #play_intro unless @intro_played
      @fps.register_tick
      @current_screen.update(@steps,dt)
    end
    
    def play_intro
      @intro_audio.play
      @intro_played = true
    end
    def dt
      @dt ||= ((self.update_interval/1000)/@steps)
    end
    
    def setup_layers
      @available_layers = Array.new(32) {|i| 1 << i}
    end
    
    def new_game
      @game = Game.new
      @current_screen = @game
    end
    
    def draw
      # Because draw is utterly without side-effects (in terms of game state;
      # obviously it has the 'side effect' of placing an image on the screen),
      # there should be no risk in silently catching and discarding exceptions
      # during the call to draw. Of course, it's better during development to
      # have them around so that they point out bugs, but for the user it's
      # better to have a single munged frame than to have the whole app crash
      # just because I passed bad arguments to some draw function.
      #
      # In the future, though, I hope to throw some intelligent crash-logging
      # into the picture.
      @current_screen.draw # rescue nil
      #ImageManager.image('pointer').draw(self.mouse_x-6,self.mouse_y,ZOrder::Pointer)
      self.caption = "Capsize - feat. Rep. Johnson and DJ Admiral: #{@fps.fps} frames per second."
    end
    
    def button_down(id)
      @current_screen.button_down(id)
    end
    
    def button_up(id)
      @current_screen.button_up(id)
    end
    
    
    # MainWindow is a singleton. This allows me to call methods on MainWindow
    # that I really want to sent to MainWindow.instance, cutting out a lot of
    # useless verbosity. And it avoids ill-performing method_missing hacks.
    #
    # clip_to is handled sepearately because it takes a block and define_method
    # doesn't handle blocks correctly in Ruby 1.8.
    
    def MainWindow.clip_to(*args,&blck)
      MainWindow.instance.clip_to(*args,&blck)
    end
    
    (MainWindow.public_instance_methods - MainWindow.public_methods).each do |meth|
      (class << MainWindow; self; end).class_eval do
        define_method(meth) do |*args|
          MainWindow.instance.send(meth,*args)   
        end
      end   
    end
  end
end