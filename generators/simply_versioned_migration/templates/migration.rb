class SimplyVersionedMigration < ActiveRecord::Migration
  
  def self.up
    create_table :versions do |t|
      t.integer   :versionable_id
      t.string    :versionable_type
      t.integer   :number
      t.text      :yaml
      
      t.timestamps      
    end
    
    add_index :versions, [:versionable_id, :versionable_type]
  end
  
  def self.down
    drop_table :versions
  end
end
