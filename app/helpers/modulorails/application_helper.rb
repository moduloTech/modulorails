# @author Matthieu CIAPPARA <ciappa_m@modulotech.fr>
module Modulorails::ApplicationHelper

  def powered_by
    link_to('https://www.modulotech.fr/', target: '_blank', class: 'modulolink', rel: 'noopener') do
      safe_join(['Powered by modulo', content_tag(:span, 'Tech')])
    end
  end

end
