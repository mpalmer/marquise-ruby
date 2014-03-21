guard 'spork', :rspec_env => { 'RACK_ENV' => 'test' } do
  watch('Gemfile')
  watch('spec/spec_helper.rb') { :rspec }
end

guard 'rspec',
      :cmd          => "rspec --drb",
      :all_on_start => true do
  watch('lib/marquise/ffi.rb')
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| Dir["spec/#{m[1].gsub('/', '_')}*_spec.rb"] }
end
