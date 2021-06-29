# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

module Finders
  def all
    scope.each(&:reload)
  end

  def scope
    set = God.instance.send(name.underscore.pluralize)
    set.is_a?(Hash) ? set.values : set
  end

  def find(id)
    raise 'ID must present' if id.blank?

    find_by id: id
  end

  def find!(id)
    raise 'ID must present' if id.blank?

    find_by! id: id
  end

  def find_by(attrs)
    scope.find do |record|
      attrs.map { |key, value| record.send(key).to_param == value.to_param }.all? true
    end.try(&:reload)
  end

  def find_by!(attrs)
    find_by(attrs) || raise("No found #{name} with #{attrs}")
  end
end
