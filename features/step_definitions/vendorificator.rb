def vendor_path_for(mod, path)
  File.join('vendor', mod['Path'] || mod['Name'], path)
end

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
      check_file_presence(mod['With file'].lines.
        map { |ln| vendor_path_for(mod, ln.strip) }, !not_p)
    end

    if mod['Without file']
      check_file_presence(mod['Without file'].lines.
          map { |ln| vendor_path_for(mod, ln.strip) }, !!not_p)
    end
  end
end
