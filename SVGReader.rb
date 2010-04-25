require 'rexml/document'
require 'chipmunk_object'

module LD17
  module SVGReader
    module_function
    def import_vertices(file,path_id)
      doc = REXML::Document.new(File.read(file))
      path = doc.get_elements("//path##{path_id}").first
      str = path.attribute(:d).to_s
      points = interpret_path_string(str)
      translate_str = path.parent.attribute("transform").to_s.match(/translate\((.*)\)/).captures.first
      tx,ty = translate_str.split(',').map {|s| s.to_i}
      translation = vec2(tx,ty)
      points.map {|v| v + translation}
    end
    
    def interpret_path_string(path_string)
      point_strings = path_string.split(" ")[1..-3]
      points = point_strings.map do |point_string|
        x,y = point_string.split(',').map {|s| s.to_i}
        vec2(x,y)
      end
      
    end
    
  end
end