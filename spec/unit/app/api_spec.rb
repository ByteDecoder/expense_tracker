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
    let(:expense) do
      {
        'payee' => 'Starbucks',
        'amount' => 5.75,
        'date' => '2017-06-10'
      }
    end

    def assert_error_expense_response(error_message, mime_type = 'application/json')
      expect(json_parsed).to include('error' => error_message) if mime_type == 'application/json'
      expect(xml_parsed).to include('error' => error_message) if mime_type == 'text/xml'
      expect(last_response.headers['Content-Type']).to eq(mime_type)
      expect(last_response.status).to eq(422)
    end

    def assert_expense_response(expense_id, mime_type = 'application/json')
      expect(json_parsed).to include('expense_id' => expense_id) if mime_type == 'application/json'
      expect(xml_parsed).to include('expense_id' => expense_id) if mime_type == 'text/xml'
      expect(last_response.headers['Content-Type']).to eq(mime_type)
      expect(last_response.status).to eq(200)
    end

    describe 'POST /expenses' do
      context 'when the expense is successfully recorded' do
        before do
          allow(ledger).to receive(:record).with(expense)
                                           .and_return(RecordResult.new(true, 417, nil))
        end

        context 'with supported format but invalid expense payload format' do
          it 'returns an error message and responds with a 422 (Unprocessable entity)' do
            header 'Content-Type', 'application/json'
            post '/expenses', Ox.dump(expense)
            assert_error_expense_response('Expense payload does not match the format advertised')
          end
        end

        context 'with Unsupported format' do
          it 'returns an error message and responds with a 422 (Unprocessable entity)' do
            header 'Content-Type', 'application/json203'
            post '/expenses', JSON.generate(expense)
            assert_error_expense_response('Unsupported format')
          end
        end

        context 'with JSON format' do
          it 'returns the expense id with HTTP 200 (OK)' do
            header 'Content-Type', 'application/json'
            post '/expenses', JSON.generate(expense)
            assert_expense_response(417)
          end
        end

        context 'with XML format' do
          it 'returns the expense id and HTTP 200 (OK)' do
            header 'Content-Type', 'text/xml'
            post '/expenses', Ox.dump(expense)
            assert_expense_response(417, 'text/xml')
          end
        end
      end

      context 'when the expense fails validation' do
        before do
          allow(ledger).to receive(:record)
            .with(expense)
            .and_return(RecordResult.new(false, 417, 'Expense incomplete'))
        end

        context 'with JSON format' do
          it 'returns an error message and responds with a 422 (Unprocessable entity)' do
            header 'Content-Type', 'application/json'
            post '/expenses', JSON.generate(expense)
            assert_error_expense_response('Expense incomplete')
          end
        end

        context 'with XML format' do
          it 'returns an error message and responds with a 422 (Unprocessable entity)' do
            header 'Content-Type', 'text/xml'
            post '/expenses', Ox.dump(expense)
            assert_error_expense_response('Expense incomplete', 'text/xml')
          end
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
