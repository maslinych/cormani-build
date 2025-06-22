# SETUP PATHS
ROOT=..
DABA=$(ROOT)/daba/daba/
SRC=$(ROOT)/cormani
vpath %.txt $(SRC)
vpath %.html $(SRC)
vpath %.dabased $(SRC)
#
# SETUP CREDENTIALS
HOST=corpora
# CHROOTS
TESTING=testing
PRODUCTION=production
TESTPORT=8098
PRODPORT=8099
BUILT=built
# UTILS
MALIDABA=$(ROOT)/malidaba
BAMADABA=$(ROOT)/bamadaba
PYTHON=PYTHONPATH=$(DABA) python
PARSER=mparser
daba2vert=$(PYTHON) $(DABA)/ad-hoc/daba2vert.py -v $(MALIDABA)/malidaba.txt
dabased=$(PYTHON) $(DABA)/dabased.py -v
RSYNC=rsync -avP --stats -e ssh
gitsrc=git --git-dir=$(SRC)/.git/
# 
# EXTERNAL RESOURCES
grammar=$(MALIDABA)/maninka.nko.gram.txt
dictionaries := $(addprefix $(MALIDABA)/,malidaba.txt diyalu.txt toolu.txt) $(BAMADABA)/jamuw.txt
dabafiles := $(addrefix $(DABA),grammar.py formats.py mparser.py newmorph.py)
# 
# SOURCE FILELISTS
gitfiles := $(shell $(gitsrc) ls-files)
auxtxtfiles := freqlist.txt
nkohtmlfiles := $(filter %.nko.html, $(gitfiles))
txtfiles := $(filter-out $(auxtxtfiles), $(filter %.txt, $(gitfiles)))
htmlfiles := $(filter-out %.pars.html %.dis.html,$(filter %.html,$(gitfiles)))
dishtmlfiles := $(filter %.dis.html,$(gitfiles))
srctxtfiles := $(filter-out $(htmlfiles:.html=.txt) $(dishtmlfiles:.dis.html=.txt) $(dishtmlfiles:.dis.html=.nko.txt) %_fra.txt, $(txtfiles))
repertoires := $(filter repertoires/%.csv, $(gitfiles))
srchtmlfiles := $(filter-out $(dishtmlfiles:.dis.html=.html) $(dishtmlfiles:.dis.html=.nko.html),$(htmlfiles))
parsenkofiles := $(filter %.nko.html,$(srchtmlfiles)) $(filter %.nko.txt,$(srctxtfiles))
parseoldfiles := $(filter %.old.html,$(srchtmlfiles)) $(filter %.old.txt,$(srctxtfiles:.old.lst.txt=.old.txt))
parselatfiles := $(filter %.lat.html,$(srchtmlfiles)) $(filter-out %.old.lat.txt,$(filter %.lat.txt,$(srctxtfiles:.lst.txt=.lat.txt)))
parshtmllatfiles := $(addsuffix .pars.html,$(basename $(parselatfiles) $(parseoldfiles)))

dabasedfiles := $(sort $(wildcard releases/*/*.dabased))
parshtmlfiles := $(addsuffix .pars.html,$(basename $(parsenkofiles)))
netfiles := $(patsubst %.html,%,$(dishtmlfiles))
brutfiles := $(netfiles) $(patsubst %.html,%,$(parshtmlfiles))
latfiles := $(patsubst %.html,%,$(parshtmllatfiles))


corpbasename := cormani
corpsite := cormani
corpora := cormani-brut-nko cormani-brut-lat cormani-net
corpora-vert := $(addsuffix .vert, $(corpora))
compiled := $(patsubst %,export/data/%/word.lex,$(corpora))
## Remote corpus installation data
corpsite-cormani := cormani
corpora-cormani := cormani-brut-nko cormani-brut-lat cormani-net

include docker.mk

.PRECIOUS: $(parshtmlfiles) $(parshtmllatfiles) $(compiled)
.PHONY: test

print-%:
	$(info $*=$($*))

compile: $(corpora-vert)

%.nko.pars.vert: %.nko.pars.html
	$(daba2vert) "$<" --unique --convert --keepsource > "$@"

%.lat.pars.vert: %.lat.pars.html
	$(daba2vert) "$<" --unique --convert > "$@"

%.old.pars.vert: %.old.pars.html
	$(daba2vert) "$<" --unique --convert > "$@"

%.dis.vert: %.dis.html %.dis.dbs
	$(daba2vert) "$<" --unique --convert --keepsource > "$@"

%.conll: %.nko.pars.html
	$(daba2vert) "$<" --unique --convert --conll -N --tonal > "$@"

%.nko_lat.txt: %.nko.pars.html
	$(PARSER) -z nko -s nko -N --convert --format txt -i "$<" -o "$@"

%.vert: config/%
	mkdir -p export/$*/data
	encodevert -c ./$< -p export/$*/data $@ 

%.nko.pars.html: %.nko.html $(dictionaries) $(grammar) $(dabafiles) 
	$(PARSER) -z nko -s nko -i "$<" -o "$@"

%.nko.pars.html: %.nko.txt $(dictionaries) $(grammar) $(dabafiles) 
	$(PARSER) -z nko -s nko -i "$<" -o "$@"

%.old.txt: %.old.lst.txt
	perl -p -e 's,<s>(.*?)</s>,,g;s,<t>(.*?)</t>,\1 ,g' "$<" > "$@"

%.lat.txt: %.lst.txt
	perl -p -e 's,<s>(.*?)</s>,,g;s,<t>(.*?)</t>,\1 ,g' "$<" > "$@"

%.lat.pars.html: %.lat.html $(dictionaries) $(grammar) $(dabafiles) 
	$(PARSER) -i "$<" -o "$@"

%.old.pars.html: %.old.txt
	$(PARSER) -s emklatinold -i "$<" -o "$@"

%.lat.pars.html: %.lat.txt $(dictionaries) $(grammar) $(dabafiles) 
	$(PARSER) -i "$<" -o "$@"

%.dis.pars.html: %.dis.html $(dictionaries) $(grammar) $(dabafiles) 
	$(PARSER) -i "$<" -o "$@"

%.dis.pars.non-tonal.vert: %.dis.pars.html
	$(daba2vert) "$<" --unique --convert --polisemy --debugfields > "$@"

%.dis.pars.tonal.vert: %.dis.pars.html 
	$(daba2vert) "$<" --tonal --unique --convert --polisemy > "$@"

%.dis.dbs: %.dis.html $(dabasedfiles)
	touch $@
	export lastcommit=$$($(gitsrc) log -n1 --pretty="%H" -- "$(<:$(SRC)/%=%)") ; \
	for f in $(dabasedfiles); do \
		export dabasedsha=$$(sha1sum $$f | cut -f1 -d" ") ; \
		export applied=$$(cat $@ | while read script scriptsha commitsha ; do \
			if [ $$dabasedsha = $$scriptsha ] ; then \
				if $$($(gitsrc) merge-base --is-ancestor $$commitsha $$lastcommit) ; then \
					echo -n "yes" ; break ;\
				else \
					echo -n "" ; break ;\
				fi ;\
			fi ;\
			done );\
		echo "Already applied:" $< $$f ;\
		test -z "$$applied" && $(dabased) -s $$f $< && echo $$f $$dabasedsha $$lastcommit >> $@ ;\
		done ; exit 0 

%.csv: %.xlsx
	ssconvert $< $@

all: compile

parse: $(parshtmlfiles)

resources: $(dictionaries) $(grammar) $(dabafiles) 
	$(PARSER) -n -g $(grammar) $(addprefix -d ,$(dictionaries))
	touch $@

makedirs:
	find $(SRC) -type d | sed 's,$(SRC)/,,' | grep -F -v .git | xargs -n1 mkdir -p

run.dabased: $(addsuffix .dbs,$(netfiles))

cormani-brut-nko.vert: $(addsuffix .vert,$(brutfiles))
	$(file >$@) $(foreach f,$(sort $^),$(shell cat $f >> $@))
	@true

cormani-brut-lat.vert: $(addsuffix .vert,$(latfiles))
	rm -f $@ $@.nonko $@.nko
	echo "$(sort $^)" | tr ' ' '\n' | while read f ; do cat "$$f" >> $@.nonko ; done
	awk -F"\t" 'NF==7 {print}' $@.nonko | cut -f 1 | perl scripts/lat2nko.pl > $@.nko
	awk -F"\t" 'BEGIN {OFS="\t"} NF==7 { getline $$8 < "$@.nko"; print ; next} {print}' $@.nonko > $@

cormani-brut-nko-ltr.vert:
	touch $@

cormani-net.vert: $(addsuffix .vert,$(netfiles))
	$(file >$@) $(foreach f,$(sort $^),$(shell cat $f >> $@))
	@true

reparse-net: $(addsuffix .pars.html,$(netfiles))

reparse-net-vert: $(addsuffix .pars.non-tonal.vert,$(netfiles)) $(addsuffix .pars.tonal.vert,$(netfiles))

freqlist.txt: cormani-brut-nko-tonal.vert
	python freqlist.py $< > $@

export/data/%/word.lex: config/% %.vert
	rm -rf export/data/$*
	rm -f export/registry/$*
	mkdir -p $(@D)
	mkdir -p export/registry
	encodevert -c ./$< -p $(@D) $*.vert
	cp $< export/registry
	sed -i '/^PATH/s,export,/var/lib/manatee,' export/registry/$*

cormani-dist.zip:
	git archive -o cormani-dist.zip --format=zip HEAD

cormani-dist.tar.xz:
	git archive --format=tar HEAD | xz -c > cormani-dist.tar.xz

dist-zip: cormani-dist.zip

dist: $(compiled)
	echo $<	

dist-print:
	echo $(foreach corpus,$(corpora),export/data/$(corpus)/word.lex)

export/cormani.tar.xz: $(compiled)
	pushd export ; tar cJvf cormani.tar.xz --mode='a+r' * ; popd

test:
	$(MAKE) -C sharness

install-testing: install-corpus-cormani

install-local: export/cormani.tar.xz
	sudo rm -rf /var/lib/manatee/{data,registry,vert}/cormani*
	sudo tar -xJvf $< --directory /var/lib/manatee --no-same-permissions --no-same-owner


corpsize: $(corpora-vert)
	for corp in $(corpora-vert); do \
		echo "$$corp" tokens: `awk 'NF>1 && $$1 !~ /^</ && $$3 != "c" {print}' $$corp | wc -l` ; \
		done
#	find -name \*.dis.html -print0 | xargs -0 -n 1 python ../daba/metaprint.py -w | awk '{c+=$$2}END{print "net:" c}'
#	find -name \*.pars.html -print0 | xargs -0 -n 1 python ../daba/metaprint.py -w | awk '{c+=$$2}END{print "brut:" c}'

repertoire:
	for i in *.xlsx ; do ssconvert $i ${i%%.xlsx}.csv ; done

conll: $(parshtmlfiles:nko.pars.html=conll)

nkolat: $(parshtmlfiles:nko.pars.html=nko_lat.txt)


clean: clean-vert clean-parse clean-pars

clean-vert:
	find -name \*.vert -not -name cormani-\*.vert -exec rm -f {} \;
	rm -f run/.vertical

clean-parse: 
	rm -f parse.filelist parseold.filelist run/status

clean-dabased:
	rm -f run/.dabased

clean-duplicates:
	git ls-files \*.dis.html | while read i ; do test -f $${i%%.dis.html}.pars.html && git rm -f $${i%%.dis.html}.pars.html ; done

clean-pars:
	find -name \*.pars.html -exec rm -f {} \;

