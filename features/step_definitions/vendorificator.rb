def vendor_path_for(mod, path)
  if mod['Path']
    File.join mod['Path'], path
  else
    File.join 'vendor', mod['Name'], path
  end
end

Then /^(?:the )?following has( not)? been conjured:$/ do |not_p, table|
  exists_p = not_p ? "does not exist" : "exists"

  step "I'm on \"master\" branch"

  table.transpose.hashes.each do |mod|
    branch = mod['Branch'] || "vendor/#{mod['Name']}"
    step "branch \"#{branch}\" #{exists_p}"

    if mod['Version']
      step "tag \"#{branch}/#{mod['Version']}\" #{exists_p}"
    else
      step "tag matching /^#{Regexp.quote(branch).gsub('/', '\\/')}\\// #{exists_p}"
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
