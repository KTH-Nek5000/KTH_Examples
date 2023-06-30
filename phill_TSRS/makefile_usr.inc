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
$(OBJDIR)/math_tools.o      :$(MATH_SRC)/math_tools.f;               $(FC) -c $(FL2) $< -o $@
$(OBJDIR)/comm_mpi_wrp.o    :$(COMM_SRC)/comm_mpi_tool.f;            $(FC) -c $(FL2) $< -o $@
$(OBJDIR)/tsrs.o            :$(TSRS_SRC)/tsrs.f ./TSRSD;             $(FC) -c $(FL2) $< -o $@
$(OBJDIR)/tsrs_IO.o         :$(TSRS_SRC)/tsrs_IO.f ./TSRSD;          $(FC) -c $(FL2) $< -o $@
$(OBJDIR)/pts_redistribute.o  :$(TSRS_SRC)/pts_redistribute.f ./TSRSD;  $(FC) -c $(FL2) $< -o $@
