module Melinis
  class TaskProcessing < ActiveRecord::Base
    belongs_to :task
    has_many :task_failures

    def data
      YAML.load(processed_details)
    end
  end
end
