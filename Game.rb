require './chipmunk_object'
#require 'chipmunk-ffi'
require 'Island'
require 'Soldier'
require 'Structure'
require 'Airplane'

module ZOrder
  Water = 20
end

module LD17
  class Game
    attr_reader :water_level
    def initialize
      @space = CP::Space.new
      @space.iterations = 5
      $gravity = @space.gravity = vec2(0,100)
      @space.resize_static_hash(40.0,999)
      @space.resize_active_hash(40.0,2999)
      
      @water_level = 240
      @island = Island.new(self)
      add_object(@island)
      
      @soldiers = []
      Soldier.collision_funcs(self)
      
      @airplanes = []
      Airplane.collision_funcs(self)
      
      @structures = []
      Structure.collision_funcs(self)
      
      @background_image
      @water_image
    end
    
    def add_object(cp_obj)
      @space.add_object(cp_obj)
    end
    
    def remove_object(cp_obj)
      @space.remove_object(cp_obj)
    end
    
    def rehash
      @space.rehash_static
    end
    
    def button_down(id)
      case id
      when Gosu::KbEscape then MainWindow.close
      #when Gosu::KbSpace  then self.update(1,MainWindow.dt)
      when Gosu::MsLeft
        drop_structure 
      when Gosu::KbA
        create_plane
      end
    end
    
    def drop_structure
      p = vec2(MainWindow.mouse_x,MainWindow.mouse_y)
      add_structure(p)
    end
    
    def create_plane
      side = rand(2) == 1 ? :left : :right
      a = Airplane.new(self,target_x,rand(150),side)
      @airplanes << a
      add_object(a)
      a
    end
    
    def target_x
      x_range = @island.drop_range
      f, l = x_range.first, x_range.last
      target_x = f + rand(l-f)
    end
    
    def drop_payload(p)
      rand(2) == 1 ? add_structure(p) : add_soldier(p)
    end
    
    def add_structure(p)
      s = Structure.new(p,10,10,10)
      @structures << s
      add_object(s)
    end
    
    def add_soldier(p)
      s = Soldier.new(self,p)
      @soldiers << s
      add_object(s)
    end
    
    def button_up(id)
    end
    
    def update(steps,dt)
      steps.times do
        @soldiers.each {|s| s.update_target }
        @space.step(dt)
      end
      disaster_check
    end
    
    def disaster_check
      if @island.disaster?
        @island.capsize!
        #puts "Capsize!"
      elsif @island.danger?
        #puts "Danger!"
        make_soldiers_run_away
      end
    end
    
    def make_soldiers_run_away
      danger_points = @island.danger_vertices.map {|v| @island.body.local2world(v)}
      safe_vertex = danger_points.reject {|v| v.y > @water_level}.sort_by {|v| -v.y }.first
      safe_vertex ||= @island.local2world(@island.top_vertex)
      @soldiers.each do |soldier|
        target_x = safe_vertex.x + rand(10) - 5
        p = @island.surface_at(target_x)
        if p
          soldier.move_towards(p - vec2(0,5))
          soldier.target_structure = nil
        else
          puts "FAIL!"
        end
      end
    end
    
    
    
    def draw
      draw_background
      draw_water
      draw_island
      draw_soldiers
      draw_airplanes
      draw_structures
    end
    
    def draw_background
      c = 0xFFFFFFFF
      MainWindow.draw_quad(0,0,c,640,0,c,0,480,c,640,480,c,0)
    end
    
    def draw_water
      c = 0x660000CC
      w = @water_level
      MainWindow.draw_quad(0,w,c,640,w,c,0,480,c,640,480,c,ZOrder::Water)
    end
    
    def draw_island
      @island.draw
    end
    
    def draw_soldiers
      @soldiers.each do |soldier|
        soldier.draw
      end
    end
    
    def draw_airplanes
      @airplanes.each do |airplane|
        airplane.draw
      end
    end
    
    def draw_structures
      @structures.each do |structure|
        structure.draw
      end
    end
    
    def add_collision_func(a,b,type=:pre,&block)
      @space.add_collision_func(a,b,type,&block)
    end
    
    def destroy(cp_obj)
      cp_obj.clean_up
      remove_object(cp_obj)
      case cp_obj
      when Airplane then @airplanes.delete(cp_obj)
      when Soldier then @soldiers.delete(cp_obj)
      when Structure then @structures.delete(cp_obj)
      end
    end    
    
    def pick_target_for_soldier(soldier)
      if (set = @structures.select {|s| s.hit? && s.body.p.y < @water_level}).empty?
        p = @island.surface_at(target_x) - vec2(0,5)
        soldier.move_towards(p)
      else
        choice = set.sort_by {rand}.first
        soldier.target(choice)
      end
    end
    
  end
end
