# frozen_string_literal: true

require 'sinatra/base'
require 'json'
require 'byebug'

module ExpenseTracker
  class API < Sinatra::Base
    def initializate(legder: Legder.new)
      @legder = legder
      super()
    end

    post '/expenses' do
      expense = JSON.parse(request.body.read)
      result = @legder.record(expense)
      JSON.generate('expense_id' => result.expense_id)
    end

    get '/expenses/:date' do
      JSON.generate([])
    end
  end
end
