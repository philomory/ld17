module LD17
  class Airplane
    include CP::Object
    
    def initialize(game,target_x,y,side)
      @game = game
      @side = side
      @body = CP::Body.new(10,CP::INFINITY)
      x = (side == :left) ? -10 : 650
      v = vec2(((side == :left) ? 50 : -50),0)
      @body.p = vec2(x,y)
      @body.velocity_func = Proc.new do |body,gravity,damping,dt|
        body.v = v
        body.update_position(dt)
      end
      
      @layer = MainWindow.available_layers.pop
      
      @shape = CP::Shape::Segment.new(@body,vec2(-5,0),vec2(5,0),1)
      @shape.group = :airplane
      @shape.layers = @layer
      @shape.collision_type = :airplane
      @shape.instance_variable_set(:@obj,self)
      
      @s_body = CP::StaticBody.new
      @slide = CP::Constraint::GrooveJoint.new(@s_body,@body,vec2(-10,y),vec2(650,y),vec2(0,0))
      
      @sensor1 = CP::StaticShape::Circle.new(@s_body,5,vec2(target_x,y))
      @sensor1.layers = @layer
      @sensor1.sensor = true
      @sensor1.collision_type = :sensor1
      
      @sensor2 = CP::StaticShape::Circle.new(@s_body,10,vec2(640-x,y))
      @sensor2.layers = @layer
      #@sensor2.sensor = true
      @sensor2.collision_type = :sensor2
      
      init_chipmunk_object(@body,@shape,@s_body,@slide,@sensor1,@sensor2)
    end
    
    def drop_payload
      @game.drop_payload(@body.p)
    end
    
    def draw
      x,y = @body.p.x, @body.p.y
      c = 0xFF000000
      MainWindow.draw_quad(x-3,y-3,c,x+3,y-3,c,x-3,y+3,c,x+3,y+3,c,10000)
    end
    
    def clean_up
      MainWindow.available_layers.push(@layer)
    end
    
    def self.collision_funcs(game)
      game.add_collision_func(:airplane,:sensor1,:begin) do |airplane,sensor|
        airplane.instance_variable_get(:@obj).drop_payload
      end
      game.add_collision_func(:airplane,:sensor2,:post) do |airplane,sensor|
        game.destroy(airplane.instance_variable_get(:@obj))
      end
    end
    
    
    
  end
end