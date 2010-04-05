# Yogo Data Management Toolkit
# Copyright (c) 2010 Montana State University
#
# License -> see license.txt
#
# FILE: factory.rb
# This Factory builds DataMapper models 
#
module DataMapper
  class Factory
    
    # There is one factory to rule them all, and in the data bind them.
    include Singleton
    
    # Created a datamapper model based on the description passed in
    #
    # @param [Hash] desc
    # @option desc [Array] :modules array of modules the class will be namespaced into by the order they are in the array
    # @option desc [String or Symbol] :name The name of the class in camel case format.
    # @option desc [Hash] :properties a hash of properties
    # @option properties [Hash] pname 
    #  This is the actual property name and is the hash-key
    # @options pname [String] :ptype 
    #  The datatype of the property   
    # @option pname [Boolean] :required  
    #  If the property can be null or not
    # @option pname [Integer] :position 
    #  the position/order of the property when stored and displayed
    # 
    # @param [String] repository_name 
    #  The name of the repository to associate the DataMapper Model with
    # 
    # @param [Hash] options
    # @options options [String] :attribute_prefix
    #
    # @return [Hash] This will look for a hash with certain keys in it. Those keys are:
    # * :modules    =>  [], an array of modules the class will be namespaced 
    #   into by the order they are in the array
    # *  :name       =>  'ClassName' The name of the class in camel case format.
    # * :properties =>  {}, a hash of properties
    #   Each key in the property hash is the name of the property.
    #   if the key points to a string or symbol, that will be used as the property type.
    #   The property type should be a valid DataMapper property type.
    # 
    #
    #     If the key points to a hash, dum, Dum, DUM!? What will happen?!
    #
    #  TODO : Implement support for relationships/associations
    # :associations => {} associations this class has with other classes.
    #
    # @author Yogo Team
    #
    # @api public
    def build(desc, repository_name = :default, options = {})
      module_names = desc[:modules] || []
      class_name   = desc[:name]
      properties   = desc[:properties]
      full_name    = (module_names + [class_name]).join('::')
      attribute_prefix = options[:attribute_prefix]
      
      # Create the scoping for the class, if it doesn't already exist.
      namespace = if module_names.any?
        Object.make_module(module_names.join('::'))
      else
        Object
      end

      if namespace.const_defined?(class_name) # && options[:overwrite] == true
        cur_class = namespace.const_get(class_name)
        DataMapper::Model.descendants.delete(cur_class)
        namespace.send(:remove_const, class_name.to_sym)
      end

      # Define our anonymous class, anonymously.
      anon_class = DataMapper::Model.new do 
        self.class_eval("def self.default_repository_name; :#{repository_name}; end")
        properties.each_pair do |property, opts|
          if opts.is_a?(Hash)
            opts[:type] = :'DataMapper::Types::Serial' if opts[:type].to_s == 'Serial'
            opts[:prefix] = attribute_prefix unless property.to_sym == :yogo_id
            property( property.to_sym, eval(opts[:type].to_s), opts.reject{|k,v| k == :type })
          else
            opts = :'DataMapper::Types::Serial' if opts.to_s == 'Serial'
            options = property.to_sym == :yogo_id ? {} : { :prefix => attribute_prefix }
            property( property.to_sym, eval(opts.to_s), options)
          end
        end
      end

      # Give the class a name.
      named_class = namespace.const_set(class_name, anon_class)
      
      named_class.send(:include, options[:modules]) if options.has_key?(:modules)
      named_class.properties.sort!
      return named_class
    end

    # FIXME make me shorter
    # FIXME @return [] This accepts class_name ("Yogo::Example::SomeName") and a 2-dimensional
    # array containing the first three line of a CSV file.
    #
    # The array should contain:
    # 1. property names in [0][]
    # 2. property types in [1][]
    # 3. property units in [2][] - currently unsupported
    # 
    # Returns a DataMapper model with properties defined by spec_array
    # FIXME @api private, semipublic, or public
    # def make_model_from_array(class_name, spec_array)
    #   scopes = class_name.split('::')
    #   spec_hash = { :name => scopes[-1], :properties => Hash.new }
    #   spec_hash[:modules] = scopes[0..-2] unless scopes.length.eql?(1)
    #   spec_array[0].each_index do |idx|
    #     prop_hash = Hash.new
    #     pname = spec_array[0][idx].tableize.singular.gsub(' ', '_')
    #     ptype = Yogo::Types.human_to_dm(spec_array[1][idx])
    #     punits = spec_array[2][idx]
    #     prop_hash = { pname => { :type => ptype, :required => false, :position => idx } }
    #     spec_hash[:properties].merge!(prop_hash)
    #   end
    #   spec_hash[:properties].merge!({ 'yogo_id' => {:type => DataMapper::Types::Serial, :field => 'id' }})
    #   # puts "CSV Spec Hash: #{spec_hash.inspect}"
    #   build(spec_hash, :yogo, { :attribute_prefix => "yogo" } )
    # 
    # end
    
  end# class Factory
end # module DataMapper