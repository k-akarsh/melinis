module Melinis
  class TaskFailure < ActiveRecord::Base
    belongs_to :task_processing
    belongs_to :task
  end
end
