module LD17
  module DrawableShape
    def draw_shape
      case @shape
      when CP::Shape::Poly then draw_poly
      when CP::Shape::Cirlce then draw_circle
      when CP::Shape::Segment then draw_segment
      end
    end

    def draw_poly
      verts = @vertices
      verts.size.times do |i|
        j = (i+1) % verts.size
        v1, v2 = verts[i], verts[j]
        l1, l2 = @body.local2world(v1), @body.local2world(v2)
        x1, y1, x2, y2 = l1.x, l1.y, l2.x, l2.y
        c = 0xFFFF0000
        z = 100
        MainWindow.draw_line(x1,y1,c,x2,y2,c,z)
      end
    end
    
    def draw_circle
    end
    
    def draw_segment
    end
  end
end
