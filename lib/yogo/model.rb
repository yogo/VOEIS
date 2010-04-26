
module Yogo
  # This module contains methods for a Yogo model
  #
  # @author Robbie Lamb
  module Model

    # This method should never be called directly
    #
    # @see http://ruby-doc.org/core-1.8.7/classes/Module.html#M000402 Ruby Doc for more info
    #
    # @return [boolean]
    #
    # @author Robbie Lamb robbie.lamb@gmail.com
    #
    # @api private
    def self.included(base)
      base.send(:include, DataMapper::Timestamps)
      base.send(:extend, ClassMethods)
      base.send(:include, InstanceMethods)
      base.send(:extend, Csv)
      base.class_eval do

        validates_present :change_summary, :if => :require_change_summary?

        base.properties.each do |property|
          # Create carrierwave class for this property.
          if property.type == DataMapper::Types::YogoFile
            path = File.join(Rails.root, Yogo::Setting['asset_directory'], asset_path)
            storage_dir = path.to_s
            anon_file_handler = Class.new(CarrierWave::Uploader::Base)
            anon_file_handler.instance_eval do 
              storage :file
              self.class_eval("def store_dir; '#{path}'; end")
            end

            named_class = Object.class_eval("#{self.name}::#{property.name.to_s.camelcase}File = anon_file_handler")
            mount_uploader property.name, named_class

          elsif property.type == DataMapper::Types::YogoImage
            path = File.join(Rails.root, Yogo::Setting['asset_directory'], asset_path)
            storage_dir = path.to_s
            anon_file_handler = Class.new(CarrierWave::Uploader::Base)
            anon_file_handler.instance_eval do 
              storage :file
              self.class_eval("def store_dir; '#{path}'; end")
            end

            named_class = Object.class_eval("#{self.name}::#{property.name.to_s.camelcase}File = anon_file_handler")
            mount_uploader property.name, named_class

          end
        end
      end
    end

    # This module contains the public methods for a Yogo model
    #
    # @author Robbie Lamb
    #
    # @api public
    module ClassMethods

      # The properties on a model for human consumption
      # 
      # @example @model.usable_properties.each{|prop| puts prop.display_name }
      # 
      # @return [Array] properties that are usable by human consumption
      # 
      # @author Robbie Lamb robbie.lamb@gmail.com
      # 
      # @api public
      def usable_properties
        properties.select{|p| p.name.to_s.match(/^yogo__/) }
      end

      ##
      # Create the asset path so we can reuse it
      # 
      # @return [String] The string path to the directory/folder to storage for assets of this model.
      # 
      # @example Get the path to the asset directory for a model
      #   Model.asset_path => "module/class"
      # 
      # @author Ivan Judson
      # 
      # @api public
      def asset_path
        self.name.gsub('::', '/')
      end

      # The name of the model humanized
      # 
      # @example 
      #   @model.public_name
      # 
      # @return [String] humanized name of the class
      # 
      # @author Robbie Lamb robbie.lamb@gmail.com
      # 
      # @api public
      def public_name
        @_public_name ||= self.name.split('::')[-1].humanize
      end
    end

    module InstanceMethods
      
      private
      
      # Check to see if the change_summary field is required to be filled out
      # 
      # @return [TrueClass or FalseClass]
      # 
      # @author Robbie Lamb robbie.lamb@gmail.com
      # 
      # @api private
      def require_change_summary?
        Yogo::Setting[:require_change_sumary] && !new_record?
      end
    end

  end
end