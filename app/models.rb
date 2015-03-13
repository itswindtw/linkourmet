class User < Sequel::Model
  one_to_many :social_services, conditions: { active: true }

  %w{facebook twitter}.each do |provider|
    one_to_one :"#{provider}_service", class: :SocialService, conditions: { provider: provider }
  end

  def increment_active_workers!
    self.values[:active_workers] += 1
    self.save(columns: [:active_workers])
  end

  def decrement_active_workers!
    self.values[:active_workers] -= 1
    if self.values[:active_workers] >= 0
      self.save(columns: [:active_workers])
    end
  end
end

class SocialService < Sequel::Model
  many_to_one :user
end
