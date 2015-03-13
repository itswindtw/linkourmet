class User < Sequel::Model
  one_to_many :social_services, conditions: { active: true }

  %w{facebook twitter}.each do |provider|
    one_to_one :"#{provider}_service", class: :SocialService, conditions: { provider: provider }
  end
end

class SocialService < Sequel::Model
  many_to_one :user
end
