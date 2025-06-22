DOCKERHOST := cormande
localarch := export
remoteroot := corpora
remotearch := setup
corplist = $(corpora)
configfiles := $(patsubst %,config/%,$(corplist)) 
corpvertfiles := $(patsubst %,%.vert,$(corplist))
#corpprlfiles := corbama-bam-fra.prl corbama-fra-bam.prl corbama-bam-fra2.prl corbama-fra2-bam.prl
archfile := cormani.tar.xz 
exportflag := $(localarch)/.exported

$(exportflag): $(configfiles) $(corpvertfiles)
	rm -f $(localarch)/registry/*
	rm -f $(localarch)/vert/*
	cp -f $(configfiles) $(localarch)/registry
	cp -f $(corpvertfiles) $(localarch)/vert
	touch $(exportflag)

exportfiles: $(exportflag)

docker-local: exportfiles
	docker run -dit --name $(corpsite) -v $$(pwd)/$(localarch)/vert:/var/lib/manatee/vert -v $$(pwd)/$(localarch)/registry:/var/lib/manatee/registry -p 127.0.0.1:8088:8080 -e CORPLIST="$(corplist)" maslinych/noske-alt:2.142-alt1

$(localarch)/$(archfile): exportfiles
	rm -f $(localarch)/$(archfile)
	tar cJvf $(localarch)/$(archfile) $(localarch)/registry $(localarch)/vert

pack-files: $(localarch)/$(archfile)

upload-files: pack-files
	rsync -avP -e ssh $(localarch)/$(archfile) $(DOCKERHOST):$(remotearch)
	ssh $(DOCKERHOST) 'tar xvf $(remotearch)/$(archfile) -C $(remoteroot)'

remove-testing-docker:
	ssh $(DOCKERHOST) 'docker stop testing'
	ssh $(DOCKERHOST) 'docker rm testing'

create-testing-docker: 
	ssh $(DOCKERHOST) 'docker run -dit --name testing -v $$(pwd)/$(remoteroot)/vert:/var/lib/manatee/vert -v $$(pwd)/$(remoteroot)/registry:/var/lib/manatee/registry -p 127.0.0.1:8088:8080 -e CORPLIST="$(corplist)" maslinych/noske-alt:2.130.1-alt4-1'

