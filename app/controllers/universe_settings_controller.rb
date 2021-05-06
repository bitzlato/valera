class UniverseSettingsController < ApplicationController
  def update
    universe = Universe.find params[:id]

    respond_to do |format|
      if universe.settings.update_attributes params.require(:universe_settings).permit!
        format.html { redirect_to(universe_settings, :notice => 'Settings was successfully updated.') }
        format.json { respond_with_bip(universe.settings) }
      else
        format.html { render :action => "edit" }
        format.json { respond_with_bip(universe.settings) }
      end
    end
  end
end
