# frozen_string_literal: true

module Finders
  def all
    set = God.instance.send(self.name.underscore.pluralize)
    set.is_a?(Hash) ? set.values : set
  end

  def find(id)
    raise 'ID must present' if id.blank?

    (all.find { |u| u.id.to_s == id.to_s } || raise("No found #{name}##{id}"))
      .reload
  end
end
