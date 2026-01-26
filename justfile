switch:
	switch

test:
	test

falcon-out:
	mv crowdstrike-falcon/falcon-sensor_7.29.0-18202_amd64.deb crowdstrike-falcon/falcon-sensor_7.29.0-18202_amd64.deb_
	git add crowdstrike-falcon/falcon-sensor_7.29.0-18202_amd64.deb

falcon-in:
	mv crowdstrike-falcon/falcon-sensor_7.29.0-18202_amd64.deb_ crowdstrike-falcon/falcon-sensor_7.29.0-18202_amd64.deb
	git add crowdstrike-falcon/falcon-sensor_7.29.0-18202_amd64.deb

alias fout := falcon-out
alias fin := falcon-in

