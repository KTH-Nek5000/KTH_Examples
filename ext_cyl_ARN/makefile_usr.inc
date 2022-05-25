$(OBJDIR)/frame.o           :$(FRAME_SRC)/frame.f;                   $(FC) -c $(FL2) $< -o $@
$(OBJDIR)/mntrlog_block.o   :$(MNTR_SRC)/mntrlog_block.f;            $(FC) -c $(FL2) $< -o $@
$(OBJDIR)/mntrlog.o         :$(MNTR_SRC)/mntrlog.f;                  $(FC) -c $(FL2) $< -o $@
$(OBJDIR)/mntrtmr_block.o   :$(MNTR_SRC)/mntrtmr_block.f;            $(FC) -c $(FL2) $< -o $@
$(OBJDIR)/mntrtmr.o         :$(MNTR_SRC)/mntrtmr.f;                  $(FC) -c $(FL2) $< -o $@
$(OBJDIR)/rprm_block.o      :$(RPRM_SRC)/rprm_block.f;               $(FC) -c $(FL2) $< -o $@
$(OBJDIR)/rprm.o            :$(RPRM_SRC)/rprm.f;                     $(FC) -c $(FL2) $< -o $@
$(OBJDIR)/io_tools_block.o  :$(IO_TOOLS_SRC)/io_tools_block.f;       $(FC) -c $(FL2) $< -o $@
$(OBJDIR)/io_tools.o        :$(IO_TOOLS_SRC)/io_tools.f;             $(FC) -c $(FL2) $< -o $@
$(OBJDIR)/chkpoint.o        :$(CHKPT_SRC)/chkpoint.f;                $(FC) -c $(FL2) $< -o $@
$(OBJDIR)/chkptd.o          :$(CHKPTDMM_SRC)/chkptd.f;               $(FC) -c $(FL2) $< -o $@
$(OBJDIR)/math_tools.o      :$(MATH_SRC)/math_tools.f;               $(FC) -c $(FL2) $< -o $@
$(OBJDIR)/spnb.o            :$(SPNB_SRC)/spnb.f;                     $(FC) -c $(FL2) $< -o $@
$(OBJDIR)/tstpr.o           :$(TSTPR_SRC)/tstpr.f ./TSTPRD;          $(FC) -c $(FL2) $< -o $@
$(OBJDIR)/cnht_tools.o      :$(CNHT_SRC)/cnht_tools.f;               $(FC) -c $(FL2) $< -o $@
$(OBJDIR)/arna.o            :$(ARNA_SRC)/arna.f ./ARNAD ./TSTPRD;    $(FC) -c $(FL2) $< -o $@
$(OBJDIR)/arna_io.o         :$(ARNA_SRC)/arna_io.f ./ARNAD ./TSTPRD; $(FC) -c $(FL2) $< -o $@
