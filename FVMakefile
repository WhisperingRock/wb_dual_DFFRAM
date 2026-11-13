# Find paths to RTL and include files
RTL_SRCS 	 := $(shell find rtl -name '*.sv' -or -name '*.v')
INCLUDE_DIRS := $(sort $(dir $(shell find . -name '*.svh' -or -name '*.vh')))
RTL_DIRS	 := $(sort $(dir $(RTL_SRCS)))

# Include both Include and RTL directories for linting
FORMAL_DIR     = ./formal
FORMAL_SUBDIRS = $(shell cd $(FORMAL_DIR) && ls -d */ | grep -v "__pycache__" )
FORMAL_TESTS   = $(FORMAL_SUBDIRS:/=)

# Formal Verification with SBY
VERIFIER      := sby
VERIFIER_ARGS := -f
SBY_JOB_TYPE  ?= bmc
JOB_TYPES      = bmc prove cover

# Text formatting for tests
BOLD  = `tput bold`
GREEN = `tput setaf 2`
ORANG = `tput setaf 214`
RED   = `tput setaf 1`
RESET = `tput sgr0`

all: formal

formal: $(FORMAL_TESTS)

formal/%: FORCE
	make -s $(subst /,, $(basename $*))

# Formal verification test targets
.PHONY: $(FORMAL_TESTS)
$(FORMAL_TESTS):
	@printf "\n$(GREEN)$(BOLD) ----- Running Formal Verif: $@ ----- $(RESET)\n"

# Run and check for error
	@printf "\n$(BOLD) Running with job type: $(SBY_JOB_TYPE)... $(RESET)\n"
	@if cd $(FORMAL_DIR)/$@;\
		$(VERIFIER) $(VERIFIER_ARGS) $@.sby $(SBY_JOB_TYPE) > results.log \
    	&& (cat results.log | grep -qi "PASS") \
    	then \
    		printf "$(GREEN) PASSED $@$(RESET)\n"; \
    	else \
        	printf "$(RED) FAILED $@$(RESET)\n"; \
        	cat results.log; \
    	fi; \

FORCE: ;

.PHONY: clean
clean:
	rm -f `find formal -iname "*.log"`
	$(foreach formal_test,$(FORMAL_TESTS),$(foreach job_type,$(JOB_TYPES),rm -rf `find formal/$(formal_test) -mindepth 1 -iname "$(formal_test)_$(job_type)"`;))
	$(foreach formal_test,$(FORMAL_TESTS),rm -rf `find formal/$(formal_test) -mindepth 1 -iname "$(formal_test)"`;)


