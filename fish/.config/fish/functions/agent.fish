function agent --wraps='eval $(ssh-agent -c)' --description 'alias agent=eval $(ssh-agent -c)'
    eval $(ssh-agent -c) $argv
end
