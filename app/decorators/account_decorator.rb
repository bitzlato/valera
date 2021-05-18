# frozen_string_literal: true

class AccountDecorator < ApplicationDecorator
  delegate_all

  def self.table_columns
    %i[id upstream client balances]
  end

  def upstream
    h.link_to object.upstream, h.upstream_path(object.upstream)
  end

  def client
    return h.middot if object.client.nil?
    object.client.class
  end
end
