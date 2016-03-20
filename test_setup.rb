require './app.rb'

c = Character.create(:user_name => "Byte String", :display_name => "Byte")
c.statistics.create(:name => "vigor", :value => 10)
c.statistics.create(:name => "swiftness", :value => 10)
c.statistics.create(:name => "toughness", :value => 10)
c.statistics.create(:name => "intellect", :value => 10)
c.statistics.create(:name => "cunning", :value => 10)

c = Character.create(:user_name => "Byte String", :display_name => "Byte 2")
c.statistics.create(:name => "vigor", :value => 1)
c.statistics.create(:name => "swiftness", :value => 1)
c.statistics.create(:name => "toughness", :value => 1)
c.statistics.create(:name => "intellect", :value => 1)
c.statistics.create(:name => "cunning", :value => 1)