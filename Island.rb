require 'chipmunk_object'
require 'SVGReader'
require 'drawable_shape'

module LD17
  class Island
    include CP::Object
    include DrawableShape
    VERTICES = SVGReader.import_vertices("island.svg","island")
    MASS = 500.0
    WEIGHT_MASS = 0
    MOMENT = CP.moment_for_poly(MASS,VERTICES,CP::ZERO_VEC_2)/25
    
    attr_reader :body
    def initialize(game)
      @game = game
      @body = CP::Body.new(MASS,MOMENT)
      @body.p = vec2(320,240)
      @body.v = vec2(0,0)
      @vertices = VERTICES.map {|v| @body.world2local(v)}
      @shape = CP::Shape::Poly.new(@body,@vertices,CP::ZERO_VEC_2)
      @shape.e = 0; @shape.u = 0.7
      @shape.collision_type = :island
      @capsized_vertices = []
      #weight1 = CP::Body.new(WEIGHT_MASS,100)
      #weight2 = CP::Body.new(WEIGHT_MASS,100)
      #weight1.p = @body.local2world(vec2(-200,0))
      #weight2.p = @body.local2world(vec2( 200,0))
      #joint1 = CP::Constraint::PivotJoint.new(@body,weight1,weight1.p)
      #joint2 = CP::Constraint::PivotJoint.new(@body,weight2,weight2.p)
      
      @s_body = CP::StaticBody.new
      @groove = CP::Constraint::GrooveJoint.new(@s_body,@body,vec2(320,0),vec2(320,10000),vec2(0,0))
      
      buoyancy_points; buoy_force; sink_force
      @body.velocity_func = apply_buoyancy
      init_chipmunk_object(@body,@shape,@s_body,@groove) #,weight1,weight2,joint1,joint2)
    end
    
    def drop_range
      a,b = @shape.bb.l+70, @shape.bb.r-70
      (a..b)
    end
    
    def surface_at(x)
      percent = @shape.segment_query(vec2(x,0),vec2(x,480)).t
      if percent
        y = percent * 480
        vec2(x,y)
      else
        nil
      end
    end
    
    def danger_vertices
      @danger_vertices ||= [2,-1].map {|i| @vertices[i] }
    end
    
    def disaster_vertices
      @disaster_vertices ||= [3,-2].map {|i| @vertices[i] }
    end
    
    def sink_vertex
      v = @vertices
      {
        v[ 3] => v[1],
        v[-2] => v[0]
      }
    end
    
    def top_vertex
      @vertices[4]
    end
    
    def danger?
      danger_vertices.any? {|v| @body.local2world(v).y > @game.water_level }
    end
    
    def disaster?
      @capsized || disaster_vertices.any? {|v| @body.local2world(v).y > @game.water_level }
    end    
    
    def capsize!
      unless @capsized
        cp = disaster_vertices.select {|v| @body.local2world(v).y > @game.water_level }.first
        @capsize_point = sink_vertex[cp]
        @body.moment = CP.moment_for_poly(MASS,VERTICES,CP::ZERO_VEC_2)
      end
      @buoy_force *= 0.99
      @sink_force /= 0.95
      @sink_force.y = [sink_force.y,max_sink_force.y].min
      @capsized = true
    end
    
    
    def apply_buoyancy
      Proc.new do |body,gravity,damping,dt|
        gravity = $gravity
        body.reset_forces
        body.apply_force(sink_force,@capsize_point) if @capsized
        body.apply_force(sink_force,CP::ZERO_VEC_2) if @capsized
        buoyancy_points.each do |point|
          p = body.local2world(point)
          if p.y > @game.water_level
            r = p - body.p
            v = body.v + (r.perp * body.w)
            f_damp = v * (-0.0003*v.length)
            f = buoy_force + f_damp
            body.apply_force(f,r)
          end
        end
        body.update_velocity(gravity,damping,dt)
      end
    end
    
    def sink_force
      @sink_force ||= -buoy_force * buoyancy_points.size / 10
    end
    
    def buoyancy_points
      @buoyancy_points ||= begin
        bb = @shape.bb
        width = bb.r - bb.l
        height = bb.t - bb.b
        numx = 10; numy = 5
        stepx = width/(numx.to_f)
        stepy = height/(numy.to_f)
        points = Array.new(numx) {|x| Array.new(numy) {|y| vec2(x*stepx+bb.l,y*stepy+bb.b)}}.flatten
        points.select {|point| @shape.point_query(point)}.map {|point| @body.world2local(point)}
      end
    end
    
    def buoy_force
      @buoy_force ||= original_buoy_force
    end
    
    def original_buoy_force
      @original_buoy_force ||= vec2(0,(-(3.2*(MASS+2*WEIGHT_MASS)*$gravity.length)/(buoyancy_points.size)))
    end
    
    def max_sink_force
      @max_sink_force ||= original_buoy_force * -3
    end
    
    def draw
      draw_shape
    end
  end
end