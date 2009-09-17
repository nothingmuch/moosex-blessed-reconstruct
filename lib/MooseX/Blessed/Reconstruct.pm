#!/usr/bin/perl

package MooseX::Blessed::Reconstruct;
use Moose;

use Carp qw(croak);

use Class::MOP 0.66; # well behaved load_class()
use Data::Visitor 0.21; # n-arity visit

use Scalar::Util qw(reftype);

use namespace::clean -except => 'meta';

our $VERSION = "0.03";

extends qw(Data::Visitor);

has load_classes => (
	isa => "Bool",
	is  => "rw",
	default => 1,
);

sub visit_object {
	my ( $v, $obj ) = @_;

	my $class = ref $obj;

	Class::MOP::load_class($class) if $v->load_classes;

	my $meta = Class::MOP::get_metaclass_by_name($class);

	if ( ref $meta ) {
		return $v->visit_object_with_meta($obj, $meta);
	} else {
		return $v->visit_ref($obj);
	}
}

sub visit_object_with_meta {
	my ( $v, $obj, $meta ) = @_;

	my $instance = $meta->get_meta_instance->create_instance;

	$v->_register_mapping( $obj => $instance );

	my $args = $v->prepare_args( $meta, $obj );

	$meta->new_object( %$args, __INSTANCE__ => $instance );

	$instance->BUILDALL($args) if $instance->can("BUILDALL");

	return $instance;
}

sub prepare_args {
	my ( $v, $meta, $obj ) = @_;

    my @args;

    if ( reftype $obj eq 'HASH' ) {
        @args = %$obj;
    } elsif ( reftype $obj eq 'ARRAY' ) {
        @args = @$obj;
    } elsif ( reftype $obj eq 'SCALAR' ) {
        @args = $$obj;
    } else {
        croak "unknown ref type $obj";
    }

    my @processed = $v->visit(@args);

    return $meta->name->BUILDARGS(@processed);
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=head1 NAME

MooseX::Blessed::Reconstruct - A L<Data::Visitor> for creating Moose objects
from blessed placeholders

=head1 SYNOPSIS

	use MooseX::Blessed::Reconstruct;


	my $obj = bless( {
		init_arg_foo => "Blah",
		arf => "yay",
	}, "Foo" );

	my $proper = MooseX::Blessed::Reconstruct->new->visit($obj);



	# equivalent to:

	my $proper = Foo->meta->new_object(%$obj);
	$proper->BUILDALL({%$obj});

	# but recursive (and works with shared references)

=head1 DESCRIPTION

The purpose of this module is to "fix up" blessed data into a real Moose
object.

This is used internally by L<MooseX::YAML> but has no implementation details
having to do with L<YAML> itself.

=head1 METHODS

See L<Data::Visitor>

=over 4

=item visit_object $object

Calls L<Class::MOP/load_class> on the C<ref> of $object.

If there's a metaclass, calls C<visit_object_with_meta>, otherwise C<visit_ref>
is used to walk the object brutishly.

Returns a deep clone of the input structure with all the L<Moose> objects
reconstructed "properly".

=item visit_object_with_meta $obj, $meta

Uses the metaclass C<$meta> to create a new instance, registers the instance
with L<Data::Visitor>'s cycle tracking, and then inflates it using
L<Moose::Meta::Class/new_object>.

After the object is built, C<BUILDALL> is called if the object implements it.

=item prepare_args $obj

Collapses $obj into key value pairs to be used as init args to
L<Moose::Meta::Class/new_object>.

=back

=head1 VERSION CONTROL

This module is maintained using Darcs. You can get the latest version from
L<http://nothingmuch.woobling.org/code>, and use C<darcs send> to commit
changes.

=head1 AUTHOR

Jonathan Rockway

Yuval Kogman E<lt>nothingmuch@woobling.orgE<gt>

=head1 COPYRIGHT

	Copyright (c) 2008 Infinity Interactive, Yuval Kogman. All rights
	reserved This program is free software; you can redistribute
	it and/or modify it under the same terms as Perl itself.

=cut
