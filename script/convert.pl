#!/usr/bin/perl
 
sub hexstr2char {
        join "", map{ pack "C", hex }(shift =~ /(..)/g);
        # or
        #join "", map{ chr hex }(shift =~ /(..)/g);
}
 
sub char2hexstr {
        join "", map{ $_ = sprintf "%X", $_ }unpack( "C*", shift );
}
 
while(<>){
        chomp;
        print &hexstr2char( $_ ),"\n";
        #print &char2hexstr( $_ ),"\n";
}

