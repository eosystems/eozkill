# == Schema Information
#
# Table name: solar_systems
#
#  id             :integer          not null, primary key
#  region_id      :integer          not null
#  name           :string(255)      not null
#  security       :decimal(20, 4)
#  security_class :string(255)
#

class SolarSystem < ApplicationRecord
end
