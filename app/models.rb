class User < Sequel::Model
  one_to_many :associations
end

class Association < Sequel::Model
  many_to_one :user
end
