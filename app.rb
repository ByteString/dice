require 'rubygems'
require 'sinatra'
require 'sinatra/activerecord'
require 'json'
require './environments'

set :environment, :development
set :bind, '0.0.0.0'
set :port, '3000'
set :logging, true


def number_with_indefinite_article(number)
    #This presumes that rolls cannot reach 80.
    [8, 11, 18].include?(number) ? "an #{number}" : "a #{number}"  
end

class Character < ActiveRecord::Base
  has_many :statistics
  has_many :roll_records
    
    def stat_roll(modifier)
        @modifier = self.statistics.find_by(:name => modifier)
        @roll = rand(19) + 1
        @roll_record = self.roll_records.new
        @roll_record.roll = @roll
        @roll_record.modifier_value = @modifier.value
        @roll_record.modifier_type = modifier
        @roll_record.note = "#{self.display_name} rolled #{number_with_indefinite_article(@roll + @modifier.value)} (Rolled #{@roll} + #{@modifier.value} #{modifier})"
        @roll_record.save
        return @roll_record
    end
    
    def damage_roll(damage_class)
        chance_to_hit_modifier = "swiftness" if (["ranged", "melee"].include? damage_class)
        chance_to_hit_modifier = "intellect" if damage_class == "magic"
        
        damage_value_modifier = "vigor" if damage_class == "melee"
        damage_value_modifier = "intellect" if damage_class == "magic"
        damage_value_modifier = "cunning" if damage_class == "ranged"
        
        @chance_to_hit_modifier = self.statistics.find_by(:name => chance_to_hit_modifier)
        @damage_value_modifier = self.statistics.find_by(:name => damage_value_modifier)
        
        @roll = rand(19) + 1
        @roll_record = self.roll_records.new
        @roll_record.roll = @roll
        @roll_record.modifier_value = @chance_to_hit_modifier.value
        @roll_record.modifier_type = chance_to_hit_modifier
        @roll_record.damage_class = damage_class
        @roll_record.damage_modifier_value = @damage_value_modifier.value
        @roll_record.damage_modifier_type = damage_value_modifier
        @roll_record.note = "For #{damage_class} chance to hit, #{self.display_name} rolled #{number_with_indefinite_article(@roll + @chance_to_hit_modifier.value)} \
(Rolled #{@roll} + #{@chance_to_hit_modifier.value} #{chance_to_hit_modifier} for #{@damage_value_modifier.value} #{damage_class} damage)"
        @roll_record.save
        return @roll_record
    end
end

class Statistic < ActiveRecord::Base
  belongs_to :character
    validates :name, uniqueness: { scope: :character_id,
      message: "should have one of each statistic" }
end

class RollRecord < ActiveRecord::Base
    belongs_to :character
end

get '/characters' do
    puts env['HTTP_X_SECONDLIFE_OWNER_NAME']
    @character = Character.where(:user_name => env['HTTP_X_SECONDLIFE_OWNER_NAME'])
    if @character.empty?
        status 404
        body "No characters"
    else
        content_type :json
        @character.to_json(:exclude => [:statistics])
    end
end

get '/characters/:display_name' do
    @character = Character.find_by(:user_name => env['HTTP_X_SECONDLIFE_OWNER_NAME'], :display_name => params['display_name'])
    if @character.nil? 
        status 404
        body "Character not found"
    else
        content_type :json
        @character.to_json(:include => [:statistics])
    end
end

get '/characters/:display_name/roll/:statistic' do
    @character = Character.find_by(:user_name => env['HTTP_X_SECONDLIFE_OWNER_NAME'], :display_name => params['display_name'])
    @roll = @character.stat_roll(params['statistic'])
    content_type :json
    @roll.to_json
end

get '/roll_records/:id' do
    content_type :json
    roll_record = RollRecord.find_by_id(params[:id])
    roll_record.to_json
end

#Special Damage Types
get '/characters/:display_name/roll/damage/:damage_class' do
    @character = Character.find_by(:user_name => env['HTTP_X_SECONDLIFE_OWNER_NAME'], :display_name => params['display_name'])
    @roll = @character.damage_roll(params['damage_class'])
    
    content_type :json
    @roll.to_json
end


get '/' do
    "GET RECEIVED"
end

post '/' do
    "POST RECEIVED"
end