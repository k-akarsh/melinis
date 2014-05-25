module Melinis
  class SetupError < StandardError
    def to_s
      "Call the 'setup' class method first to create the task"
    end
  end

  class NoNameError < SetupError
    def to_s
      ":name not defined in 'properties' class method"
    end
  end
end
