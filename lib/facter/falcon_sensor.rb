# Get the status of crowdstrike's falcon sensor

Facter.add(:falcon_sensor) do
  confine kernel: :Linux
  confine do
    File.executable?('/opt/CrowdStrike/falconctl')
  end

  setcode do
    # find out if a customer id has been set. it is a
    # separate query because its failure masks all other responses
    ask_falcon = '/opt/CrowdStrike/falconctl -g --cid'

    falcon_says = Facter::Util::Resolution.exec(ask_falcon)

    # empty response means that it has been an error message and it went
    # to stderr, which exec function did not capture. we do not get the
    # actual value of cid not to expose it in facter output.
    cid_is_set = !falcon_says.empty?

    # find out current sensor settings
    ask_falcon = "/opt/CrowdStrike/falconctl -g --aid --apd --aph --app \
      --rfm-state --rfm-reason --version --tags"

    # format in which falconctl outputs data
    pattern = %r{^(aid(?:=|\sis\s)"?(?<agent_id>not\sset|[a-f0-9]*)"?[,\s\n]*|
      apd(?:=|\sis\s)(?<proxy_disable>not\sset|TRUE|FALSE)[,\s\n]*|
      aph(?:=|\sis\s)(?<proxy_host>not\sset|[^,]+)[,\s\n]*|
      app(?:=|\sis\s)(?<proxy_port>not\sset|[^,]+)[,\s\n]*|
      rfm-state(?:=|\sis\s)(?<reduced_functionality_mode>not\sset|true|false)[,\s\n]*|
      rfm-reason(?:=|\sis\s)(?<reduced_functionality_reason>not\sset|[^,]+)[,\s\n]*|
      (code=0x[A-F0-9]+)[,\s\n]*|
      version\s=\s(?<version>[\d\.]+)[,\s\n]*|
      (?:Sensor\sgrouping\s)?tags(?:=|\sare\s)(?<tags>[^,]*)[,\s\n]*)*$}x

    falcon_says = Facter::Util::Resolution.exec(ask_falcon)

    if !falcon_says.empty?
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
        # add a boolean value to flag set/unset cid
        falcon_facts[:cid] = cid_is_set

        # do not include unset values in the fact
        falcon_facts.reject { |_, value| value.nil? }
      else
        # should never happen. means fact is broken because it cannot
        # pattern match the falconctl response. try to fail gracefully
        # by setting a status flag.
        'parsing_error'
      end
    else
      # should never happen. means that falconctl call returned and error
      # to stderr. try to fail gracefully by setting a flag.
      'falconctl_error'
    end
  end
end
