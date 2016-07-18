# SETUP PATHS
ROOT=..
DABA=$(ROOT)/daba/
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
# UTILS
MALIDABA=$(ROOT)/malidaba
BAMADABA=$(ROOT)/bamadaba
PYTHON=PYTHONPATH=$(DABA) python
PARSER=$(PYTHON) $(DABA)/mparser.py 
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
auxtxtfiles := freqlist.txt
nkohtmlfiles := $(patsubst $(SRC)/%,%,$(wildcard $(SRC)/*.nko.html $(SRC)/*/*.nko.html $(SRC)/*/*/*.nko.html))
txtfiles := $(patsubst $(SRC)/%,%,$(wildcard $(SRC)/*.txt $(SRC)/*/*.txt $(SRC)/*/*/*.txt))
htmlfiles := $(filter-out %.pars.html %.dis.html,$(patsubst $(SRC)/%,%,$(wildcard $(SRC)/*.html $(SRC)/*/*.html $(SRC)/*/*/*.html)))
dishtmlfiles := $(patsubst $(SRC)/%,%,$(wildcard $(SRC)/*.dis.html $(SRC)/*/*.dis.html $(SRC)/*/*/*.dis.html))
srctxtfiles := $(filter-out $(htmlfiles:.html=.txt) $(dishtmlfiles:.dis.html=.txt) $(dishtmlfiles:.dis.html=.nko.txt) $(auxtxtfiles) %_fra.txt,$(txtfiles))
repertoires := $($(SRC)/%,%,$(wildcard $(SRC)/repertoires/*.csv))
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


corpora := cormani-brut-nko cormani-brut-lat
corpora-vert := $(addsuffix .vert, $(corpora))
compiled := $(patsubst %,export/data/%/word.lex,$(corpora))

.PRECIOUS: $(parshtmlfiles) $(parshtmllatfiles) $(compiled)
.PHONY: test

test:
	$(info $(brutfiles))

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
	
%.vert: config/%
	mkdir -p export/$*/data
	encodevert -c ./$< -p export/$*/data $@ 

%.nko.pars.html: %.nko.html $(dictionaries) $(grammar) $(dabafiles) 
	$(PARSER) -t -s nko -i "$<" -o "$@"

%.nko.pars.html: %.nko.txt $(dictionaries) $(grammar) $(dabafiles) 
	$(PARSER) -t -s nko -i "$<" -o "$@"

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
	find $(SRC) -type d | sed 's,$(SRC)/,,' | fgrep -v .git | xargs -n1 mkdir -p

run.dabased: $(addsuffix .dbs,$(netfiles))

cormani-brut-nko.vert: $(addsuffix .vert,$(brutfiles))
	rm -f $@
	echo "$(sort $^)" | tr ' ' '\n' | while read f ; do cat "$$f" >> $@ ; done
	
cormani-brut-lat.vert: $(addsuffix .vert,$(latfiles))
	rm -f $@ $@.nonko $@.nko
	echo "$(sort $^)" | tr ' ' '\n' | while read f ; do cat "$$f" >> $@.nonko ; done
	awk -F"\t" 'NF==7 {print}' $@.nonko | cut -f 1 | perl scripts/lat2nko.pl > $@.nko
	awk -F"\t" 'BEGIN {OFS="\t"} NF==7 { getline $$8 < "$@.nko"; print ; next} {print}' $@.nonko > $@
	
cormani-brut-nko-ltr.vert:
	touch $@

reparse-net: $(addsuffix .pars.html,$(netfiles))

reparse-net-vert: $(addsuffix .pars.non-tonal.vert,$(netfiles)) $(addsuffix .pars.tonal.vert,$(netfiles))

freqlist.txt: cormani-brut-nko-tonal.vert
	python freqlist.py $< > $@

export/data/%/word.lex: config/% %.vert
	mkdir -p $(@D)
	mkdir -p export/registry
	mkdir -p export/vert
	encodevert -c ./$< -p $(@D) $*.vert
	cp $< export/registry
	sed -i '/^PATH/s,export,/var/lib/manatee,' export/registry/$*
	cp $*.vert export/vert

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
	pushd export ; tar cJvf cormani.tar.xz * ; popd

create-testing:
	$(RSYNC) remote/*.sh $(HOST):
	ssh $(HOST)  sh create-hsh.sh $(TESTING) $(TESTPORT)

setup-bonito:
	ssh $(HOST) hsh-run --rooter $(TESTING) -- 'sh setup-bonito.sh cormani $(corpora)' 

install-testing: export/cormani.tar.xz
	$(RSYNC) $< $(HOST):$(TESTING)/chroot/.in/
	ssh $(HOST) hsh-run --rooter $(TESTING) -- 'rm -rf /var/lib/manatee/{data,registry,vert}/cormani*'
	ssh $(HOST) hsh-run --rooter $(TESTING) -- 'tar --no-same-permissions --no-same-owner -xJvf cormani.tar.xz --directory /var/lib/manatee'

production:
	$(RSYNC) remote/testing2production.sh $(HOST):$(TESTING)/chroot/.in/
	ssh $(HOST) hsh-run --rooter $(TESTING) -- 'sh testing2production.sh $(TESTPORT) $(PRODPORT)'
	ssh $(HOST) mv $(PRODUCTION) $(ROLLBACK)
	ssh $(HOST) mv $(TESTING) $(PRODUCTION)


install: export/cormani.tar.xz
	$(RSYNC) $< $(HOST):
	ssh $(HOST) rm -rf /var/lib/manatee/{data,registry,vert}/cormani*
	ssh $(HOST) "umask 0022 && tar --no-same-permissions --no-same-owner -xJvf cormani.tar.xz --directory /var/lib/manatee"

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

