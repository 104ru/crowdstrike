# Get the status of crowdstrike's falcon sensor

Facter.add(:falcon_sensor) do
  confine kernel: :Linux
  confine do
    File.exist?('/opt/CrowdStrike/falconctl')
  end

  setcode do
    # invoke falconctl to get the current settings
    get_string = "/opt/CrowdStrike/falconctl -g --aid --apd --aph --app \
      --rfm-state --rfm-reason --version --tags"

    # format in which falconctl outputs data
    pattern = %r{^aid(?:=|\sis\s)"?(?<agent_id>not\sset|[a-f0-9]*)"?,\s
      apd(?:=|\sis\s)(?<proxy_disable>not\sset|TRUE|FALSE),\s
      aph(?:=|\sis\s)(?<proxy_host>not\sset|[^,]+),\s
      app(?:=|\sis\s)(?<proxy_port>not\sset|[^,]+),\s
      rfm-state(?:=|\sis\s)(?<reduced_functionality_mode>not\sset|true|false),\s
      rfm-reason(?:=|\sis\s)(?<reduced_functionality_reason>not\sset|[^,]+),\s
      (code=0x[A-F0-9]+,\s)?
      version\s=\s(?<version>[\d\.]+)
      (?:Sensor\sgrouping\s)?tags(?:=|\sare\s)(?<tags>.*),\s*$}x

    falcon_says = Facter::Util::Resolution.exec(get_string)

    if falcon_says
      match_data = pattern.match(falcon_says)
      if match_data
        falcon_facts = Hash[match_data.names.zip(match_data.captures)]

        # convert the values to the appropriate types
        falcon_facts.each do |key, value|
          falcon_facts[key] = case value.downcase
                              when 'true'
                                true
                              when 'false'
                                false
                              when 'not set'
                                nil
                              else
                                if key == 'tags'
                                  value.split(',')
                                else
                                  value
                                end
                              end
        end
      else
        nil
      end
      # do not include unset values in the fact
      falcon_facts.reject { |_, value| value.nil? }
    else
      nil
    end
  end
end
