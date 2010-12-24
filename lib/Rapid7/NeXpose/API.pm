package Rapid7::NeXpose::API;

use warnings;
use strict;

use XML::Simple;
use LWP::UserAgent;
use HTTP::Request::Common;

use Data::Dumper;

=head1 NAME

Rapid7::NeXpose::API - The great new Rapid7::NeXpose::API!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Rapid7::NeXpose::API;

    my $foo = Rapid7::NeXpose::API->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut
sub new {
	my $class = shift;
	my $self;

	$self->{_url} = shift;
#	$self->{_opts} = shift;
#	$self->{_url} = $self->{_opts}->{url}
	if ($self->{_url} eq '') {
		$self->{_url}='https://localhost:3780/';
	} elsif (substr($self->{_url},-1,1) ne '/') {
		$self->{_url}= $self->{_url}.'/';
	}
	$self->{_urlapi}=$self->{_url}."api/1.1/xml";
	$self->{_ua} = LWP::UserAgent->new;
	bless $self, $class;
	return $self;
}

=head2 url ( [$nexpose_url] )

get/set NeXpose base URL
=cut
sub url {
	my ( $self, $url ) = @_;
	$self->{_url} = $url if defined($url);
	return ( $self->{_url} );
}

=head2 urlapi ( [$nexpose_url_api] )

get/set NeXpose API URL
=cut
sub urlapi {
	my ( $self, $urlapi ) = @_;
	$self->{_urlapi} = $urlapi if defined($urlapi);
	return ( $self->{_urlapi} );
}

=head2 user ( [$user] )

set NeXpose credentials, returns $user
=cut
sub user {
	my ( $self, $user, $password ) = @_;
	$self->{_user} = $user if defined($user);
	$self->{_password} = $password if defined($password);
	return ( $self->{_user} );
}

=head2 password ( [$password])

set NeXpose credentials, returns $password
=cut
sub password {
	my ( $self, $password ) = @_;
	$self->{_password} = $password if defined($password);
	return ( $self->{_password} );
}

=head2 session ( [$session])

set NeXpose session-id, returns $session
=cut
sub session {
	my ( $self, $session ) = @_;
	$self->{_session} = $session if defined($session);
	return ( $self->{_session} );
}

=head2 syncid ( [$syncid])

set NeXpose sync-id, returns $id
=cut
sub syncid {
	my ( $self, $syncid ) = @_;
	my $sid;
	if (defined($syncid)) {
		$sid = $syncid;
	} else {
		$sid=int(rand(65535));
	}
	return ( $sid );
}

=head2 lwpdebug 

get/set LWP debugging
=cut
sub lwpdebug {
	my ( $self ) = @_;
	my $ua = $self->{_ua};
	$ua->add_handler("request_send",  sub { shift->dump; return });
	$ua->add_handler("response_done", sub { shift->dump; return });
}

=head2 xml_request ( <$req> )

perform XML request to nexpose 
=cut
sub xml_request {
	my ( $self, $req ) = @_;

	my $xml = XMLout($req, RootName => '', XMLDecl => '<?xml version="1.0" encoding="UTF-8"?>');
	print $xml."\n";
	my $cont = $self->http_api ($xml);
	my $xmls;
	eval {
	$xmls=XMLin($cont, KeepRoot => 1, ForceArray => 1, KeyAttr => '', SuppressEmpty => '' );
	} or return '';
	return ($xmls);
}

=head2 http_api <$post_data> )

perform api request to nexpose and return content
=cut
sub http_api {
	my ( $self, $post_data ) = @_;

	my $ua = $self->{_ua};
	my $r = POST $self->{_urlapi}, 'Content-Type'=>'text/xml', Content=>$post_data;
	my $result = $ua->request($r);
	if ($result->is_success) {
		return $result->content;
	} else {
		return '';
	}
}

=head2 login 

login to NeXpose 
=cut
sub login {
	my ( $self ) = @_;
	my $hashref = { 'LoginRequest' => {
	'sync-id' => $self->syncid(),
	'user-id' => $self->user(),
	'password' => $self->password()
	} };
	my $xmlh = $self->xml_request($hashref);
	if ($xmlh->{'LoginResponse'}->[0]->{'success'}==1) {
		$self->session($xmlh->{'LoginResponse'}->[0]->{'session-id'});
		return $xmlh; 
	} else { 
		return ''
	}
}

sub logout {
	my ( $self ) = @_;

	my $sid=int(rand(65535));
	my $hashref = { 'LogoutRequest' => {
	'sync-id' => $self->syncid(),
	'session-id' => $self->session()
	} };
	
	my $xmlh = $self->xml_request($hashref);
	if ($xmlh->{'LogoutResponse'}->[0]->{'success'}==1) {
		return 1; 
	} else {
		return 0;
	}
}

=head2 sitelist 

list sites 
=cut
sub sitelist {
	my ( $self ) = @_;
	my $hashref = { 'SiteListingRequest' => {
	'sync-id' => $self->syncid(),
	'session-id' => $self->session()
	} };
	my $xmlh = $self->xml_request($hashref);
	if ($xmlh->{'SiteListingResponse'}->[0]->{'success'}==1) {
		return $xmlh->{'SiteListingResponse'}->[0]->{'SiteSummary'};
	} else { 
		return ''
	}
}

=head2 sitescan 

site scan
=cut
sub sitescan {
	my ( $self, $siteid ) = @_;
	my $hashref = { 'SiteScanRequest' => {
	'sync-id' => $self->syncid(),
	'session-id' => $self->session(),
	'site-id' => $siteid
	} };
	my $xmlh = $self->xml_request($hashref);
	if ($xmlh->{'SiteScanResponse'}->[0]->{'success'}==1) {
		my $hashref={
		'scan-id' => $xmlh->{'Scan'}->[0]->{'scan-id'},
		'engine-id' => $xmlh->{'Scan'}->[0]->{'engine-id'}
		};
		return $hashref;
	} else { 
		return ''
	}
}

=head2 sitedelete 

delete site
=cut
sub sitedelete {
	my ( $self, $siteid ) = @_;
	my $hashref = { 'SiteDeleteRequest' => {
	'sync-id' => $self->syncid(),
	'session-id' => $self->session(),
	'site-id' => $siteid
	} };
	my $xmlh = $self->xml_request($hashref);
	if ($xmlh->{'SiteDeleteResponse'}->[0]->{'success'}==1) {
		return 1;
	} else { 
		return 0;
	}
}

=head2 DESTROY 
destructor, calls logout method on destruction
=cut
sub DESTROY {
	my ($self) = @_;
	$self->logout();
}

=head1 AUTHOR

Vlatko Kosturjak, C<< <kost at linux.hr> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-rapid7-nexpose-api at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Rapid7-NeXpose-API>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Rapid7::NeXpose::API


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Rapid7-NeXpose-API>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Rapid7-NeXpose-API>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Rapid7-NeXpose-API>

=item * Search CPAN

L<http://search.cpan.org/dist/Rapid7-NeXpose-API/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Vlatko Kosturjak.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Rapid7::NeXpose::API
