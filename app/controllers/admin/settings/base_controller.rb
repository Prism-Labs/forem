module Admin
  module Settings
    class BaseController < Admin::ApplicationController
      def create
        errors = upsert_config(settings_params)

        if errors.none?
          Audit::Logger.log(:internal, current_user, params.dup)
          redirect_to admin_config_path, notice: "Site configuration was successfully updated."
        else
          redirect_to admin_config_path, alert: "😭 #{errors.to_sentence}"
        end
      end

      private

      def upsert_config(configs)
        errors = []
        configs.each do |key, value|
          next if value.blank?

          Object.const_get(settings_class).public_send("#{key}=", value)
        rescue ActiveRecord::RecordInvalid => e
          errors << e.message
          next
        end

        errors
      end

      def settings_params
        params
          .require(:"settings_#{settings_class.demodulize.underscore}")
          .permit(*Object.const_get(settings_class).keys)
      end

      def settings_class
        @settings_class ||= self.class.name.gsub(/(Admin::|Controller)/, "").singularize
      end
    end
  end
end
