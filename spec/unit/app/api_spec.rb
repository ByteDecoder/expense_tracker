# frozen_string_literal: true

require_relative '../../../app/api'
require 'rack/test'
require 'ox'
require 'byebug'

module ExpenseTracker
  RSpec.describe API do
    include Rack::Test::Methods

    def app
      API.new(ledger: ledger)
    end

    def json_parsed
      JSON.parse(last_response.body)
    end

    def xml_parsed
      Ox.parse_obj(last_response.body)
    end

    let(:ledger) { instance_double('ExpenseTracker::Ledger') }

    describe 'POST /expenses' do
      context 'when the expense is successfully recorded' do
        let(:expense) do
          {
            'payee' => 'Starbucks',
            'amount' => 5.75,
            'date' => '2017-06-10'
          }
        end

        before do
          allow(ledger).to receive(:record).with(expense)
                                           .and_return(RecordResult.new(true, 417, nil))
        end

        context 'with JSON format' do
          it 'returns the expense id with HTTP 200 (OK)' do
            header 'Content-Type', 'application/json'
            post '/expenses', JSON.generate(expense)
            expect(json_parsed).to include('expense_id' => 417)
            expect(last_response.headers['Content-Type']).to eq('application/json')
            expect(last_response.status).to eq(200)
          end
        end

        context 'with XML format' do
          it 'returns the expense id and HTTP 200 (OK)' do
            header 'Content-Type', 'text/xml'
            post '/expenses', Ox.dump(expense)
            expect(xml_parsed).to include('expense_id' => 417)
            expect(last_response.headers['Content-Type']).to include('text/xml')
            expect(last_response.status).to eq(200)
          end
        end
      end

      context 'when the expense fails validation' do
        let(:expense) { { 'some' => 'data' } }

        before do
          allow(ledger).to receive(:record)
            .with(expense)
            .and_return(RecordResult.new(false, 417, 'Expense incomplete'))
        end

        it 'returns an error message' do
          post '/expenses', JSON.generate(expense)
          expect(json_parsed).to include('error' => 'Expense incomplete')
        end

        it 'responds with a 422 (Unprocessable entity)' do
          post '/expenses', JSON.generate(expense)
          expect(last_response.status).to eq(422)
        end
      end
    end

    describe 'GET /expenses/:date' do
      context 'when expenses exist on the given date' do
        before do
          allow(ledger).to receive(:expenses_on).with('2017-06-12')
                                                .and_return(%w[expense_1 expense_2])
        end

        it 'returns the expense records as JSON' do
          get 'expenses/2017-06-12'
          expect(json_parsed).to eq(%w[expense_1 expense_2])
        end

        it 'respond with a 200 (OK)' do
          get '/expenses/2017-06-12'
          expect(last_response.status).to eq(200)
        end
      end

      context 'when there are no expenses on the given date' do
        before do
          allow(ledger).to receive(:expenses_on).with('2017-06-12')
                                                .and_return([])
        end

        it 'returns an empty array as JSON' do
          get 'expenses/2017-06-12'
          expect(json_parsed).to eq([])
        end

        it 'respond with a 200 (OK)' do
          get 'expenses/2017-06-12'
          expect(last_response.status).to eq(200)
        end
      end
    end
  end
end
