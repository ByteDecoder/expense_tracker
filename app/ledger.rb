# frozen_string_literal: true

require_relative '../config/sequel'

module ExpenseTracker
  RecordResult = Struct.new(:success?, :expense_id, :error_message)

  class Ledger
    def record(expense)
      unless valid_expense?(expense)
        message = invalid_messages(expense)
        return RecordResult.new(false, nil, message)
      end

      DB[:expenses].insert(expense)
      id = DB[:expenses].max(:id)
      RecordResult.new(true, id, nil)
    end

    def expenses_on(date)
      DB[:expenses].where(date: date).all
    end

    private

    def valid_expense?(expense)
      expense.key?('payee') && expense.key?('amount') && expense.key?('date')
    end

    def invalid_messages(expense)
      messages = []
      messages << invalid_expense_key('payee', expense)
      messages << invalid_expense_key('amount', expense)
      messages << invalid_expense_key('date', expense)
    end

    def invalid_expense_key(key, expense)
      "Invalid expense: `#{key}` is required" unless expense.key?(key)
    end
  end
end
