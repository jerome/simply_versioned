# SimplyVersioned 0.1
#
# Simple ActiveRecord versioning
# Copyright (c) 2007 Matt Mower <self@mattmower.com>
# Released under the MIT license (see accompany MIT-LICENSE file)
#

class Version < ActiveRecord::Base #:nodoc:
  belongs_to :versionable, :polymorphic => true
  
  def before_create
    self.number = if versionable.versions.empty?
      1
    else
      versionable.versions.maximum( :number ) + 1
    end
  end
  
  def model
    obj = versionable.class.new
    YAML::load( self.yaml ).each do |var_name,var_value|
      obj.__send__( "#{var_name}=", var_value )
    end
    obj
  end
  
  def next
    versionable.versions.next( self.number )
  end
  
  def previous
    versionable.versions.prev( self.number )
  end
  
end
