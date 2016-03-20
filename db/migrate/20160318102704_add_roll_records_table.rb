class AddRollRecordsTable < ActiveRecord::Migration
    create_table :roll_records do |t|
        t.integer :roll
        t.integer :modifier_value
        t.string :modifier_type
        t.string :damage_class
        t.integer :damage_modifier_value
        t.string :damage_modifier_type
        t.string :note
        t.integer :character_id
        
        t.timestamps
    end
end
