class CreateMelinisTaskFailures < ActiveRecord::Migration
  def change
    create_table :melinis_task_failures do |t|
      t.text :failure_details
      t.integer :task_id
      t.integer :task_processing_id
      t.integer :retry_count
      t.string :status

      t.timestamps
    end
  end
end
