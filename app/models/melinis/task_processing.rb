module Melinis
  class TaskProcessing < ActiveRecord::Base
    belongs_to :task
  end
end
