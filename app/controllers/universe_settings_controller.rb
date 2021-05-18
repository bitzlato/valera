# frozen_string_literal: true

class StrategySettingsController < ApplicationController
  def update
    strategy = Strategy.find params[:id]

    respond_to do |format|
      if strategy.settings.update_attributes params.require(:strategy_settings).permit!
        format.html { redirect_to(strategy_settings, notice: 'Settings was successfully updated.') }
        format.json { respond_with_bip(strategy.settings) }
      else
        format.html { render action: 'edit' }
        format.json { respond_with_bip(strategy.settings) }
      end
    end
  end
end
