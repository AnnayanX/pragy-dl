all: lazy-extractors pragy-dl doc pypi-files
clean: clean-test clean-dist
clean-all: clean clean-cache
completions: completion-bash completion-fish completion-zsh
doc: README.md CONTRIBUTING.md issuetemplates supportedsites
ot: offlinetest
tar: pragy-dl.tar.gz

# Keep this list in sync with MANIFEST.in
# intended use: when building a source distribution,
# make pypi-files && python setup.py sdist
pypi-files: AUTHORS Changelog.md LICENSE README.md README.txt supportedsites \
	        completions pragy-dl.1 requirements.txt setup.cfg devscripts/* test/*

.PHONY: all clean install test tar pypi-files completions ot offlinetest codetest supportedsites

clean-test:
	rm -rf test/testdata/sigs/player-*.js tmp/ *.annotations.xml *.aria2 *.description *.dump *.frag \
	*.frag.aria2 *.frag.urls *.info.json *.live_chat.json *.meta *.part* *.tmp *.temp *.unknown_video *.ytdl \
	*.3gp *.ape *.ass *.avi *.desktop *.f4v *.flac *.flv *.gif *.jpeg *.jpg *.m4a *.m4v *.mhtml *.mkv *.mov *.mp3 \
	*.mp4 *.mpga *.oga *.ogg *.opus *.png *.sbv *.srt *.swf *.swp *.tt *.ttml *.url *.vtt *.wav *.webloc *.webm *.webp
clean-dist:
	rm -rf pragy-dl.1.temp.md pragy-dl.1 README.txt MANIFEST build/ dist/ .coverage cover/ pragy-dl.tar.gz completions/ \
	pragy_dl/extractor/lazy_extractors.py *.spec CONTRIBUTING.md.tmp pragy-dl pragy-dl.exe pragy_dl.egg-info/ AUTHORS .mailmap
clean-cache:
	find . \( \
		-type d -name .pytest_cache -o -type d -name __pycache__ -o -name "*.pyc" -o -name "*.class" \
	\) -prune -exec rm -rf {} \;

completion-bash: completions/bash/pragy-dl
completion-fish: completions/fish/pragy-dl.fish
completion-zsh: completions/zsh/_pragy-dl
lazy-extractors: pragy_dl/extractor/lazy_extractors.py

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin
MANDIR ?= $(PREFIX)/man
SHAREDIR ?= $(PREFIX)/share
PYTHON ?= /usr/bin/env python3

# set SYSCONFDIR to /etc if PREFIX=/usr or PREFIX=/usr/local
SYSCONFDIR = $(shell if [ $(PREFIX) = /usr -o $(PREFIX) = /usr/local ]; then echo /etc; else echo $(PREFIX)/etc; fi)

# set markdown input format to "markdown-smart" for pandoc version 2 and to "markdown" for pandoc prior to version 2
MARKDOWN = $(shell if [ `pandoc -v | head -n1 | cut -d" " -f2 | head -c1` = "2" ]; then echo markdown-smart; else echo markdown; fi)

install: lazy-extractors pragy-dl pragy-dl.1 completions
	mkdir -p $(DESTDIR)$(BINDIR)
	install -m755 pragy-dl $(DESTDIR)$(BINDIR)/pragy-dl
	mkdir -p $(DESTDIR)$(MANDIR)/man1
	install -m644 pragy-dl.1 $(DESTDIR)$(MANDIR)/man1/pragy-dl.1
	mkdir -p $(DESTDIR)$(SHAREDIR)/bash-completion/completions
	install -m644 completions/bash/pragy-dl $(DESTDIR)$(SHAREDIR)/bash-completion/completions/pragy-dl
	mkdir -p $(DESTDIR)$(SHAREDIR)/zsh/site-functions
	install -m644 completions/zsh/_pragy-dl $(DESTDIR)$(SHAREDIR)/zsh/site-functions/_pragy-dl
	mkdir -p $(DESTDIR)$(SHAREDIR)/fish/vendor_completions.d
	install -m644 completions/fish/pragy-dl.fish $(DESTDIR)$(SHAREDIR)/fish/vendor_completions.d/pragy-dl.fish

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/pragy-dl
	rm -f $(DESTDIR)$(MANDIR)/man1/pragy-dl.1
	rm -f $(DESTDIR)$(SHAREDIR)/bash-completion/completions/pragy-dl
	rm -f $(DESTDIR)$(SHAREDIR)/zsh/site-functions/_pragy-dl
	rm -f $(DESTDIR)$(SHAREDIR)/fish/vendor_completions.d/pragy-dl.fish

codetest:
	flake8 .

test:
	$(PYTHON) -m pytest
	$(MAKE) codetest

offlinetest: codetest
	$(PYTHON) -m pytest -k "not download"

# XXX: This is hard to maintain
CODE_FOLDERS = pragy_dl pragy_dl/downloader pragy_dl/extractor pragy_dl/postprocessor pragy_dl/compat pragy_dl/compat/urllib pragy_dl/utils pragy_dl/dependencies pragy_dl/networking
pragy-dl: pragy_dl/*.py pragy_dl/*/*.py
	mkdir -p zip
	for d in $(CODE_FOLDERS) ; do \
	  mkdir -p zip/$$d ;\
	  cp -pPR $$d/*.py zip/$$d/ ;\
	done
	touch -t 200001010101 zip/pragy_dl/*.py zip/pragy_dl/*/*.py
	mv zip/pragy_dl/__main__.py zip/
	cd zip ; zip -q ../pragy-dl pragy_dl/*.py pragy_dl/*/*.py __main__.py
	rm -rf zip
	echo '#!$(PYTHON)' > pragy-dl
	cat pragy-dl.zip >> pragy-dl
	rm pragy-dl.zip
	chmod a+x pragy-dl

README.md: pragy_dl/*.py pragy_dl/*/*.py devscripts/make_readme.py
	COLUMNS=80 $(PYTHON) pragy_dl/__main__.py --ignore-config --help | $(PYTHON) devscripts/make_readme.py

CONTRIBUTING.md: README.md devscripts/make_contributing.py
	$(PYTHON) devscripts/make_contributing.py README.md CONTRIBUTING.md

issuetemplates: devscripts/make_issue_template.py .github/ISSUE_TEMPLATE_tmpl/1_broken_site.yml .github/ISSUE_TEMPLATE_tmpl/2_site_support_request.yml .github/ISSUE_TEMPLATE_tmpl/3_site_feature_request.yml .github/ISSUE_TEMPLATE_tmpl/4_bug_report.yml .github/ISSUE_TEMPLATE_tmpl/5_feature_request.yml pragy_dl/version.py
	$(PYTHON) devscripts/make_issue_template.py .github/ISSUE_TEMPLATE_tmpl/1_broken_site.yml .github/ISSUE_TEMPLATE/1_broken_site.yml
	$(PYTHON) devscripts/make_issue_template.py .github/ISSUE_TEMPLATE_tmpl/2_site_support_request.yml .github/ISSUE_TEMPLATE/2_site_support_request.yml
	$(PYTHON) devscripts/make_issue_template.py .github/ISSUE_TEMPLATE_tmpl/3_site_feature_request.yml .github/ISSUE_TEMPLATE/3_site_feature_request.yml
	$(PYTHON) devscripts/make_issue_template.py .github/ISSUE_TEMPLATE_tmpl/4_bug_report.yml .github/ISSUE_TEMPLATE/4_bug_report.yml
	$(PYTHON) devscripts/make_issue_template.py .github/ISSUE_TEMPLATE_tmpl/5_feature_request.yml .github/ISSUE_TEMPLATE/5_feature_request.yml
	$(PYTHON) devscripts/make_issue_template.py .github/ISSUE_TEMPLATE_tmpl/6_question.yml .github/ISSUE_TEMPLATE/6_question.yml

supportedsites:
	$(PYTHON) devscripts/make_supportedsites.py supportedsites.md

README.txt: README.md
	pandoc -f $(MARKDOWN) -t plain README.md -o README.txt

pragy-dl.1: README.md devscripts/prepare_manpage.py
	$(PYTHON) devscripts/prepare_manpage.py pragy-dl.1.temp.md
	pandoc -s -f $(MARKDOWN) -t man pragy-dl.1.temp.md -o pragy-dl.1
	rm -f pragy-dl.1.temp.md

completions/bash/pragy-dl: pragy_dl/*.py pragy_dl/*/*.py devscripts/bash-completion.in
	mkdir -p completions/bash
	$(PYTHON) devscripts/bash-completion.py

completions/zsh/_pragy-dl: pragy_dl/*.py pragy_dl/*/*.py devscripts/zsh-completion.in
	mkdir -p completions/zsh
	$(PYTHON) devscripts/zsh-completion.py

completions/fish/pragy-dl.fish: pragy_dl/*.py pragy_dl/*/*.py devscripts/fish-completion.in
	mkdir -p completions/fish
	$(PYTHON) devscripts/fish-completion.py

_EXTRACTOR_FILES = $(shell find pragy_dl/extractor -name '*.py' -and -not -name 'lazy_extractors.py')
pragy_dl/extractor/lazy_extractors.py: devscripts/make_lazy_extractors.py devscripts/lazy_load_template.py $(_EXTRACTOR_FILES)
	$(PYTHON) devscripts/make_lazy_extractors.py $@

pragy-dl.tar.gz: all
	@tar -czf pragy-dl.tar.gz --transform "s|^|pragy-dl/|" --owner 0 --group 0 \
		--exclude '*.DS_Store' \
		--exclude '*.kate-swp' \
		--exclude '*.pyc' \
		--exclude '*.pyo' \
		--exclude '*~' \
		--exclude '__pycache__' \
		--exclude '.pytest_cache' \
		--exclude '.git' \
		-- \
		README.md supportedsites.md Changelog.md LICENSE \
		CONTRIBUTING.md Collaborators.md CONTRIBUTORS AUTHORS \
		Makefile MANIFEST.in pragy-dl.1 README.txt completions \
		setup.py setup.cfg pragy-dl pragy_dl requirements.txt \
		devscripts test

AUTHORS: .mailmap
	git shortlog -s -n | cut -f2 | sort > AUTHORS

.mailmap:
	git shortlog -s -e -n | awk '!(out[$$NF]++) { $$1="";sub(/^[ \t]+/,""); print}' > .mailmap
