class Init < ActiveRecord::Migration
  def change
    create_table :characters do |t|
        t.string :user_name
        t.string :display_name
        
        t.timestamps
    end
    
    create_table :statistics do |t|
      t.string :name
      t.integer :value
      t.integer :character_id
        
      t.timestamps
    end
  end
end
