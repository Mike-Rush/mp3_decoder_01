open(DATA1,"<states.txt");
open(DATA2,">out.txt");
$fsm_counter=0;
while (<DATA1>) 
{
	if ($_)
	{
		$fsm_counter=$fsm_counter+1;
	}
}
$i=1;
close DATA1;
open(DATA1,"<states.txt");
#printf DATA2 "typedef enum logic[%d:0] {\n",$fsm_counter-1; 
while (<DATA1>) {
if ($_)
{
	$t=$_;
	$t=~s/\n//;
	printf DATA2 "`define %s %d\'b",$t,$fsm_counter;
	for ($a=0; $a<$i-1; $a+=1) 
	{
		print DATA2 '0';
	}
	print DATA2 '1';
	for ($a=0;$a<$fsm_counter-$i;$a+=1) {print DATA2 '0';}
	#if ($i<$fsm_counter) {print DATA2 ',';}
	print DATA2 "\n";
	$i+=1;
}
}
#printf DATA2 "} state;\n";
close DATA1;
close DATA2;