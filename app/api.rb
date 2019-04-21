# frozen_string_literal: true

require 'sinatra/base'
require 'json'
require_relative 'ledger'

module ExpenseTracker
  class API < Sinatra::Base
    def initialize(ledger: Ledger.new)
      @ledger = ledger
      super()
    end

    post '/expenses' do
      return render_unsupported_format unless valid_mime_type?

      expense = set_expense
      return render_payload_unsupported_format if expense.nil?

      result = @ledger.record(expense)
      return render_success(result, request.media_type) if result.success?

      render_unprocessable_entity(result.error_message, request.media_type)
    end

    get '/expenses/:date' do
      JSON.generate(@ledger.expenses_on(params[:date]))
    end

    private

    def set_expense
      return JSON.parse(request.body.read) if request.media_type == 'application/json'

      Ox.parse_obj(request.body.read)
    rescue StandardError
      nil
    end

    def valid_mime_type?
      request.media_type == 'application/json' || request.media_type == 'text/xml'
    end

    def render_success(result, mime_type = 'application/json')
      status 200
      headers['Content-Type'] = mime_type
      return JSON.generate('expense_id' => result.expense_id) if mime_type == 'application/json'

      Ox.dump('expense_id' => result.expense_id)
    end

    def render_unsupported_format
      render_unprocessable_entity('Unsupported format')
    end

    def render_payload_unsupported_format
      render_unprocessable_entity('Expense payload does not match the format advertised')
    end

    def render_unprocessable_entity(error_message, mime_type = 'application/json')
      status 422
      headers['Content-Type'] = mime_type
      return JSON.generate('error' => error_message) if mime_type == 'application/json'

      Ox.dump('error' => error_message)
    end
  end
end
