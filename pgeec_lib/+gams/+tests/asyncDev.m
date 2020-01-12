function asyncDev()
	clear;
	clc;

	isRunning = true;
	
	function dummyFunc()
		a = 0;
		for i = 1:1000000000
			a = sqrt(a+1);
		end
		isRunning = false;
	end
	
	t = timer('StartDelay', 1e-3);
	t.TimerFcn = @(myTimerObj, thisEvent)dummyFunc();

	
	disp('before');	
	start(t)
	disp('after');	
	
	while(isRunning == true)
	  disp('.')
	  pause(1)
	end
	
	delete(t)

	
end