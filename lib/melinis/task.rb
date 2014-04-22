module Melinis
  class Task
    attr_reader :task,:task_processing,:task_failures

    def initialize(task_name,options = {})
      options = {description: '',file_path: '',command: '',individual_retries_limit: 1,bulk_retries_limit: 1}.merge(options)
      @task = TaskList.find_or_initialize_by_name(task_name)
      @task.update_attributes(options)
      @task_processing = TaskProcessing.create({:task_id => @task.id})
      @task_failures = task_failures_to_be_processed
    end

    def end(processed_details)
      @task_processing.processed_details = processed_details.to_yaml
      @task_processing.save!
    end

    def failure(failure_details,args = {})
      args = {:task_failure_id => nil,:status => 'failure'}.merge(args)
      task_failure = TaskFailure.find_by_id(args[:task_failure_id])
      if task_failure
        task_failure.increment(:retry_count).update_attributes({:failure_details => failure_details.to_yaml,:status => args[:status]})
      else
        TaskFailure.create(:task_processing_id => @task_processing.id,:task_id => @task.id,:failure_details => failure_details.to_yaml,:status => 'failure')
      end
    end	

    def task_failures_to_be_processed
      @task.task_failures.where("status = ? AND retry_count < ?",'failure',@task.individual_retries_limit)
    end

  end
end
