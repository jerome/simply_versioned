# SimplyVersioned 0.1
#
# Simple ActiveRecord versioning
# Copyright (c) 2007 Matt Mower <self@mattmower.com>
# Released under the MIT license (see accompany MIT-LICENSE file)
#

module SoftwareHeretics
  
  module ActiveRecord
  
    module SimplyVersioned
    
      module ClassMethods
        def simply_versioned( options = {} )
          
          options.reverse_merge!( {
            :limit => 99
          })
          
          has_many :versions, :order => 'number DESC', :as => :versionable, :dependent => :destroy, :extend => VersionsProxyMethods

          before_save :simply_versioned_cache_values
          after_save :simply_versioned_create_version
          
          cattr_accessor :keep_versions
          self.keep_versions = options[:limit]
          
        end

      end

      module InstanceMethods
        
        def revert_to_version( version )
          version = if version.kind_of?( Version )
            version
          else
            version = self.versions.find( :first, :conditions => { :number => Integer( version ) } )
          end
          self.update_attributes( YAML::load( version.yaml ) )
        end
        
        protected
        
        def simply_versioned_cache_values
          @simply_versioned_value_cache = self.attributes
          true
        end
        
        def simply_versioned_create_version
          if self.versions.create( :yaml => @simply_versioned_value_cache.to_yaml )
            self.versions.clean( keep_versions )
          end
          true
        end
        
      end

      module VersionsProxyMethods
        
        def get( number )
          find_by_number( number )
        end
        
        def first
          find( :first, :order => 'number ASC' )
        end
        
        def current
          find( :first, :order => 'number DESC' )
        end
        
        def clean( versions_to_keep )
          find( :all, :conditions => [ 'number <= ?', self.maximum( :number ) - versions_to_keep ] ).each do |version|
            version.destroy
          end
        end
        
        def next( number )
          find( :first, :order => 'number ASC', :conditions => [ "number > ?", number ] )
        end
        
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