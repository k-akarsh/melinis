class CreateMelinisTasks < ActiveRecord::Migration
  def change
    create_table :melinis_tasks do |t|
      t.string :name
      t.text :description
      t.string :file_path
      t.string :command
      t.integer :individual_retries_limit
      t.integer :bulk_retries_limit

      t.timestamps
    end
  end
end
