#!/bin/fish

function javaenv
    if test (count $argv) -eq 0
        /usr/lib/jvm/ -V
    else
        switch $argv[1]
        case 'ls'
            /usr/lib/jvm/ -V
        case 'set'
            set -xU JAVA_HOME (/usr/lib/jvm/ -v $argv[2])
        end
    end
end

