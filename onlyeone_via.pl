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
        
        %tokill->{$user} = $currentid
            if length(%userslogged->{$user}) 
            && %userslogged->{$user} != $currentid;
        
        %userslogged->{$user} = $currentid;
    }

    foreach my $nuser (keys %tokill) {
        next if $nuser ne $user;
        next if %userslogged->{$users} ne $currentid;
        OpenSIPS::log(L_INFO, "Sorry, I need to kill $user");
        $m->sl_send_reply("488", "Sorry, I need to kill you");
    }

}



