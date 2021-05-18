# frozen_string_literal: true

class StrategySettingsController < ApplicationController
  def update
    strategy = Strategy.find params[:id]

    respond_to do |format|
      format.html do
        if strategy.settings.update_attributes params.require(:strategy_settings).permit!
          redirect_to(strategy_settings, notice: 'Settings was successfully updated.')
        else
          render action: 'edit'
        end
      end
      format.json { respond_with_bip(strategy.settings) }
    end
  end
end
