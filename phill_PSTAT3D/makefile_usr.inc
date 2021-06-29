$(OBJDIR)/frame.o           :$(FRAME_SRC)/frame.f;                   $(F77) -c $(FL2) -I./ $(TOOLBOX_INC) $< -o $@
$(OBJDIR)/mntrlog_block.o   :$(MONITOR_SRC)/mntrlog_block.f;         $(F77) -c $(FL2) -I./ $(TOOLBOX_INC) $< -o $@
$(OBJDIR)/mntrlog.o         :$(MONITOR_SRC)/mntrlog.f;               $(F77) -c $(FL2) -I./ $(TOOLBOX_INC) $< -o $@
$(OBJDIR)/mntrtmr_block.o   :$(MONITOR_SRC)/mntrtmr_block.f;         $(F77) -c $(FL2) -I./ $(TOOLBOX_INC) $< -o $@
$(OBJDIR)/mntrtmr.o         :$(MONITOR_SRC)/mntrtmr.f;               $(F77) -c $(FL2) -I./ $(TOOLBOX_INC) $< -o $@
$(OBJDIR)/rprm_block.o      :$(RUNPARAM_SRC)/rprm_block.f;           $(F77) -c $(FL2) -I./ $(TOOLBOX_INC) $< -o $@
$(OBJDIR)/rprm.o            :$(RUNPARAM_SRC)/rprm.f;                 $(F77) -c $(FL2) -I./ $(TOOLBOX_INC) $< -o $@
$(OBJDIR)/io_tools_block.o  :$(IO_TOOLS_SRC)/io_tools_block.f;       $(F77) -c $(FL2) -I./ $(TOOLBOX_INC) $< -o $@
$(OBJDIR)/io_tools.o        :$(IO_TOOLS_SRC)/io_tools.f;             $(F77) -c $(FL2) -I./ $(TOOLBOX_INC) $< -o $@
$(OBJDIR)/pstat.o           :${PSTAT3D_SRC}/pstat.f ./PSTATD;        $(F77) -c $(FL2) -I./ $(TOOLBOX_INC) $< -o $@
$(OBJDIR)/pstat_IO.o        :${PSTAT3D_SRC}/pstat_IO.f ./PSTATD;     $(F77) -c $(FL2) -I./ $(TOOLBOX_INC) $< -o $@
