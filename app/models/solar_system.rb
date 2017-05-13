# == Schema Information
#
# Table name: solar_systems
#
#  id        :integer          not null, primary key
#  region_id :integer          not null
#  name      :string(255)      not null
#

class SolarSystem < ApplicationRecord
end
