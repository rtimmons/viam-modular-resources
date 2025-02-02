default:
	echo "no target entered"

ssh-keygen:
	@if [ ! -f ~/.ssh/id_ecdsa ]; then \
		ssh-keygen -t ecdsa -f ~/.ssh/id_ecdsa -N "";\
	fi
	ssh-copy-id -i ~/.ssh/id_ecdsa.pub $(target)

robot-install:
	ssh $(target) "sudo curl -H 'Secret: $(secret)' 'https://app.viam.com/api/json1/config?id=$(part)&client=t' -o /etc/viam.json; curl https://storage.googleapis.com/packages.viam.com/apps/viam-server/viam-server-stable-aarch64.AppImage -o viam-server && chmod 755 viam-server && sudo ./viam-server --aix-install && sudo raspi-config nonint do_i2c 0 && sudo reboot"

robot-copy:
	echo "copying files to $(target)"
	ssh $(target) "rm -rf ~/src; rm -rf ~/test; rm -f meta.json; rm -f test.sh; rm -f requirements.txt;"
	scp -r src $(target):~/
	scp -r test $(target):~/
	scp meta.json test.sh requirements.txt $(target):~/

robot-runtime-test:
	echo "running modules on $(target)"
	ssh $(target) "python3 src/main.py"

robot-clean:
	echo "cleaning $(target)"
	ssh $(target) "rm -rf src; rm -rf ~/dist; rm -rf ~/build; rm main.spec"

robot-build:
	echo "building binary on $(target)"
	ssh $(target) "python3 -m PyInstaller --onefile --hidden-import="googleapiclient" ~/src/main.py"

robot-deploy:
	echo "deploying local module on $(target)"
	ssh $(target) "sudo rm /viam-modular-resources-build ; sudo cp dist/main /viam-modular-resources-build"

robot-restart:
	ssh $(target) "echo 'restarting viam server... ' && sudo systemctl restart viam-server && echo 'done'"

module-package:
	mkdir -p dist
	echo "copying binary from $(target)"
	scp $(target):~/dist/main dist/main
	tar -czvf dist/archive.tar.gz dist/main

robot-deploy-workflow: robot-copy robot-build robot-deploy robot-restart module-package

robot-package-workflow: robot-copy robot-build module-package

robot-runtime-test-workflow: robot-copy robot-runtime-test