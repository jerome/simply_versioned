# SimplyVersioned 0.3
#
# Simple ActiveRecord versioning
# Copyright (c) 2007 Matt Mower <self@mattmower.com>
# Released under the MIT license (see accompany MIT-LICENSE file)
#

module SoftwareHeretics
  
  module ActiveRecord
  
    module SimplyVersioned
    
      module ClassMethods
        
        # Marks this ActiveRecord model as being versioned. Calls to +create+ or +save+ will,
        # in future, create a series of associated Version instances that can be accessed via
        # the +versions+ association.
        #
        # Options:
        # +limit+ - specifies the number of old versions to keep (default = 99)
        #
        # To save the record without creating a version either set +versioning_enabled+ to false
        # on the model before calling save or, alternatively, use +without_versioning+ and save
        # the model from its block.
        #
        def simply_versioned( options = {} )
          options.reverse_merge!( {
            :keep => 99
          })
          
          has_many :versions, :order => 'number DESC', :as => :versionable, :dependent => :destroy, :extend => VersionsProxyMethods

          after_save :simply_versioned_create_version
          
          cattr_accessor :simply_versioned_keep_limit
          self.simply_versioned_keep_limit = options[:keep]
          
          class_eval do
            def versioning_enabled=( enabled )
              self.instance_variable_set( :@simply_versioned_enabled, enabled )
            end
            
            def versioning_enabled?
              enabled = self.instance_variable_get( :@simply_versioned_enabled )
              if enabled.nil?
                enabled = self.instance_variable_set( :@simply_versioned_enabled, true )
              end
              enabled
            end
          end
        end

      end

      # Methods that will be defined on the ActiveRecord model being versioned
      module InstanceMethods
        
        # Revert this model instance to the attributes it had at the specified version number.
        def revert_to_version( version )
          version = if version.kind_of?( Version )
            version
          else
            version = self.versions.find( :first, :conditions => { :number => Integer( version ) } )
          end
          self.update_attributes( YAML::load( version.yaml ) )
        end
        
        # Invoke the block for this record with versioning disabled. Calls to save
        # during the block will not result in the creation of a new version.
        def without_versioning( &block )
          versioning_was_enabled = self.versioning_enabled?
          self.versioning_enabled = false
          begin
            yield self
          ensure
            self.versioning_enabled = versioning_was_enabled
          end
        end
        
        def unversioned?
          self.versions.empty?
        end
        
        protected
        
        def simply_versioned_create_version
          if self.versioning_enabled?
            if self.versions.create( :yaml => self.attributes.to_yaml )
              self.versions.clean( simply_versioned_keep_limit )
            end
          end
          true
        end
        
      end

      module VersionsProxyMethods
        
        # Get the Version instance corresponding to this models for the specified version number.
        def get( number )
          find_by_number( number )
        end
        
        # Get the first Version corresponding to this model.
        def first
          find( :first, :order => 'number ASC' )
        end

        # Get the current Version corresponding to this model.
        def current
          find( :first, :order => 'number DESC' )
        end
        
        # If the model instance has more versions than the limit specified, delete all excess older versions.
        def clean( versions_to_keep )
          find( :all, :conditions => [ 'number <= ?', self.maximum( :number ) - versions_to_keep ] ).each do |version|
            version.destroy
          end
        end
        
        # Return the Version for this model with the next higher version
        def next( number )
          find( :first, :order => 'number ASC', :conditions => [ "number > ?", number ] )
        end
        
        # Return the Version for this model with the next lower version
        def prev( number )
          find( :first, :order => 'number DESC', :conditions => [ "number < ?", number ] )
        end
      end

      def self.included( receiver )
        receiver.extend         ClassMethods
        receiver.send :include, InstanceMethods
      end
    
    end
  
  end

end

ActiveRecord::Base.send( :include, SoftwareHeretics::ActiveRecord::SimplyVersioned )
