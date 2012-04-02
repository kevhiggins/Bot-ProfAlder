#!/usr/bin/perl
package Google;
use LWP::UserAgent;

# Search google... Don't spam this
# Make a max search get param

sub google_search {
  
  my $query = shift;
  my $query = join("+",split(/ /, $query));

  my $ua = new LWP::UserAgent;

  my $ua = LWP::UserAgent->new( 
    env_proxy => 1, 
    keep_alive => 1, 
    timeout => 30, 
    agent => "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.3) Gecko/2008101315 Ubuntu/8.10 (intrepid) Firefox/3.0.3\r\n"
  ); 

  my $response = $ua->get("http://www.google.com/search?hl=en&q=$query&btnG=Google+Search&aq=f&oq=");

  my $result = $response->content; 

  my @urls = $result =~ /<br><cite>(.*?)<\/cite>/g;
  my @final;
  for(my $i = 0; $i < scalar(@urls); $i++) {
    $urls[$i] =~ s/(?:<b>|<\/b>)//g;
    if($urls[$i] =~ /(.*?) - \d+k - /) {
      push(@final, $1);
    }
  }

  return @final;
  
}

1;
