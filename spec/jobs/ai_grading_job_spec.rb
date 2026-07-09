require 'rails_helper'

RSpec.describe AiGradingJob, type: :job do
  it 'delega a correção para o AiGradingService' do
    attempt = create(:quiz_attempt)
    service = instance_double(AiGradingService, call: nil)
    allow(AiGradingService).to receive(:new).with(attempt).and_return(service)

    described_class.perform_now(attempt.id)

    expect(service).to have_received(:call)
  end

  it 'não explode se a tentativa foi apagada antes do job rodar' do
    expect { described_class.perform_now(-1) }.not_to raise_error
  end
end
