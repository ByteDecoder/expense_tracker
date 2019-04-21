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
      if request.media_type == 'application/json'
        expense = JSON.parse(request.body.read)
      elsif request.media_type == 'text/xml'
        expense = Ox.parse_obj(request.body.read)
      end

      result = @ledger.record(expense)

      if result.success?
        case request.media_type
        when 'application/json'
          headers['Content-Type'] = 'application/json'
          JSON.generate('expense_id' => result.expense_id)
        when 'text/xml'
          headers['Content-Type'] = 'text/xml'
          Ox.dump({'expense_id' => result.expense_id})
        end
      else
        case request.media_type
        when 'application/json'
          headers['Content-Type'] = 'application/json'
          status 422
          JSON.generate('error' => result.error_message)
        when 'text/xml'
          status 422
          headers['Content-Type'] = 'text/xml'
        end
      end
    end

    get '/expenses/:date' do
      JSON.generate(@ledger.expenses_on(params[:date]))
    end
  end
end
