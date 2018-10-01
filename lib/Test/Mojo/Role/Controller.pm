package Test::Mojo::Role::Controller;

use Mojo::Base -base;
use Role::Tiny;

use Mojo::Loader 'load_class';

has _controllers => sub { {} };

# if a new txn happens, our current set of controllers is out of date,
# so clear the cache
before tx => sub {
    my $self = shift;
    if ($@) {
        warn "CLEARING CONTROLLERS";
        $self->_controllers( {} );
    }
};

sub fake_request {
    my $self = shift;
    my $tx = $self->app->ua->build_tx( @_ ? @_ : ( 'GET', '/' ) );
    $self->tx($tx);
}

sub controller {
    my $self  = shift;
    my $class = shift;

    if (@_) {
        $self->fake_request(@_);
    }
    elsif ( !$self->tx ) {
        $self->fake_request();
    }

    unless ( $self->_controllers->{$class} ) {

        # load first matching class in namespace(s)
        my @classes = ($class);
        push @classes, "${_}::$class" for @{ $self->app->routes->namespaces };

        my $found;
        foreach (@classes) {
            load_class $_ and next;
            $found = $_;
        }

        $t->_controllers->{$class} = $found->new(
            {   app => $self->app,
                tx  => $self->tx,
            }
        );
    }

    return $t->_controllers->{$class};
}

1;

__END__

=pod

=head1 NAME

Test::Mojo::Role::Controller - easier testing of controllers and plugins

=head1 SYNOPSIS

    use Test::Mojo::WithRoles 'Controller';

    my $t = Test::Mojo::WithRoles->new('My::App');

    # controller with faked GET / request
    my $c = $t->controller('Foo'); # searches in $t->app->routes->namespaces

    # build a fake current request:
    $t->fake_request( POST => '/foo' => json => { foo => 'bar' } );

    # now can call methods on the controller
    $c->stash( ... );
    is $c->my_internal_method( ...' ), ...;
    is $c->my_helper( ... ), ...;

    # optionally pass fake request arguments at same time
    my $c = $t->controller( 'Foo', POST => '/foo' => json => { foo => 'bar' } );

    $t->get_ok( '/bar' ); # real request made on test app
    my $c = $t->controller('Foo'); # now has GET /bar as current 'fake' request

=head1 DESCRIPTION

Role for C<Test::Mojo> to facilitate testing functionality in controllers and
plugins.

Helpers in Mojolicious applications are added to both application and controller
but in many cases are only applicable on the controller. This allows testing
of a helper without the need to construct a fake route to call that helper.

=head1 METHODS

=head2 fake_request

    # Pass in transaction building arguments (same as for $t->get_ok, $t->post_ok, etc)
    my $tx = $t->fake_request( GET => '/foo' );
    my $tx = $t->fake_request( POST => '/foo' => json => {...} );

=head2 controller

    # Pass in:
    # * class name (or partial class name to be found in namespace)
    # * optional transaction building arguments (same as for $t->get_ok, $t->post_ok, etc)
    my $c = $t->controller('Foo');
    my $c = $t->controller( 'Foo', POST => '/foo' => json => {...} );

Returns a L<Mojolicious::Controller> object that can be used in tests. Takes optional
arguments to build a fake request.

=cut

