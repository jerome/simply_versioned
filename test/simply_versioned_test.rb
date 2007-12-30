require File.join( File.dirname( __FILE__ ), 'test_helper' )

class Aardvark < ActiveRecord::Base
  simply_versioned :keep => 3
end

class Gnu < ActiveRecord::Base
  simply_versioned :keep => 4
end

class SimplyVersionedTest < FixturedTestCase
  
  def self.suite_setup
    ActiveRecord::Schema.define do
      create_table :aardvarks, :force => true do |t|
        t.string :name
        t.integer :age
      end
      
      create_table :gnus, :force => true do |t|
        t.string :name
        t.text :description
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
      drop_table :gnus
      drop_table :aardvarks
    end
  end
  
  def test_should_start_with_empty_versions
    anthony = Aardvark.new( :name => 'Anthony', :age => 35 )
    assert anthony.unversioned?
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
  
  def test_should_isolate_versioned_models
    anthony = Aardvark.create!( :name => 'Anthony', :age => 35 )
    gary = Gnu.create!( :name => 'Gary', :description => 'Gary the GNU' )
    
    assert_equal 2, Version.count
    assert_equal 1, anthony.versions.first.number
    assert_equal 1, gary.versions.first.number
  end
  
  def test_should_not_version_in_block
    anthony = Aardvark.create!( :name => 'Anthony', :age => 35 ) # v1
    
    assert_no_difference( 'anthony.versions.count' ) do
      anthony.age += 1
      anthony.without_versioning do
        anthony.save!
      end
    end
  end
  
end
