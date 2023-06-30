$(OBJDIR)/frame.o           :$(FRAME_SRC)/frame.f;                   $(FC) -c $(FL2) $< -o $@
$(OBJDIR)/mntrlog_block.o   :$(MNTR_SRC)/mntrlog_block.f;            $(FC) -c $(FL2) $< -o $@
$(OBJDIR)/mntrlog.o         :$(MNTR_SRC)/mntrlog.f;                  $(FC) -c $(FL2) $< -o $@
$(OBJDIR)/mntrtmr_block.o   :$(MNTR_SRC)/mntrtmr_block.f;            $(FC) -c $(FL2) $< -o $@
$(OBJDIR)/mntrtmr.o         :$(MNTR_SRC)/mntrtmr.f;                  $(FC) -c $(FL2) $< -o $@
$(OBJDIR)/rprm_block.o      :$(RPRM_SRC)/rprm_block.f;               $(FC) -c $(FL2) $< -o $@
$(OBJDIR)/rprm.o            :$(RPRM_SRC)/rprm.f;                     $(FC) -c $(FL2) $< -o $@
$(OBJDIR)/io_tools_block.o  :$(IO_TOOLS_SRC)/io_tools_block.f;       $(FC) -c $(FL2) $< -o $@
$(OBJDIR)/io_tools.o        :$(IO_TOOLS_SRC)/io_tools.f;             $(FC) -c $(FL2) $< -o $@
$(OBJDIR)/chkpt.o           :$(CHKPT_SRC)/chkpt.f;                   $(FC) -c $(FL2) $< -o $@
$(OBJDIR)/chkptms.o         :$(CHKPTMS_SRC)/chkptms.f;               $(FC) -c $(FL2) $< -o $@
$(OBJDIR)/map2D.o           :$(MAP2D_SRC)/map2D.f;                   $(FC) -c $(FL2) $< -o $@
$(OBJDIR)/stat.o            :$(STAT_SRC)/stat.f ./STATD;             $(FC) -c $(FL2) $< -o $@
$(OBJDIR)/stat_IO.o         :$(STAT_SRC)/stat_IO.f ./STATD;          $(FC) -c $(FL2) $< -o $@
