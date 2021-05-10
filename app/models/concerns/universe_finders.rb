# frozen_string_literal: true

module UniverseFinders
  def all
    God.instance.universes
  end

  def find(id)
    raise 'ID must present' if id.blank?

    all.find { |u| u.id == id }.reload
  end
end
