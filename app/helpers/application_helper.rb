# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def find_pledge
    if session[:pledge_id].nil?
      pledge = Pledge.create!
      session[:pledge_id] = pledge.id
    end
    pledge = Pledge.find(session[:pledge_id])
  end

  def select_pledge_amounts_cents_values(max=30000)
    pledge_amounts = Array.new
    2500.step(max, 2500) do |amt|
      # Map amount string (in dollars) to amount integer (in cents)
      pledge_amounts << [(:donation_amount.l :amount => amt/100), amt]
    end
    pledge_amounts << [(:donation_amount.l :amount => max/100), max] if pledge_amounts.last[1] < max
    pledge_amounts
  end

  def select_savetogether_amounts_cents_values
    factors = [0.1, 0.15, 0.2, 0.25, 0.3, 0.4, 0.5]
    opts = [[:none.l, 0]]
    total_cents = 0
    st_ask_cents = 0
    storg_id = Organization.find_savetogether_org.id
    find_pledge.donations.each do |d|
      unless d.to_user_id == storg_id
        total_cents = total_cents + d.cents
      else
        st_ask_cents = d.cents
      end  
    end  

    factors.each_with_index do |f, i|
      opts << savetogether_donation_menu_entry(factored_cents(total_cents, f), percent_from_factor(f))
    end
    
    if (st_ask_cents > 0) then
      opts << savetogether_donation_menu_entry(st_ask_cents, percent_from_factor(st_ask_cents.to_f/total_cents.to_f))
      opts.uniq!
      opts = opts.sort{|this, that| this[1] <=> that[1]}
    end
        
    return opts
  end

private
  def savetogether_donation_menu_entry(cents, percent)
    [:donation_amount_to_st.l(:amount => Money.new(cents).format(:html), :percent => "%-.1f" % percent), cents]
  end

  def factored_cents(cents, factor)
    (cents.to_f * factor).to_i
  end
  
  def percent_from_factor(factor)
    factor * 100.to_f
  end

end
