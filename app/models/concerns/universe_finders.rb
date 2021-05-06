module UniverseFinders
  def all
    God.instance.universes
  end

  def find(id)
    all.find { |u| u.id == id }
  end
end
