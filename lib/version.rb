# SimplyVersioned 0.3
#
# Simple ActiveRecord versioning
# Copyright (c) 2007 Matt Mower <self@mattmower.com>
# Released under the MIT license (see accompany MIT-LICENSE file)
#

# A Version represents a numbered revision of an ActiveRecord model.
#
# The version has two attributes +number+ and +yaml+ where the yaml attribute
# holds the representation of the ActiveRecord model attributes. To access
# these call +model+ which will return an instantiated model of the original
# class with those attributes.
#
class Version < ActiveRecord::Base #:nodoc:
  belongs_to :versionable, :polymorphic => true
  
  # Return an instance of the versioned ActiveRecord model with the attribute
  # values of this version.
  def model
    obj = versionable.class.new
    YAML::load( self.yaml ).each do |var_name,var_value|
      obj.__send__( "#{var_name}=", var_value )
    end
    obj
  end
  
  # Return the next higher numbered version, or nil if this is the last version
  def next
    versionable.versions.next( self.number )
  end
  
  # Return the next lower numbered version, or nil if this is the first version
  def previous
    versionable.versions.prev( self.number )
  end

protected
  def before_create
    self.number = if versionable.versions.empty?
      1
    else
      versionable.versions.maximum( :number ) + 1
    end
  end
  
end
