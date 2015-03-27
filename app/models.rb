class User < Sequel::Model
  one_to_many :social_services, conditions: { active: true }

  %w(facebook twitter).each do |provider|
    one_to_one :"#{provider}_service", class: :SocialService, conditions: { provider: provider }
  end

  def increment_active_workers!
    values[:active_workers] += 1
    save(columns: [:active_workers])
  end

  def decrement_active_workers!
    return unless values[:active_workers] >= 1

    values[:active_workers] -= 1
    save(columns: [:active_workers])
  end
end

class SocialService < Sequel::Model
  many_to_one :user
end
