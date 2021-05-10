module UpdatePeatioBalance
  private

  def find_balance(balances, currency)
    data = balances.find { |b| b['currency'] == currency }
    return data['balance'].to_d if data.has_key? 'balance'
  end

  def update_peatio_balances!
    balances = peatio_client.account_balances
    state.assign_attributes(
      :peatio_base_balance => find_balance(balances, market.base.downcase),
      :peatio_quote_balance => find_balance(balances, market.quote.downcase)
    )
  end
end
