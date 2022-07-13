# @author Matthieu CIAPPARA <ciappa_m@modulotech.fr>
module Modulorails::ApplicationHelper

  def powered_by
    link_to('https://www.modulotech.fr/', target: '_blank', class: 'modulolink', rel: 'noopener') do
      raw('Powered by modulo<span>Tech</span>')
    end
  end

end
