require 'chipmunk_object'
require 'drawable_shape'

module LD17
  class Structure
    include CP::Object
    include DrawableShape
    
    def self.image
      Gosu::Image.new(MainWindow.instance,"media/structure.png",false)
    end
    
    attr_reader :body
    def initialize(p,mass,w,h)
      @image = Structure.image
      
      @vertices = [
        vec2(-w/2,-h/2),
        vec2( w/2,-h/2),
        vec2( w/2, h/2),
        vec2(-w/2, h/2)
      ]
      mass = w*h/6
      moment = CP.moment_for_poly(mass,@vertices,CP::ZERO_VEC_2)
      @body = CP::Body.new(mass,moment)
      @body.p = p
      @original_func = @body.struct.velocity_func
      @body.velocity_func = Proc.new do |body,gravity,damping,dt|
        body.update_velocity($gravity/10,damping,dt)
      end
      
      @shape = CP::Shape::Poly.new(@body,@vertices,CP::ZERO_VEC_2)
      @shape.e = 0.0; @shape.u = 1.0
      @shape.group = :structure
      @shape.collision_type = :structure
      @shape.instance_variable_set(:@obj,self)
      init_chipmunk_object(@body,@shape)
    end
    
    def draw
      x,y = @body.p.x, @body.p.y
      angle = (@body.angle-Math::PI/2).radians_to_gosu
      @image.draw_rot(x,y,ZOrder::Structure,angle)
      draw_shape
    end
    
    def hit?
      @hit
    end
    
    def reset_velocity_func
      @hit = true
      @body.struct.velocity_func = @original_func
      @body.instance_variable_set(:@body_velocity_lambda,nil)
      @body.send(:set_default_velocity_lambda)
      @body.reset_forces
      @body.v = CP::ZERO_VEC_2
    end
    
    def self.collision_funcs(game)
      game.add_collision_func(:structure,:island,:begin) do |structure,island|
        structure.instance_variable_get(:@obj).reset_velocity_func
        true
      end
    end
    
  end
end