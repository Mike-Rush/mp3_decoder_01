my $fn=$ARGV[0];
my $size=$ARGV[1];
my $buf,$i;
open(IN,"<".$fn);
#print($fn," ");
$fn=~s/\./_/;
$size*=4;
#print($fn," ",$size,"\n");
open(OUT,">".$fn.".h");
binmode(IN);
read(IN,$buf,$size);
@bufarr=unpack("C*",$buf);
#printf("%d\n",scalar@bufarr);
#printf("%02x\n",$bufarr[0]);
printf(OUT "uint32_t mp3_data[]={\n");
for ($i=0;$i<$size-4;$i+=4) 
{
	printf(OUT "0x%02x%02x%02x%02x,\n",$bufarr[$i],$bufarr[$i+1],$bufarr[$i+2],$bufarr[$i+3]);
}
printf(OUT "0x%02x%02x%02x%02x};\n",$bufarr[$size-4],$bufarr[$size-3],$bufarr[$size-2],$bufarr[$size-1]);
close(IN);
close(OUT);
	