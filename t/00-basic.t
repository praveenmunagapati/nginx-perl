#!/usr/bin/perl

# Copyright 2011 Alexandr Gomoliako

use strict;
use warnings;
no  warnings 'uninitialized';

use Data::Dumper;
use Test::More;
use Nginx::Test;


my $nginx = find_nginx_perl;
my $dir   = "objs/t00"; 
mkdir "objs" unless -e "objs";

plan skip_all => "Can't find executable binary ($nginx) to test"
        if  !$nginx    ||  
            !-x $nginx    ;

plan 'no_plan';


{
    my ($child, $peer) = fork_nginx_handler_die $nginx, $dir, '',<<'    END';

        sub handler {
            my ($r) = @_;

            $r->main_count_inc;


            my $buf = "Hello\n";

            $r->header_out ('Content-Length', length ($buf));
            $r->send_http_header ('text/html; charset=UTF-8');

            $r->print ($buf)
                    unless  $r->header_only;

            $r->send_special (NGX_HTTP_LAST);
            $r->finalize_request (NGX_OK);


            return NGX_DONE;
        }

    END

    wait_for_peer $peer, 5
        or diag "wair_for_peer \"$peer\" failed\n";

    my ($body, $headers) = http_get $peer, '/', 2;

    ok $body =~ /Hello/i, "hello"
        or diag "body = $body\n", cat_nginx_logs $dir;

}



