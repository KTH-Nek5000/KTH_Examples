$(OBJDIR)/frame.o           :frame.f FRAMELP;                        $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/mntrlog_block.o   :mntrlog_block.f MNTRLOGD;               $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/mntrlog.o         :mntrlog.f MNTRLOGD;                     $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/mntrtmr_block.o   :mntrtmr_block.f MNTRLOGD MNTRTMRD;      $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/mntrtmr.o         :mntrtmr.f MNTRLOGD MNTRTMRD FRAMELP;    $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/rprm_block.o      :rprm_block.f RPRMD;                     $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/rprm.o            :rprm.f RPRMD FRAMELP;                   $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/io_tools_block.o  :io_tools_block.f IOTOOLD;               $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/io_tools.o        :io_tools.f IOTOOLD;                     $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/pstat.o           :pstat.f PSTATD FRAMELP;                 $(F77) -c $(FL2) -I./ $< -o $@
$(OBJDIR)/pstat_IO.o        :pstat_IO.f PSTATD FRAMELP;              $(F77) -c $(FL2) -I./ $< -o $@
