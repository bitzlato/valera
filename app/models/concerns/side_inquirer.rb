module SideInquirer
  extend ActiveSupport::Concern

  SIDES = %i[ask bid].freeze

  included do
    validates :side, presence: true, inclusion: { in: SIDES + SIDES.map(&:to_s) }
  end

  def side?(asked_side)
    asked_side = asked_side.to_s

    raise "Unknown side #{asked_side}" unless SIDES.map(&:to_s).include? asked_side

    asked_side == side
  end

  def bid?
    side? :bid
  end

  def ask?
    side? :ask
  end
end
