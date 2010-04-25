require 'chipmunk_object'
require 'drawable_shape'

module LD17
  class Soldier
    include CP::Object
    include DrawableShape
    
    attr_writer :target_structure
    def initialize(game,p)
      @game = game
      w, h = 2, 6
      @vertices = [
        vec2(-w/2,-h/2),
        vec2( w/2,-h/2),
        vec2( w/2, h/2),
        vec2(-w/2, h/2)
      ]
      mass = 1.0
      @body = CP::Body.new(mass,CP::INFINITY)
      @body.p = p
      @original_func = @body.struct.velocity_func
      @body.velocity_func = Proc.new do |body,gravity,damping,dt|
        body.update_velocity($gravity/10,damping,dt)
      end
      
      #@control_body = CP::StaticBody.new
      
      @shape = CP::Shape::Poly.new(@body,@vertices,CP::ZERO_VEC_2)
      @shape.e = 0.0; @shape.u = 2.0
      @shape.group = :soldier
      @shape.collision_type = :soldier
      @shape.instance_variable_set(:@obj,self)
      
      #@wheel_body = CP::Body.new(mass,CP.moment_for_circle(mass,1,CP::ZERO_VEC_2))
      #@wheel_body.p = p
      #@wheel_body.p.y = p.y + h/2 - 0.95
      #@feet_wheel = CP::Shape::Circle.new(@wheel_body,1,CP::ZERO_VEC_2)
      #@feet_wheel.u = 1.0
      #@feet_wheel.group = :soldier
      #@feet_wheel.collision_type = :soldier
      #@feet_wheel.instance_variable_set(:@obj,self)
      #
      #@axel = CP::Constraint::PivotJoint.new(@body,@wheel_body,@wheel_body.local2world(@wheel_body.p))
      
      init_chipmunk_object(@body,@shape) #@control_body,@wheel_body,@feet_wheel,@axel)
    end
    
    def draw
      draw_shape
      #draw_control_body
      draw_target_point
    end
    
    def draw_target_point
      if @target_point
        x,y = @target_point.x, @target_point.y
        c = 0xFF00FF00
        MainWindow.draw_quad(x-1,y-1,c,x+1,y-1,c,x-1,y+1,c,x+1,y+1,c,100)
      end
    end
    
    def draw_control_body
      if @control_body
        v = @control_body.p
        x,y = v.x, v.y
        c = 0xFF00FF00
        MainWindow.draw_quad(x-1,y-1,c,x+1,y-1,c,x-1,y+1,c,x+1,y+1,c,100)
      end
    end
    
    def on_ground(arbiter)
      @normal = arbiter.normal
      unless @hit
        @hit = true
        @body.struct.velocity_func = @original_func
        @body.instance_variable_set(:@body_velocity_lambda,nil)
        @body.send(:set_default_velocity_lambda)
        @body.reset_forces
        @body.v = CP::ZERO_VEC_2
        @game.pick_target_for_soldier(self)
      end
    end
    
    def reached_structure(structure)
      if structure == @target_structure
        @body.v.x = 0
        @game.pick_target_for_soldier(self)
      end
    end
    
    def update_target
      return unless @hit
      if rand(30) == 0
        @game.pick_target_for_soldier(self)
      elsif @target_structure
        @target_point = @target_structure.body.p
      end
      if @normal.length > 0
        @shape.surface_v = @normal.perp * 400 * target_direction
        if @body.p.near?(@target_point,3.0)
          @body.v.x = [[-2,@body.v.x].max,2].min
        elsif @body.p.near?(@target_point,10.0)
          @body.v.x = [[-20,@body.v.x].max,20].min
        else
          @body.v.x = [[-70,@body.v.x].max,70].min
        end
        @normal = CP::ZERO_VEC_2
      end
    end
    
    def target(structure)
      @target_structure = structure
      move_towards(structure.body.p)
    end
    
    def target_direction
      @target_point.x > @body.p.x ? 1 : -1
    end
    
    def move_towards(p)
      @target_point = p
    end
    
    
    #old def
    def dont_move_towards(p)
      @control_body.p = p
      @game.rehash
      if @connection
        #@game.remove_object(@connection)
        @body.reset_forces
        @body.v = CP::ZERO_VEC_2
      else
        @connection = CP::Constraint::DampedSpring.new(@body,@control_body,CP::ZERO_VEC_2,CP::ZERO_VEC_2,0,10,0)
        @connection.max_force = 0.1
        @connection.max_bias = 10000
        @connection.bias_coef = 10000.0
      end
      #@connection = CP::Constraint::PivotJoint.new(@body,@control_body,CP::ZERO_VEC_2,p)
      #@connection.bias_coef = 1.0
      #@connection.max_force = 10000.0
      @game.add_object(@connection)
    end
    
    def self.collision_funcs(game)
      game.add_collision_func(:soldier,:island) do |arbiter,soldier,island|
        soldier.instance_variable_get(:@obj).on_ground(arbiter)
        true
      end
      game.add_collision_func(:soldier,:structure) do |soldier,structure|
        sold = soldier.instance_variable_get(:@obj)
        stru = structure.instance_variable_get(:@obj)
        sold.reached_structure(stru)
        false
      end
    end
    
  end
end