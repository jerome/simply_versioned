require File.join( File.dirname( __FILE__ ), 'test_helper' )

class Aardvark < ActiveRecord::Base
  simply_versioned :limit => 3
end

class SimplyVersionedTest < FixturedTestCase
  
  def self.suite_setup
    ActiveRecord::Schema.define do
      create_table :aardvarks, :force => true do |t|
        t.string :name
        t.integer :age
      end
      
      create_table :versions, :force => true do |t|
        t.integer   :versionable_id
        t.string    :versionable_type
        t.integer   :number
        t.text      :yaml

        t.timestamps
      end
    end
  end
  
  def self.suite_teardown
    ActiveRecord::Schema.define do
      drop_table :versions
      drop_table :aardvarks
    end
  end
  
  def test_should_version_on_create
    anthony = Aardvark.create!( :name => 'Anthony', :age => 35 )
    assert_equal 1, anthony.versions.count
  end
  
  def test_should_version_on_save
    anthony = Aardvark.create!( :name => 'Anthony', :age => 35 )
    anthony.age += 1
    anthony.save!
    assert_equal 2, anthony.versions.count
  end
  
  def test_should_trim_versions
    anthony = Aardvark.create!( :name => 'Anthony', :age => 35 ) # v1
    anthony.age += 1
    anthony.save! #v2
    
    anthony.age += 1
    anthony.save! #v3
    
    anthony.age += 1
    anthony.save! #v4 !!
    
    assert_equal 3, anthony.versions.count
    assert_equal 36, anthony.versions.first.model.age
    assert_equal 38, anthony.versions.current.model.age
  end
  
  def test_should_revert
    anthony = Aardvark.create!( :name => 'Anthony', :age => 35 ) # v1
    anthony.age += 1
    anthony.save! #v2
    
    anthony.revert_to_version( 1 )
    assert_equal 35, anthony.age
    
    assert_equal 3, anthony.versions.count
    assert_equal 35, anthony.versions.current.model.age
  end
  
  def test_should_delete_dependent_versions
    anthony = Aardvark.create!( :name => 'Anthony', :age => 35 ) # v1
    anthony.age += 1
    anthony.save! #v2
    
    assert_difference( 'Version.count', -2 ) do
      anthony.destroy
    end
  end
  
end
