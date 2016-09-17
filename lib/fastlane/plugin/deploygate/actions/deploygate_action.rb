module Fastlane
  module Actions
    module SharedValues
      DEPLOYGATE_URL = :DEPLOYGATE_URL
      DEPLOYGATE_REVISION = :DEPLOYGATE_REVISION # auto increment revision number
      DEPLOYGATE_APP_INFO = :DEPLOYGATE_APP_INFO # contains app revision, bundle identifier, etc.
    end

    class DeploygateAction < Action
      DEPLOYGATE_URL_BASE = 'https://deploygate.com'.freeze

      def self.is_supported?(platform)
        [:android].include? platform
      end

      def self.run
        uploader(options).upload(options)
      end

      def self.uploader
        if options[:apk]
          APKUploader.new
        else
          raise
        end
      end
      private_class_method :uploader

      class UploaderBase
        def upload
          # Available options: https://deploygate.com/docs/api
          UI.success("Starting with #{binary_name} upload to DeployGate... this could take some time ⏳")

          response = perform_upload(options)

          return if Helper.is_test?

          if parse_response(response)
            UI.message("DeployGate URL: #{Actions.lane_context[SharedValues::DEPLOYGATE_URL]}")
            UI.success("Build successfully uploaded to DeployGate as revision \##{Actions.lane_context[SharedValues::DEPLOYGATE_REVISION]}!")
          else
            UI.user_error!("Error when trying to upload #{binary_name} to DeployGate")
          end
        end

        def self.binary_name
          raise 'must be override'
        end

        def parse_response(response)
          if response && response.key?('error')

            if response['error']
              UI.error("Error uploading to DeployGate: #{response['message']}")
              help_message(response)
              return
            else
              res = response['results']
              url = DEPLOYGATE_URL_BASE + res['path']

              Actions.lane_context[SharedValues::DEPLOYGATE_URL] = url
              Actions.lane_context[SharedValues::DEPLOYGATE_REVISION] = res['revision']
              Actions.lane_context[SharedValues::DEPLOYGATE_APP_INFO] = res
            end
          else
            UI.error("Error uploading to DeployGate: #{response}")
            return
          end
          true
        end

        def help_message(response)
          message =
            case response['message']
            when 'you are not authenticated'
              'Invalid API Token specified.'
            when 'application create error: permit'
              'Access denied: May be trying to upload to wrong user or updating app you join as a tester?'
            when 'application create error: limit'
              'Plan limit: You have reached to the limit of current plan or your plan was expired.'
            end
          UI.error(message) if message
        end
      end

      class APKUploader < UploaderBase
        def binary_name
          'apk'
        end

        def perform_upload(options)
          require 'net/http/post/multipart'

          url = URI.parse("https://deploygate.com/api/users/#{options[:user]}/apps")
          apk = File.new(options[:apk])
          file = UploadIO.new(apk, 'application/octet-stream', File.basename(apk.path))

          req = Net::HTTP::Post::Multipart.new(url.path, file: file, token: options[:api_token])
          res = Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
            http.request(req)
          end

          JSON.parse(res.body)
        end
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :api_token,
                                       env_name: 'DEPLOYGATE_API_TOKEN',
                                       description: 'Deploygate API Token',
                                       verify_block: proc do |value|
                                         UI.user_error!("No API Token for DeployGate given, pass using `api_token: 'token'`") unless value.to_s.length > 0
                                       end),
          FastlaneCore::ConfigItem.new(key: :user,
                                       env_name: 'DEPLOYGATE_USER',
                                       description: 'Target username or organization name',
                                       verify_block: proc do |value|
                                         UI.user_error!("No User for app given, pass using `user: 'user'`") unless value.to_s.length > 0
                                       end),
          FastlaneCore::ConfigItem.new(key: :ipa,
                                       env_name: 'DEPLOYGATE_IPA_PATH',
                                       description: 'Path to your IPA file. Optional if you use the `gym` or `xcodebuild` action',
                                       default_value: Actions.lane_context[SharedValues::IPA_OUTPUT_PATH],
                                       optional: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("Couldn't find ipa file at path '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :apk,
                                       env_name: 'DEPLOYGATE_APK_PATH',
                                       description: 'Path to your APK file',
                                       default_value: Actions.lane_context[SharedValues::GRADLE_APK_OUTPUT_PATH],
                                       optional: true,
                                       verify_block: proc do |value|
                                         UI.user_error!("Couldn't find apk file at path '#{value}'") unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :message,
                                       env_name: 'DEPLOYGATE_MESSAGE',
                                       description: 'Release Notes',
                                       default_value: 'No changelog provided'),
          FastlaneCore::ConfigItem.new(key: :distribution_key,
                                       optional: true,
                                       env_name: 'DEPLOYGATE_DISTRIBUTION_KEY',
                                       description: 'Target Distribution Key'),
          FastlaneCore::ConfigItem.new(key: :release_note,
                                       optional: true,
                                       env_name: 'DEPLOYGATE_RELEASE_NOTE',
                                       description: 'Release note for distribution page')
        ]
      end

      def self.output
        [
          ['DEPLOYGATE_URL', 'URL of the newly uploaded build'],
          ['DEPLOYGATE_REVISION', 'auto incremented revision number'],
          ['DEPLOYGATE_APP_INFO', 'Contains app revision, bundle identifier, etc.']
        ]
      end

      def self.description
        'Upload a new build to DeployGate'
      end

      def self.authors
        ['tnj', 'tomorrowkey']
      end
    end
  end
end
