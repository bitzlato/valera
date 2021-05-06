module UniverseFinders
  def all
    God.instance.universes
  end

  def find(id)
    all.find { |u| u.id == id }.reload
  end
end
