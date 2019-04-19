# frozen_string_literal: true

class API < Sinatra::Base
  def initializate(legder:)
    @legder = legder
    super()
  end

  app = API.new(legder: Legder.new)
end
