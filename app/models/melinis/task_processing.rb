module Melinis
  class TaskProcessing < ActiveRecord::Base
    belongs_to :task
    has_many :task_failures
  end
end
