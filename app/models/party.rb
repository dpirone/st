# == Schema Information
# Schema version: 20090422073021
#
# Table name: users
#
#  id                        :integer(4)      not null, primary key
#  login                     :string(255)
#  email                     :string(255)
#  description               :text
#  avatar_id                 :integer(4)
#  crypted_password          :string(40)
#  salt                      :string(40)
#  created_at                :datetime
#  updated_at                :datetime
#  remember_token            :string(255)
#  remember_token_expires_at :datetime
#  stylesheet                :text
#  view_count                :integer(4)      default(0)
#  vendor                    :boolean(1)
#  activation_code           :string(40)
#  activated_at              :datetime
#  state_id                  :integer(4)
#  metro_area_id             :integer(4)
#  login_slug                :string(255)
#  notify_comments           :boolean(1)      default(TRUE)
#  notify_friend_requests    :boolean(1)      default(TRUE)
#  notify_community_news     :boolean(1)      default(TRUE)
#  country_id                :integer(4)
#  featured_writer           :boolean(1)
#  last_login_at             :datetime
#  zip                       :string(255)
#  birthday                  :date
#  gender                    :string(255)
#  profile_public            :boolean(1)      default(TRUE)
#  activities_count          :integer(4)      default(0)
#  sb_posts_count            :integer(4)      default(0)
#  sb_last_seen_at           :datetime
#  role_id                   :integer(4)
#  type                      :string(255)
#  requested_match_cents     :integer(4)
#  asset_type_id             :integer(4)
#  organization_id           :integer(4)
#  first_name                :string(255)
#  last_name                 :string(255)
#

class Party < User
  belongs_to :organization
  belongs_to :asset_type

  has_many :members, :class_name => 'Saver', :foreign_key => :organization_id  

  composed_of :requested_match_amount, :class_name => "Money", :mapping => [%w(requested_match_cents cents)], :converter => Proc.new { |value| value.to_money }

  def display_name
    if profile_public
      first_name
    else
      'Anonymous'
    end 
  end

  def to_param
    self.id.to_s
  end

  def self.build_conditions_for_search(search)
    cond = Caboose::EZ::Condition.new

    cond.append ['activated_at IS NOT NULL ']
    if search['country_id'] && !(search['metro_area_id'] || search['state_id'])
      cond.append ['country_id = ?', search['country_id'].to_s]
    end
    if search['state_id'] && !search['metro_area_id']
      cond.append ['state_id = ?', search['state_id'].to_s]
    end
    if search['metro_area_id']
      cond.append ['metro_area_id = ?', search['metro_area_id'].to_s]
    end
    if search['login']
      cond.login =~ "%#{search['login']}%"
    end
    if search['vendor']
      cond.vendor == true
    end
    if search['description']
      cond.description =~ "%#{search['description']}%"
    end
    if search['asset_type_id']
      cond.append ['asset_type_id = ?', search['asset_type_id']]
    end
    cond
  end

  def self.find_country_and_state_from_search_params(search)
    country = Country.find(search['country_id']) if !search['country_id'].blank?
    state = State.find(search['state_id']) if !search['state_id'].blank?
    metro_area = MetroArea.find(search['metro_area_id']) if !search['metro_area_id'].blank?
    asset_type = AssetType.find(search['asset_type_id']) if !search['asset_type_id'].blank?

    if metro_area && metro_area.country
      country ||= metro_area.country
      state ||= metro_area.state
      search['country_id'] = metro_area.country.id if metro_area.country
      search['state_id'] = metro_area.state.id if metro_area.state
    end
    search['asset_type_id'] = asset_type.id if asset_type

    states = country ? country.states.sort_by{|s| s.name} : []
    if states.any?
      metro_areas = state ? state.metro_areas.all(:order => "name") : []
    else
      metro_areas = country ? country.metro_areas : []
    end
    asset_types = AssetType.find(:all)

    return [metro_areas, states, asset_types]
  end

  def self.paginated_users_conditions_with_search(params)
    search = prepare_params_for_search(params)

    metro_areas, states, asset_types = find_country_and_state_from_search_params(search)

    cond = build_conditions_for_search(search)
    return cond, search, metro_areas, states, asset_types
  end

  #
  # Overload login ==> email
  # 
  def login=(login)
    becomes(User).email = login
    super
  end
  
  # Only allow email manipulation via login accessor
  def email=(email)
    raise "email lockdown: To set email attribute call login"
  end

  def to_label
    "#{first_name} (#{type})"
  end  
end
