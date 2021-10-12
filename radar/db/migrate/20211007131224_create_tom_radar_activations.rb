# frozen_string_literal: true

# Table to track the times when TOM recieves a call
class CreateTomRadarActivations < ActiveRecord::Migration[6.1]
  def change
    create_table :tom_radar_activations do |t|
      t.string :source
      t.string :issuetitle
      t.string :issuebody
      t.string :status

      t.timestamps
    end
  end
end
