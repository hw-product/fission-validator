describe 'Fission::Validator::Github' do
  before do
    @cwd = File.dirname(__FILE__)
    Carnivore::Config.configure(:config_path => File.join(@cwd, 'config/github.json'))
    @runner = Thread.new do
      require 'fission/runner'
    end
    source_wait(:setup)
  end

  after do
    Carnivore::Supervisor.supervisor.terminate
    @runner.terminate
  end

  it 'should add account to payload' do
    Carnivore::Supervisor.supervisor[:validator].transmit(payload_for(:github, :nest => :github))
    source_wait{ !MessageStore.messages.empty? }
    result = MessageStore.messages.pop
    result.wont_be_nil
    Carnivore::Utils.retrieve(result, :data, :account).wont_be_nil
  end

  it 'should set error state if payload is invalid' do
    Carnivore::Supervisor.supervisor[:validator].transmit(Fission::Utils.new_payload(:fubar, {:github => {:bad => :state}}))
    source_wait{ !MessageStore.messages.empty? }
    result = MessageStore.messages.pop
    result.wont_be_nil
    Carnivore::Utils.retrieve(result, :data, :account).must_be_nil
  end

end
