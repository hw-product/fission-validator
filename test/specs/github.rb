
describe 'Fission::Validator::Github' do
  before do
    @cwd = File.dirname(__FILE__)
    Carnivore::Config.configure(:config_path => File.join(@cwd, 'config/github.json'))
    @runner = Thread.new do
      require 'fission/runner'
    end
    source_wait
  end

  after do
    @runner.terminate
  end

  it 'should add user to payload' do
    Celluloid::Actor[:validator].transmit(payload_for(:github, :nest => :github))
    source_wait
    result = MessageStore.messages.pop
    result[:data][:account].wont_be_nil
  end
end
