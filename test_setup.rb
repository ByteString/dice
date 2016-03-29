require './app.rb'

c = Character.create(:user_name => "Byte String", :display_name => "Byte")
c.statistics.create(:name => "vigor", :value => 100)
c.statistics.create(:name => "swiftness", :value => 100)
c.statistics.create(:name => "toughness", :value => 100)
c.statistics.create(:name => "intellect", :value => 100)
c.statistics.create(:name => "cunning", :value => 100)

c = Character.create(:user_name => "Byte String", :display_name => "Byte 2")
c.statistics.create(:name => "vigor", :value => 1)
c.statistics.create(:name => "swiftness", :value => 1)
c.statistics.create(:name => "toughness", :value => 1)
c.statistics.create(:name => "intellect", :value => 1)
c.statistics.create(:name => "cunning", :value => 1)