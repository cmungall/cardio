# NOTE: you will need biomake to run this


prolog
root(mondo,'DOID:114').
root(mp,'MP:0005385').
root(hp,'HP:0001626').
root(go,'GO:0003013').
root(ub,'UBERON:0004535').
endprolog

MP_CV = MP:0005385
HP_CV = HP:0001626
GO_CV = GO:0003013
UB_CV = UBERON:0004535
DO_CV = DOID:114

ONTS = mp hp go ub mondo
XONTS = uberon go cl

all: all_cv all_cv_png all_cv2_png all_cv3_png all_cv4_png all_cv2_tree all_cv3_tree all_cv4_tree all_x

all_cv: $(patsubst %, %cv.obo, $(ONTS))

all_x: xp-mp xp-hp

xp-$(ONT): $(patsubst %,$(ONT)ld-%.obo,$(XONTS))

all_cv_png: $(patsubst %, %cv-all.png, $(ONTS))

all_cv2_png: $(patsubst %, %cv-depth-2.png, $(ONTS))
all_cv3_png: $(patsubst %, %cv-depth-3.png, $(ONTS))
all_cv4_png: $(patsubst %, %cv-depth-4.png, $(ONTS))

all_cv2_tree: $(patsubst %, %cv-depth-2.tree, $(ONTS))
all_cv3_tree: $(patsubst %, %cv-depth-3.tree, $(ONTS))
all_cv4_tree: $(patsubst %, %cv-depth-4.tree, $(ONTS))


clean:
	rm *.png *.tree

BLIPREL := -rel subclass -rel part_of -rel develops_from

# ----------------------------------------
# Ontology Slices
# ----------------------------------------

mpcv.obo:
	blip ontol-query -r MP -r mp_xp -query "subclassRT(ID,'$(MP_CV)')" -to obo > $@.tmp && mv $@.tmp $@

hpcv.obo:
	blip ontol-query -r HP -r hp_xp -query "subclassRT(ID,'$(HP_CV)')" -to obo > $@.tmp && mv $@.tmp $@

gocv.obo:
	blip ontol-query -r go_basic -query "parentRT(ID,'$(GO_CV)')" -to obo > $@.tmp && mv $@.tmp $@

ubcv.obo:
	blip ontol-query -r uberons -query "parentRT(ID,'$(UB_CV)')" -to obo > $@.tmp && mv $@.tmp $@

mondocv.obo:
	blip ontol-query -r mondo -query "subclassRT(ID,'$(DO_CV)')" -to obo > $@.tmp && mv $@.tmp $@

%-all.png: %.obo
	blip ontol-subset -i $< -n % -to png $(BLIPREL) > $@.tmp && mv $@.tmp $@

# ----------------------------------------
# Sub-Trees from Root
# ----------------------------------------

# requires biomake
$(ONT)cv-depth-$(DEPTH).png: $(ONT)cv.obo
	blip -u ontol_config_do ontol-subset -i $< -id $(bagof ROOT, root($(ONT),ROOT)) -down $(DEPTH) -to png $(BLIPREL) > $@.tmp && mv $@.tmp $@

$(ONT)cv-depth-$(DEPTH).tree: $(ONT)cv.obo
	blip -u ontol_config_do ontol-subset -i $< -id $(bagof ROOT, root($(ONT),ROOT)) -down $(DEPTH)  > $@.tmp && mv $@.tmp $@

# ----------------------------------------
# Logical defs
# ----------------------------------------

mpld-%.obo:
	blip ontol-query -r $* -r MP -r mp_xp -query "subclassRT(X,'$(MP_CV)'),differentium(X,_,ID),id_idspace(ID,S),upcase_atom('$*',S)" -to obo > $@.tmp && mv $@.tmp $@

hpld-%.obo:
	blip ontol-query -r $* -r HP -r hp_xp -query "subclassRT(X,'$(HP_CV)'),differentium(X,_,ID),id_idspace(ID,S),upcase_atom('$*',S)" -to obo > $@.tmp && mv $@.tmp $@

# EXP

mondocv-phenolog-go-mf-D.obo:
	obo-grep.pl --neg -r 'namespace: (biological_process|cellular_component)' mondocv-phenolog-go.obo > $@

mondocv-phenolog-go-bp-D.obo:
	obo-grep.pl --neg -r 'namespace: (molecular_function|cellular_component)' mondocv-phenolog-go.obo > $@

mondocv-phenolog-go-cc-D.obo:
	obo-grep.pl --neg -r 'namespace: (molecular_function|biological_process)' mondocv-phenolog-go.obo > $@

mondocv-phenolog-go-%-slim.obo: mondocv-phenolog-go-%-D.obo
	owltools $< --remove-dangling -o -f obo $@


mondocv-phenolog-go-%-slim.png: mondocv-phenolog-go-%-slim.obo
	blip ontol-subset -u ontol_config_do -i $< -n % -to png > $@

mondocv-phenolog-go-%-summary.obo: mondocv-phenolog-go-%-slim.obo
	obo-grep.pl -r 'relationship: assoc' $<  | obo-filter-tags.pl -t id -t name -t is_a -t relationship - > $@
