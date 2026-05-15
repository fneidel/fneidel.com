export BROWSERSLIST_IGNORE_OLD_DATA=1

all: tww serve install-hooks

serve:
	firefox http://localhost:1313 >/dev/null 2>&1 &
	hugo server -D -p 1313 --navigateToChanged --baseURL="http://localhost"

tw: themes/blowfish/node_modules  # tailwind
	./themes/blowfish/node_modules/.bin/tailwindcss -c ./themes/blowfish/tailwind.config.js -i ./themes/blowfish/assets/css/main.css -o ./assets/css/compiled/main.css --minify
tww: themes/blowfish/node_modules # tailwind watch
	./themes/blowfish/node_modules/.bin/tailwindcss -c ./themes/blowfish/tailwind.config.js -i ./themes/blowfish/assets/css/main.css -o ./assets/css/compiled/main.css --jit --watch >/dev/null

themes/blowfish/node_modules:
	git submodule init
	git submodule update
	npm install --prefix ./themes/blowfish

assets/css/compiled/main.css: themes/blowfish/node_modules
	./themes/blowfish/node_modules/.bin/tailwindcss -c ./themes/blowfish/tailwind.config.js -i ./themes/blowfish/assets/css/main.css -o ./assets/css/compiled/main.css ---minify

build:
	HUGO_ENV=production hugo --gc --minify

test: assets/css/compiled/main.css
	HUGO_ENV=production hugo --gc --minify --templateMetrics --templateMetricsHints --printPathWarnings

clear-cache:
	rm -r public
	git restore public/_redirects

write-hugo-version:
	hugo version | grep -Eo "\d+\.\d+\.\d+" >.hugo-version

install-hugo:
	required_version="$$(cat .hugo-version)"; \
	local_version="$$(hugo version | grep -Po "\d+\.\d+\.\d+")"; \
	if [ "$$local_version" != "$$required_version" ]; then \
		CGO_ENABLED=1 go install -tags extended github.com/gohugoio/hugo@v$$required_version; \
	fi

pull:
	git fetch origin master
	git reset --hard origin/master
	git submodule update

sync-tailwind: assets/css/compiled/main.css
	rsync -avrp --delete assets/css/compiled/main.css uber:html/assets/css/compiled/main.css

reset:
	git reset --hard
	git clean -df

publish: # run via a custom git publish
	ssh uber 'zsh -lc "cd html; make pull; make install-hugo; make reset; mkdir -p assets/css/compiled"'
	$(MAKE) sync-tailwind
	ssh uber 'zsh -lc "cd html; make build"'
