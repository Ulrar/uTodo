
## Sample Makefile for eliom application.

APP_NAME := utodo
STATICDIR := static

## Packages required to build the server part of the application

SERVER_PACKAGES := lwt.ppx js_of_ocaml.deriving.ppx atdgen uuidm

## Packages to be linked in the client part

CLIENT_PACKAGES := lwt.ppx js_of_ocaml.ppx js_of_ocaml.deriving.ppx atdgen uuidm

## Source files for the server part

SERVER_FILES := src/ulist_t.mli		\
		src/ulist_j.mli		\
		src/ulist_t.ml		\
		src/ulist_j.ml		\
		src/services.eliom	\
		src/tools.eliom		\
		src/category.eliom	\
		src/menu.eliom		\
		src/ulist_fs.eliom	\
		src/ulist_btn.eliom	\
		src/ulist.eliom		\
		src/utodo.eliom

## Source files for the client part

CLIENT_FILES :=	$(SERVER_FILES)

## Required binaries

ELIOMC      := eliomc
ELIOMOPT    := eliomopt
ELIOMDEP    := eliomdep
JS_OF_ELIOM := js_of_eliom -ppx

## Where to put intermediate object files.
## - ELIOM_{SERVER,CLIENT}_DIR must be distinct
## - ELIOM_CLIENT_DIR mustn't be the local dir.
## - ELIOM_SERVER_DIR could be ".", but you need to
##   remove it from the "clean" rules...

export ELIOM_SERVER_DIR := _server
export ELIOM_CLIENT_DIR := _client
export ELIOM_TYPE_DIR   := .

#####################################

all: byte install
byte:: ${APP_NAME}.cma ${APP_NAME}.js
opt:: ${APP_NAME}.cmxs ${APP_NAME}.js

#### Server side compilation #######

SERVER_DIRS     := $(shell echo $(foreach f, $(SERVER_FILES), $(dir $(f))) |  tr ' ' '\n' | sort -u | tr '\n' ' ')
SERVER_DEP_DIRS := ${addprefix -eliom-inc ,${SERVER_DIRS}}
SERVER_INC_DIRS := ${addprefix -I $(ELIOM_SERVER_DIR)/, ${SERVER_DIRS}}

SERVER_INC  := ${addprefix -package ,${SERVER_PACKAGES}}
SERVER_DB_INC  := ${addprefix -package ,${SERVER_DB_PACKAGES}}

SERVER_OBJS := $(patsubst %.mli,${ELIOM_SERVER_DIR}/%.cmi, ${SERVER_FILES})
SERVER_OBJS := $(patsubst %.ml,${ELIOM_SERVER_DIR}/%.cmo, ${SERVER_OBJS})
SERVER_OBJS := $(patsubst %.eliom,${ELIOM_SERVER_DIR}/%.cmo, ${SERVER_OBJS})

${ELIOM_SERVER_DIR}/%.type_mli: %.eliom
		${ELIOMC} -ppx -infer ${SERVER_INC} ${SERVER_INC_DIRS} $<


${APP_NAME}.cma: depend ${SERVER_OBJS}
	${ELIOMC} -a -o $@ $(filter %.cmo,${SERVER_OBJS})
${APP_NAME}.cmxa: ${SERVER_OBJS:.cmo=.cmx}
	${ELIOMOPT} -a -o $@ $^

%.cmxs: %.cmxa
		$(ELIOMOPT) -ppx -shared -linkall -o $@ $(GENERATE_DEBUG) $<

${ELIOM_SERVER_DIR}/%.cmi: %.mli
		${ELIOMC} -ppx -c ${SERVER_INC} ${SERVER_INC_DIRS} $(GENERATE_DEBUG) $<

${ELIOM_SERVER_DIR}/%.cmi: %.eliomi
		${ELIOMC} -ppx -c ${SERVER_INC} ${SERVER_INC_DIRS} $(GENERATE_DEBUG) $<

${ELIOM_SERVER_DIR}/%.cmo: %.ml
		${ELIOMC} -ppx -c ${SERVER_INC} ${SERVER_INC_DIRS} $(GENERATE_DEBUG) $<
${ELIOM_SERVER_DIR}/%.cmo: %.eliom
		${ELIOMC} -ppx -c ${SERVER_INC} ${SERVER_INC_DIRS} $(GENERATE_DEBUG) $<

${ELIOM_SERVER_DIR}/%.cmx: %.ml
		${ELIOMOPT} -ppx -c ${SERVER_INC} ${SERVER_INC_DIRS} $(GENERATE_DEBUG) $<
${ELIOM_SERVER_DIR}/%.cmx: %.eliom
		${ELIOMOPT} -ppx -c ${SERVER_INC} ${SERVER_INC_DIRS} $(GENERATE_DEBUG) $<

##### Client side compilation ####

CLIENT_DIRS     := $(shell echo $(foreach f, $(CLIENT_FILES), $(dir $(f))) |  tr ' ' '\n' | sort -u | tr '\n' ' ')
CLIENT_DEP_DIRS := ${addprefix -eliom-inc ,${CLIENT_DIRS}}
CLIENT_INC_DIRS := ${addprefix -I $(ELIOM_CLIENT_DIR)/,${CLIENT_DIRS}}

CLIENT_LIBS := ${addprefix -package ,${CLIENT_PACKAGES}}
CLIENT_INC  := ${addprefix -package ,${CLIENT_PACKAGES}}

CLIENT_OBJS := $(filter %.eliom %.ml %.mli, $(CLIENT_FILES))
CLIENT_OBJS := $(patsubst %.mli,${ELIOM_CLIENT_DIR}/%.cmi, $(CLIENT_OBJS))
CLIENT_OBJS := $(patsubst %.eliom,${ELIOM_CLIENT_DIR}/%.cmo, ${CLIENT_OBJS})
CLIENT_OBJS := $(patsubst %.ml,${ELIOM_CLIENT_DIR}/%.cmo, ${CLIENT_OBJS})

${APP_NAME}.js: ${CLIENT_OBJS}
	${JS_OF_ELIOM} -o $@ ${CLIENT_LIBS} $(filter %.cmo,${CLIENT_OBJS})

${ELIOM_CLIENT_DIR}/%.cmi: %.mli
		${JS_OF_ELIOM} -c ${CLIENT_INC} ${CLIENT_INC_DIRS} $(GENERATE_DEBUG) $<

${ELIOM_CLIENT_DIR}/%.cmo: %.eliom
		${JS_OF_ELIOM} -c ${CLIENT_INC} ${CLIENT_INC_DIRS} $(GENERATE_DEBUG) $<
${ELIOM_CLIENT_DIR}/%.cmo: %.ml
		${JS_OF_ELIOM} -c ${CLIENT_INC} ${CLIENT_INC_DIRS} $(GENERATE_DEBUG) $<

${ELIOM_CLIENT_DIR}/%.cmi: %.eliomi
		${JS_OF_ELIOM} -c ${CLIENT_INC} ${CLIENT_INC_DIRS} $(GENERATE_DEBUG) $<
############

## Clean up

clean:
	-rm -f src/*.cm[ioax] *.cmxa *.cmxs *.o *.a *.annot
	-rm -f src/*.type_mli
	-rm -f .depend
	-rm -f ${APP_NAME}.js
	-rm -rf ${ELIOM_CLIENT_DIR} ${ELIOM_SERVER_DIR}

distclean: clean.local
	-rm -f *~ \#* .\#*

## Dependencies

depend: .depend
.depend: ${SERVER_FILES} ${CLIENT_FILES}
	$(ELIOMDEP) -server -ppx ${SERVER_INC} ${SERVER_FILES} | sed 's,src,_server/src,g' > .depend
	$(ELIOMDEP) -client -ppx  ${CLIENT_INC} ${CLIENT_FILES} | sed 's,src,_server/src,g' >> .depend

## Warning: Dependencies towards *.eliom are not handled by eliomdep yet.

include .depend

## installation #########

install:
	@mkdir -p $(STATICDIR)/
	@cp $(APP_NAME).js $(STATICDIR)/$(APP_NAME).js


## test

test.byte: byte
	cp utodo.cma local/lib/utodo/utodo.cma
	cp utodo.js local/var/www/utodo/eliom/utodo.js
	ocsigenserver -c local/etc/utodo/utodo-test.conf
