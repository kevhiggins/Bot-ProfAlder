#!/usr/bin/perl

=head1 NAME


talker.pm - Outputs random sentences from trained text

=head1 PROBLEM

Train a program to generate sentences from a given set of text

=head1 SOLUTION

This program uses a hash to store all n-1 grams in the given text.
Each hash key references an 2 element array. Element one is the number
of occurences of the hash key. Element two is a hash containing keys
of all unigrams occurring directly after the n-1 gram. The value of
the key is the number of times each unigram occurs. Using this
information, the program statistically generates sentences based
on these Ngrams. Taking the occurrence of the unigram / n-1gram
*100 for all ngrams that are possible at a given part of a sentence.
(Starting at the beginning). A random number is then generated, and
whatever unigram is associated with the called number is then added
to the sentence. This occurs until a punctuation mark is found.

=head1 AUTHOR

Kevin Higgins - kev.higgins@gmail.com

=cut

#I would like to fix this to use strict O.O it's looking pretty frightening

package talker;

sub descendHash;
sub doGram;
sub doLink;
sub rand_talk;

#Sorts the hash by value, then by name
sub descendHash {
	$daHash{$b}[0] <=> $daHash{$a}[0]
	or
	$a cmp $b	
}

#Adds the ngram to the hash
sub doGram {
	my $curToken = $_[0];
	if(exists $daHash{$curToken}){
		$daHash{$curToken}->[0]++;
	}
	else{
		$termcount++;
		$daHash{$curToken} = [1, {}];
	}			
}

#Creates a hash in $prevToken to $curToken
sub doLink {
	my($prevToken, $curToken);
	($prevToken, $curToken) = @_;
	if(exists $daHash{$prevToken}->[1]->{$curToken}){
		$daHash{$prevToken}->[1]->{$curToken}++;
	}
	else{
		$daHash{$prevToken}->[1]->{$curToken} = 1;
	}
}

sub rand_talk {

#Shift the non-file args off of the array
$n = shift;
$m = shift;
$content_ptr = shift;

(($m && $n) > 0) or die "Invalid argument(s)\n";

$argcount = scalar(@$content_ptr);
%daHash;
$wordcount = 0;
$termcount = 0;
@sString;

#Initializes @sString with the proxy unigrams
for(my $i = 0; $i<$n -1; $i++){
	push(@sString,"<S$i>");
}

#Slurps a file at a time drawing it into the n-gram hash table
while($argcount--){

	my @tokens;
	my $tmpn = $n - 1;

	#Limit the scope of textin so that it is trashed after split
	{
	my $textin = $content_ptr->[$argcount];
	
	#Remove unwanted symbols
	$textin =~ s/[\(\)*\#"{}`;:]|'\s|\s'/ /g;
	$textin =~ s/(,)/ \1 /g;
	#Convert Mac/Windows/DOS to Unix/Linux
	$textin =~ s/\r\n|\r/\n/g;
	#Remove text headers
	$textin =~ s/([^\?!\.]|\.[^\s\.])*?\n\n+/ /g;
	#Remove newlines and set to lowercase
	$textin =~ s/[\n]/ /g;
	$textin = lc($textin);	
	#Tokenize textin by sentence
	@sentences = $textin =~ /([^\?\.!]*[\?\.!]+)/g;
	}

  #if(scalar(@sentences) == 0) { return undef};

	foreach(@sentences){

		my @ngram;
		#Allow period to be tokenized
		s/([\.\?!]+)/ \1 /g;
		#Tokenize sentence
		@tokens = split(/\s+/, $_);
		#Get rid of any leading spaces in token array
		if(($tokens[0] =~/^$/)){ shift(@tokens);}
		#Skip sentence if smaller than n
		next if scalar @tokens < $tmpn;
		
		#Special case for $n == 1 Just adds ngrams to hash
		if($n == 1){
			foreach(@tokens){
				$wordcount++;
				doGram($_);
			}
		}
		#Else, add n-1grams to hash AND link them to unigrams
		else{
			@ngram = @sString;
			foreach(@tokens){
				$wordcount++;
				my $currToken = "@ngram";		
				my $nextToken = $_;
				doGram($currToken);
				doLink($currToken, $nextToken);
				shift(@ngram);
				push(@ngram, $nextToken);
			}
			doGram("@ngram");
		}
	}
}
my $counter = 1;
#Apologies for the impending mess

#Special Case Just does stats of unigrams compared to word count
if($n==1){

my @stats;
my $tmpStat = 0;
#Generate the unigram statistics into an array
foreach $key(keys(%daHash)){
	$tmpStat += ($daHash{$key}[0]/$wordcount)* 100;
	if($tmpStat > 0){
		push(@stats, $tmpStat);
		push(@stats, $key);
	}
}
#Using the stats array, generate unigrams until punctuation
while($m--){
my $lastWord;
my @randLine;
	while(!($lastWord =~ /[\.\?!]/)){
		my $rNum = rand(100);
	
		for(my $i=0;$i<scalar(@stats);$i+=2){
			if($stats[$i] > $rNum){
				$lastWord = $stats[$i+1]; 

				push(@randLine, $lastWord);
				last;
			}
		}
	}
#Print it
$out = "@randLine";
$out =~ s/\s([\.\?!,])/$1/g;
print "$out\n";

}
}
#Other cases: get stats from unigram/n-1gram counts
else{
while($m--){
my @randLine;
my $lastWord;
my @currGram = @sString;
while(!($lastWord =~ /[\.\?!]/)){
	my @stats;
	my $tmpStat = 0;
#Same idea, but the stats are regenerated every word, so they are current for
#the given n-1gram
	foreach $key (keys(%{$daHash{"@currGram"}->[1]})){
		$tmpStat += ($daHash{"@currGram"}->[1]{$key}/$daHash{"@currGram"}->[0])* 100;
		if($tmpStat > 0){
			push(@stats, $tmpStat);
			push(@stats, $key);
		}
	}
#Then a random number is generated, and a word is added to the sentence
	my $rNum = rand(100);
	for(my $i=0;$i<scalar(@stats);$i+=2){
		if($stats[$i] > $rNum){
			$lastWord = $stats[$i+1]; 

			push(@randLine, $lastWord);
			last;
		}
	}
	shift(@currGram);
	push(@currGram, $lastWord);
}

#Print it
$out = "@randLine";
$out =~ s/\s([\.\?!,])/$1/g;
return $out;
print "$counter) $out\n\n";
$counter++;
}
}
}
1;
