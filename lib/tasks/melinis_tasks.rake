namespace :melinis do
  desc "Usage -> rake RAILS_ENV=development melinis:run_task"
  task :run, [:task_name] => :environment do |t, args|
    tname = args.task_name
    require "./lib/%s.rb" % [tname.underscore]
    tname.constantize.new.run
  end
end
