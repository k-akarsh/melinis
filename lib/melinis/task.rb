module Melinis
  class Task
    attr_reader :last_run, :failures, :logger, :current_run

    # Returns a hash with the following keys:
    #
    # * name: Name of the task - Required
    # * description: Task Description
    # * file_path: File Path
    # * command: Command that starts the execution of the task
    # * individual_retries_limit: Maximum number of times each individual failed entry must be retried
    # * bulk_retries_limit: Maximum number of consecutive failed entries that will halt the task execution
    def self.properties
      raise NotImplementedError
    end

    def self.setup(first_run_data = {})
      options = {
        :description => '',
        :file_path => '',
        :command => '',
        :individual_retries_limit => 1,
        :bulk_retries_limit => 1
      }.merge(self.properties)
      task_name = options.delete(:name)
      raise NoNameError unless task_name
      task = Melinis::TaskList.find_or_initialize_by(name: task_name)
      task.update_attributes(options)

      unless first_run_data.blank?
        current_run = Melinis::TaskProcessing.create!({
          :task_id => task.id,
          :processed_details => first_run_data.to_yaml
        })
      end
    end

    def initialize
      task_name = self.class.properties[:name]
      raise NoNameError unless task_name

      @task = Melinis::TaskList.find_by_name(task_name)
      raise SetupError unless @task

      @logger = Logger.new("log/%s.log" % [task_name.snakecase])
      @last_run = @task.task_processings.last

      # 'failures' returns the list of records that are still in failed state and have individual retries left
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
        success_info = { :success_count => success,
                         :total => total }
        wrapup_info = wrapup
        final_wrapup = wrapup_info.is_a?(Hash) ? wrapup_info.merge(success_info) : success_info
        @current_run.processed_details = final_wrapup.to_yaml
        @current_run.save!
      end
    end

    # * failure_details: A hash that will keep track of the records being processed
    #
    # Optional Parameters that can be passed:
    # * task_failure_id: Id of the failed record in case an earlier failed record is being processed again
    # * status: 'failure' in case a record fails either for the first time or in subsequent attempts.
    #            Or 'success' in case an earlier failed record succeeds in the next attempt.
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
