module FixtureHelpers
  def fixture_path(filename)
    "#{Dir.pwd}/spec/fixtures/#{filename}"
  end

  def fixture_json(filename)
    JSON.parse(File.read(fixture_path(filename)))
  end
end

RSpec.configure do |c|
  c.include FixtureHelpers
end
