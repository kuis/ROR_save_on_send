module NameLocalization
  extend ActiveSupport::Concern

  def name
    if I18n.locale == :en
      super
    else
      send("name_#{I18n.locale}")
    end
  end
end
