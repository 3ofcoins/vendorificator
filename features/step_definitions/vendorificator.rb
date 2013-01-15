Then /^(?:the )?following has( not)? been conjured:$/ do |not_p, table|
  exists_p = not_p ? "does not exist" : "exists"

  step "I'm on \"master\" branch"

  table.transpose.hashes.each do |mod|
    step "branch \"vendor/#{mod['Name']}\" #{exists_p}"

    if mod['Version']
      step "tag \"vendor/#{mod['Name']}/#{mod['Version']}\" #{exists_p}"
    else
      step "tag matching /^vendor\\/#{Regexp.quote(mod['Name']).gsub('/', '\\/')}\\// #{exists_p}"
    end

    if mod['With file']
      mod['With file'].lines.each do |path|
        step "file \"vendor/#{mod['Name']}/#{path.strip}\" #{exists_p}"
      end
    end

    if mod['Without file']
      mod['Without file'].lines.each do |path|
        step "file \"vendor/#{mod['Name']}/#{path.strip}\" does not exist"
      end
    end
  end
end
