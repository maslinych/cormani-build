# SETUP PATHS
ROOT=..
DABA=$(ROOT)/daba/
SRC=$(ROOT)/cormani
vpath %.txt $(SRC)
vpath %.html $(SRC)
vpath %.dabased $(SRC)
#
# SETUP CREDENTIALS
HOST=maslinsky.spb.ru
USER=corpora
PORT=222
# CHROOTS
TESTING=testing
TESTPORT=8098
# UTILS
MALIDABA=$(ROOT)/malidaba
BAMADABA=$(ROOT)/bamadaba
PYTHON=PYTHONPATH=$(DABA) python
PARSER=$(PYTHON) $(DABA)/mparser.py 
daba2vert=$(PYTHON) $(DABA)/ad-hoc/daba2vert.py -v $(MALIDABA)/malidaba.txt
dabased=$(PYTHON) $(DABA)/dabased.py -v
RSYNC=rsync -avP --stats -e "ssh -p $(PORT)"
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
srchtmlfiles := $(filter-out $(dishtmlfiles:.dis.html=.html) $(dishtmlfiles:.dis.html=.nko.html),$(htmlfiles))
parsenkofiles := $(filter %.nko.html,$(srchtmlfiles)) $(filter %.nko.txt,$(srctxtfiles))
dabasedfiles := $(sort $(wildcard releases/*/*.dabased))
parshtmlfiles := $(addsuffix .pars.html,$(basename $(parsenkofiles)))
netfiles := $(patsubst %.html,%,$(dishtmlfiles))
brutfiles := $(netfiles) $(patsubst %.html,%,$(parshtmlfiles))

corpora := cormani-brut-nko-non-tonal cormani-brut-nko-tonal cormani-brut-lat-non-tonal cormani-brut-lat-tonal
corpora-vert := $(addsuffix .vert, $(corpora))
compiled := $(patsubst %,export/data/%/word.lex,$(corpora))

.PRECIOUS: $(parshtmlfiles)

test:
	$(info $(brutfiles))

print-%:
	$(info $*=$($*))

%.pars.tonal.vert: %.pars.html
	$(daba2vert) "$<" --tonal > "$@"
	
%.pars.non-tonal.vert: %.pars.html
	$(daba2vert) "$<" --unique  > "$@"

%.pars.lat.vert: %.pars.html
	$(daba2vert) "$<" --unique --convert > "$@"

%.pars.lat-tonal.vert: %.pars.html
	$(daba2vert) "$<" --unique --tonal --convert > "$@"


%.dis.tonal.vert: %.dis.html %.dis.dbs
	$(daba2vert) "$<" --tonal --unique --convert --polisemy > "$@"
	
%.dis.non-tonal.vert: %.dis.html %.dis.dbs
	$(daba2vert) "$<" --unique --convert --polisemy --debugfields > "$@"

%.dis.nul.vert: %.dis.html %.dis.dbs
	$(daba2vert) "$<" --unique --null --convert > "$@"

%.vert: config/%
	mkdir -p export/$*/data
	encodevert -c ./$< -p export/$*/data $@ 

%.nko.pars.html: %.nko.html
	$(PARSER) -t -s nko -i "$<" -o "$@"

%.nko.pars.html: %.nko.txt
	$(PARSER) -t -s nko -i "$<" -o "$@"

%.pars.html: %.html $(dictionaries) $(grammar) $(dabafiles) 
	$(PARSER) -i "$<" -o "$@"

%.pars.html: %.txt $(dictionaries) $(grammar) $(dabafiles) 
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
		export applyed=$$(cat $@ | while read script scriptsha commitsha ; do \
			if [ $$dabasedsha = $$scriptsha ] ; then \
				if $$($(gitsrc) merge-base --is-ancestor $$commitsha $$lastcommit) ; then \
					echo -n "yes" ; break ;\
				else \
					echo -n "" ; break ;\
				fi ;\
			fi ;\
			done );\
		echo "Already applyed:" $< $$f ;\
		test -z "$$applyed" && $(dabased) -s $$f $< && echo $$f $$dabasedsha $$lastcommit >> $@ ;\
		done ; exit 0 

all: compile

parse: $(parshtmlfiles)

resources: $(dictionaries) $(grammar) $(dabafiles) 
	$(PARSER) -n -g $(grammar) $(addprefix -d ,$(dictionaries))
	touch $@

makedirs:
	find $(SRC) -type d | sed 's,$(SRC)/,,' | fgrep -v .git | xargs -n1 mkdir -p

run.dabased: $(addsuffix .dbs,$(netfiles))

cormani-brut-nko-non-tonal.vert: $(addsuffix .non-tonal.vert,$(brutfiles))
	rm -f $@
	echo "$(sort $^)" | tr ' ' '\n' | while read f ; do cat "$$f" >> $@ ; done
	
cormani-brut-nko-tonal.vert: $(addsuffix .tonal.vert,$(brutfiles))
	rm -f $@
	echo "$(sort $^)" | tr ' ' '\n' | while read f ; do cat "$$f" >> $@ ; done

cormani-brut-lat-non-tonal.vert: $(addsuffix .lat.vert,$(brutfiles))
	rm -f $@
	echo "$(sort $^)" | tr ' ' '\n' | while read f ; do cat "$$f" >> $@ ; done
	
cormani-brut-lat-tonal.vert: $(addsuffix .lat-tonal.vert,$(brutfiles))
	rm -f $@
	echo "$(sort $^)" | tr ' ' '\n' | while read f ; do cat "$$f" >> $@ ; done
	
	
compile: $(corpora-vert)

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
	$(RSYNC) remote/*.sh $(USER)@$(HOST):
	ssh $(USER)@$(HOST) -p $(PORT) create-hsh.sh $(TESTING) $(TESTPORT)
	ssh $(USER)@$(HOST) -p $(PORT) hsh-run --rooter $(TESTING) -- 'sh setup-bonito.sh cormani $(corpora)' 

install-testing: export/cormani.tar.xz
	$(RSYNC) $< $(USER)@$(HOST):$(TESTING)/chroot/.in/
	ssh $(USER)@$(HOST) -p $(PORT) hsh-run --rooter $(TESTING) -- 'rm -rf /var/lib/manatee/{data,registry,vert}/cormani*'
	ssh $(USER)@$(HOST) -p $(PORT) hsh-run --rooter $(TESTING) -- 'tar --no-same-permissions --no-same-owner -xJvf cormani.tar.xz --directory /var/lib/manatee'

install: export/cormani.tar.xz
	$(RSYNC) $< $(USER)@$(HOST):
	ssh $(USER)@$(HOST) -p $(PORT) rm -rf /var/lib/manatee/{data,registry,vert}/cormani*
	ssh $(USER)@$(HOST) -p $(PORT) "umask 0022 && tar --no-same-permissions --no-same-owner -xJvf cormani.tar.xz --directory /var/lib/manatee"

install-local: export/cormani.tar.xz
	sudo rm -rf /var/lib/manatee/{data,registry,vert}/cormani*
	sudo tar -xJvf $< --directory /var/lib/manatee --no-same-permissions --no-same-owner


corpsize:
	@echo "net:" `awk 'NF>1 && $$1 !~ /^</ && $$3 != "c" {print}' cormani-brut-nko-non-tonal.vert | wc -l`
	@echo "brut:" `awk 'NF>1 && $$1 !~ /^</ && $$3 != "c" {print}' cormani-brut-nko-non-tonal.vert | wc -l`
#	find -name \*.dis.html -print0 | xargs -0 -n 1 python ../daba/metaprint.py -w | awk '{c+=$$2}END{print "net:" c}'
#	find -name \*.pars.html -print0 | xargs -0 -n 1 python ../daba/metaprint.py -w | awk '{c+=$$2}END{print "brut:" c}'

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

