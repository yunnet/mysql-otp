# MySQL/OTP
#
# This Makefile should be complete enough for this project to be used as an
## erlang.mk dependency.
#
# We use rebar for eunit with coverage since erlang.mk doesn't have this yet.
# 'make tests' is not usable. Try 'rebar eunit' or 'make eunit-coverage'.
#
# Additional targets:
#
#  - eunit-coverage: Creates doc/eunit.html with the coverage and eunit output.
#  - gh-pages:       Generates docs and eunit reports and commits these in the
#                    gh-pages which Github publishes automatically when pushed.

PROJECT = mysql
EDOC_OPTS = {stylesheet_file,"priv/edoc-style.css"},{todo,true}
PLT_APPS = crypto
SHELL_PATH = -pa ebin

include erlang.mk

.PHONY: gh-pages eunit eunit-report

eunit:
	@mkdir -p .eunit
	@rm -f .eunit/index.html # make sure we don't get an old one if cover=false
	@rebar eunit | tee .eunit/output

# Update the local 'gh-pages' branch with pregenerated output files
# (trick from https://groups.google.com/forum/#!topic/github/XYxkdzxpgCo)
gh-pages: docs eunit-report
	@if [ $$(git name-rev --name-only HEAD) != master ] ; then \
	  echo "Not on master. Aborting." ; \
	  false ; \
	fi
	@git update-ref refs/heads/gh-pages origin/gh-pages '' 2>/dev/null || true
	@GIT_INDEX_FILE=gitindex.tmp; export GIT_INDEX_FILE; \
	rm -f $${GIT_INDEX_FILE} && \
	git add -f doc/*.html doc/stylesheet.css doc/erlang.png && \
	git update-ref refs/heads/gh-pages \
	    $$(echo "Autogenerated html pages for $$(git describe --tags)" \
	        | git commit-tree $$(git write-tree --prefix=doc) \
	                    -p refs/heads/gh-pages)
	@rm gitindex.tmp
	@echo "Committed $$(git describe --tags) in the gh-pages branch."

# Build eunit.html containing the coverage report and the eunit output in the
# doc directory.
eunit-report: eunit
	@(echo '<!DOCTYPE html>' ; \
	 cat .eunit/index.html | sed 's!</body></html>!!' ; \
	 echo '<h3>Output of <code>make eunit</code></h3><pre>' ; \
	 sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g;' .eunit/output ; \
	 echo '</pre>' ; \
	 echo '<p><em>Generated using rebar and EUnit,' ; \
	 date -u '+%d %h %Y %H:%M:%S UTC.' ; \
	 echo '</em></p>' ; \
	 echo '</body></html>') > doc/eunit.html
	@cp .eunit/*.COVER.html doc/
