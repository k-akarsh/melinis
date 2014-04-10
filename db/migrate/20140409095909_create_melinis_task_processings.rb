class CreateMelinisTaskProcessings < ActiveRecord::Migration
  def change
    create_table :melinis_task_processings do |t|
      t.text :processed_details
      t.integer :task_id

      t.timestamps
    end
  end
end
