module Melinis
  class TaskList < ActiveRecord::Base
    self.table_name = 'melinis_tasks'
    has_many :task_processings, :foreign_key => "task_id"
    has_many :task_failures, :foreign_key => "task_id"
  end
end
