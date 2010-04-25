require 'gosu'
require 'chipmunk_object'
require 'SVGReader'

module LD17
  class Win < Gosu::Window
    def initialize
      super(640,480,false)
      @body = CP::Body.new(0,0)
      @body.p = vec2(320,240)
      @verts = SVGReader.import_vertices("island.svg","island")#.map {|v| @body.world2local(v)}
      @font = Gosu::Font.new(self,Gosu::default_font_name,10)
      puts @verts
    end
    
    def button_down(id)
      close
    end
    
    def draw
      #draw_background
      draw_points
    end
    
    def draw_background
      c = 0x00000000
      self.draw_quad(0,0,c,640,0,c,0,480,c,640,480,c,0)
    end
    
    def draw_points
      @verts.each_with_index do |vert,index|
        x,y = vert.x, vert.y
        @font.draw(index.to_s,x,y,1)
      end
    end
  end
end

LD17::Win.new.show