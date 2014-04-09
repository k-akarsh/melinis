class CreateMelinisTaskFailures < ActiveRecord::Migration
  def change
    create_table :melinis_task_failures do |t|
      t.text :failure_details
      t.integer :task_id

      t.timestamps
    end
  end
end
