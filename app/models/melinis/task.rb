module Melinis
  class Task < ActiveRecord::Base
    has_many :task_processings
    has_many :task_failures

    def self.start(task_name,options = {})
      options = {description: '',file_path: '',command: '',individual_retries_limit: 1,bulk_retries_limit: 1}.merge(options)
      task = self.find_or_initialize_by_name(task_name)
      task.update_attributes(options)
      task_processing = TaskProcessing.create({:task_id => task.id})
      [task.id,task_processing,task.task_failures_to_be_processed]
    end

    def self.success(task_id,task_processing_id,processed_details)
      task_processing = TaskProcessing.update(task_processing_id,{:processed_details => processed_details.to_yaml})
    end

    def self.failure(task_id,task_failure_id = nil,failure_details)
      task_failure = TaskFailure.find_by_id(task_failure_id)
      if task_failure
        task_failure.increment(:retry_count).update_attributes({:failure_details => failure_details.to_yaml})
      else
        TaskFailure.create(:task_id => task_id,:failure_details => failure_details.to_yaml,:status => 'failure')
      end
    end

    def task_failures_to_be_processed
      self.task_failures.where("status = ? AND retry_count < ?",'failure',self.individual_retries_limit)
    end

  end
end
