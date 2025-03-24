use strict;
use warnings;

my %variables;

sub evaluate {
    my ($expr) = @_;
    $expr =~ s/\s+//g;  
    
    if ($expr =~ /^([a-zA-Z]+)=(.+)$/) {
        my ($var, $value) = ($1, $2);
        my $result = eval_expression($value);
        if (defined $result) {
            $variables{$var} = $result;
            return $result;
        } else {
            return "Error: Invalid expression";
        }
    } else {
        my $result = eval_expression($expr);
        return defined $result ? $result : "Error: Invalid expression";
    }
}

sub eval_expression {
    my ($expr) = @_;
    
    # Replace variables with their values, if they exist
    $expr =~ s/([a-zA-Z]+)/exists $variables{$1} ? $variables{$1} : "Error: Undefined variable $1"/ge;

    return "Error: Invalid characters" if $expr =~ /[^0-9+\-*\/()]/;
    
    my $result = eval $expr;
    return defined $result ? $result : "Error: Invalid expression";
}


while (1) {
    print "Enter expression or 'q' to quit: ";
    my $input = <STDIN>;
    chomp $input;
    last if $input eq 'q';
    print "Result: ", evaluate($input), "\n";
}
