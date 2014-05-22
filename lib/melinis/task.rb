module Melinis
  class Task
    attr_reader :last_run, :failures, :logger, :current_run

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

      @logger = Logger.new("log/%s.log" % [task_name.snakecase])
      @last_run = @task.task_processings.last
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
        @current_run = Melinis::TaskProcessing.create!({:task_id => @task.id})
        logger.info { "Starting run #%d" % [@current_run.id] }
        data = prepare
        total = data.size
        data.each do |unit|
          begin
            execute(unit)
            success += 1
          rescue Exception => e
            failure(execution_failure(unit), {:exception => e})
            logger.error { e }
          end
        end
      rescue Exception => e
        failure({}, {:exception => e})
        logger.error { e }
      ensure
        @current_run.processed_details = wrapup.merge({
          :success_count => success,
          :total => total
        }).to_yaml
        @current_run.save!
      end
    end

    def failure(failure_details, args = {})
      task_failure_id = args[:task_failure_id]
      data = failure_details.merge({:exception => args[:exception].to_s})
      attrs = {
        :failure_details => data.to_yaml,
        :status => args[:status] || 'failure'
      }
      if task_failure_id.nil?
        Melinis::TaskFailure.create!({
          :task_processing_id => @current_run.id,
          :task_id => @task.id
        }.merge(attrs))
      else
        task_failure = Melinis::TaskFailure.find_by_id(task_failure_id)
        task_failure.increment(:retry_count).update_attributes(attrs)
      end
    end
  end
end
