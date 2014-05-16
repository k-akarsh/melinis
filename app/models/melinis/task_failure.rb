module Melinis
  class TaskFailure < ActiveRecord::Base
    belongs_to :task_processing
    belongs_to :task

    def self.to_be_processed(individual_retries_limit)
      where("status = ? AND retry_count < ?", 'failure', individual_retries_limit)
    end
  end
end
