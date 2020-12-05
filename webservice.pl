use Time::HiRes qw(usleep);

print "Webserver Run\n";



while($ARGV[$n]){
    print $n . ': ' . $ARGV[$n] . "\n" if $Debug;
    if($ARGV[$n] eq "kill_all_on_start"){
		$kill_all_on_start = 1;
	}
    if($ARGV[$n] eq "telegraf"){
		$use_telegraf = 1;
		print "Telegraf set to run...\n";
	}
    if($ARGV[$n] eq "apache_background_start"){
		$instance_start_in_background = 0;
		print "instance background starting enabled...\n";
	}
    if($ARGV[$n] eq "background_start"){
		$start_in_background = 1;
		print "All process background starting enabled...\n";
	}
    if($ARGV[$n]=~/apache=/i){
        my @data = split('=', $ARGV[$n]);
        print "Instances to launch: " . $data[1] . "\n";
		$instances_to_launch = $data[1];
    }
    $n++;
}

if($kill_all_on_start){
	system("start taskkill /IM telegraf.exe /F > nul");
	system("start taskkill /IM mysql.exe /F > nul");
	system("start taskkill /IM httpd.exe /F > nul");

}

if(!$instances_to_launch){
	$instances_to_launch = 1;
}
if(!$start_in_background){
	$start_in_background = 0;
}

if($start_in_background == 0){
	$background_start = " /b ";
	$pipe_redirection = " > nul ";
}
else{
	$background_start = "";
	$pipe_redirection = "";
}

%process_status = (
	0 => "DOWN",
	1 => "UP",
);

sub print_status{
	print "									\r";
	print "Telegraf: " . $process_status{$telegraf_process_count} . " ";
	print "Apache: (" . $instance_process_count . "/" . $instances_to_launch . ") ";
	print "mysql: " . $process_status{$mysql_process_count} . " ";
	if($use_telegraf){ print "Telegraf: " . $process_status{$telegraf_process_count} . " "; }
	print "\r";
}

while(1){
	$instance_process_count = 0;
	$telegraf_process_count = 0;

	$l_processes = `TASKLIST`;
	my @processes = split("\n", $l_processes);
	foreach my $val (@processes){

		if($val=~/instance/i){
			$instance_process_count++;
		}

		if($val=~/telegraf/i){
			$telegraf_process_count++;
		}
		if($val=~/mysql/i){
			$mysql_process_count++;
			}
	}
	
	print_status();
	
	#::: Telegraf Process
	if($use_telegraf){	
		for($i = $telegraf_process_count; $i < 1; $i++){ 
			system("start " . $background_start . " telegraf.exe " . $pipe_redirection); 
			$telegraf_process_count++;
			print_status(); 
		}
	}

	#::: instance Processes
	for($i = $instance_process_count; $i < $instances_to_launch; $i++){
		if($instance_start_in_background == 1){
			system("start /b httpd.exe > nul");
		}
		else{
			system("start " . $background_start . " httpd.exe " . $pipe_redirection);
		}
		$instance_process_count++;
		print_status();
		usleep(100);
	}

	#::: mySQL Process
	for($i = $mysql_process_count; $i < 0; $i++){ 
		system("start " . $background_start . " mysql.exe " . $pipe_redirection); 
		print_status();
	}
	
	
	sleep(1);
}
