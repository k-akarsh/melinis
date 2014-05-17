module Melinis
  class Task
    attr_reader :last_run, :failures

    def initialize(task_name, options = {})
      options = {
        :description => '',
        :file_path => '',
        :command => '',
        :individual_retries_limit => 1,
        :bulk_retries_limit => 1
      }.merge(options)
      @task = Melinis::TaskList.find_or_initialize_by_name(task_name)
      @task.update_attributes(options)

      @last_run = @task.task_processings.last
      @current_run = Melinis::TaskProcessing.create!({:task_id => @task.id})
      @failures = @task.task_failures.to_be_processed(@task.individual_retries_limit)
    end

    def prepare
      []
    end

    def execute(unit)
      raise NotImplementedError
    end

    def execution_failure(unit)
      {}
    end

    def wrapup
      {}
    end

    def run
      success, total = 0, 0
      begin
        data = prepare
        data.each do |unit|
          total += 1
          begin
            execute(unit)
            success += 1
          rescue Exception => e
            failure(execution_failure(unit))
          end
        end
      rescue Exception => e
        failure({})
      ensure
        @current_run.processed_details = wrapup.merge({
          :success => success,
          :total => total
        }).to_yaml
        @current_run.save!
      end
    end

    def failure(failure_details, args = {})
      args = {:task_failure_id => nil, :status => 'failure'}.merge(args)
      if args[:task_failure_id].nil?
        Melinis::TaskFailure.create!({
          :task_processing_id => @current_run.id,
          :task_id => @task.id,
          :failure_details => failure_details.to_yaml,
          :status => 'failure'
        })
      else
        task_failure = Melinis::TaskFailure.find_by_id(args[:task_failure_id])
        task_failure.increment(:retry_count).update_attributes({
          :failure_details => failure_details.to_yaml,
          :status => args[:status]
        })
      end
    end
  end
end
