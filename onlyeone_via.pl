use OpenSIPS;
use OpenSIPS::Constants;

use IPC::Shareable;

my %userslogged;
my %tokill;

sub onlyone_via {
    my $m = shift;

    my ($user, $domain) = split('@', $m->pseudoVar("\$Au"));

    tie %userslogged, IPC::Shareable, {
        key => 'lsus',
        create => 1,
        destroy => 1
    } or die "Error with IPC::Shareble";

    tie %tokill, IPC::Shareable, {
        key => 'lstk',
        create => '1',
        detroy => 1
    } or die "Error with IPC::Shareble";

    my ($currentid) = split(/;/, $m->getHeader("Via"));

    if ($m->getMethod() eq "REGISTER") {
        
        if (%tokill->{$user} eq $currentid) {
            my $au = %tokill->{$user};
            OpenSIPS::log(L_INFO, "488 - sorry, i need to kill $au");
            delete %tokill->{$user};
            OpenSIPS::AVP::add("user_to_kill", "1");
            return 1;
        }

        my $activeid = %userslogged->{$user};

        if ($activeid && $activeid ne $currentid) {
            %tokill->{$user} = $activeid;
            OpenSIPS::log(L_INFO, "488 - Request to kill $activeid");
        }
        %userslogged->{$user} = $currentid;
    
    }

    return 1;
}



