Rake::Task["spec"].clear if Rake::Task.task_defined?('spec')

desc "GITLAB | Run specs"
task :spec do
  cmds = [
    %W(rake gitlab:setup),
    %W(rspec spec),
  ]

  cmds.each do |cmd|
    system({'RAILS_ENV' => 'test', 'force' => 'yes'}, *cmd)
    raise "#{cmd} failed!" unless $?.exitstatus.zero?
  end
end
